//
//  TrapsMapViewController.m
//  TrapSniper
//
//  Created by Hai Phung on 11/7/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <TSMessages/TSMessage.h>
#import <TSMessages/TSMessageView.h>
#import "TrapsMapViewController.h"
#import "Trap.h"

#define kRegionRadius 200.0
#define kRegionOverlayRadius 500.0
#define kRedColor [UIColor colorWithRed:177.0/255.0 green:29.0/255.0 blue:44.0/255.0 alpha:1.0]

@interface TrapsMapViewController () <MKMapViewDelegate, TSMessageViewProtocol, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *reportButtonTrailingConstraint;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, getter=isGPSOn) BOOL GPSOn;
@property (nonatomic, getter=isMonitoring) BOOL monitoring;
@property (nonatomic) Trap *selectedTrap;

@end

@implementation TrapsMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [TSMessage setDelegate:self];
    
    // User tracking button.
    MKUserTrackingBarButtonItem *userTrackingButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    
    [self.toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.toolbar setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny];
    [self.toolbar setBarTintColor:kRedColor];
    self.toolbar.items = @[userTrackingButtonItem];
    
    // Setup the location manager.
    [self setupLocationManager];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


#pragma mark - Helper Methods

- (void)setupLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (void)startMonitoringForSpeedTraps {
    if ([CLLocationManager locationServicesEnabled]) {
        if (self.isGPSOn) {
            [self.locationManager startUpdatingLocation];
        } else {
            [self.locationManager startMonitoringSignificantLocationChanges];
        }
        
        // Show the report speed trap button.
        [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.reportButtonTrailingConstraint.constant = 16;
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    [TSMessage showNotificationInViewController:self title:@"Monitoring is ON." subtitle:@"You'll be notified when you're near a speed trap." type:TSMessageNotificationTypeMessage];
}

- (void)stopMonitoringForSpeedTraps {
    [self unregisterMonitoredRegions];
    if (self.isGPSOn) {
        [self.locationManager stopUpdatingLocation];
    } else {
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
    
    // Hide the report speed trap button.
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.reportButtonTrailingConstraint.constant = -100;
        [self.view layoutIfNeeded];
    } completion:nil];
    
    [TSMessage showNotificationInViewController:self title:@"Monitoring is OFF." subtitle:nil type:TSMessageNotificationTypeMessage];
}

- (void)overlayMapWithSpeedTraps:(NSArray *)speedTraps radius:(CLLocationDistance)radius {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    for (Trap *speedTrap in speedTraps) {
        // Create a circular overlay.
        CLLocationCoordinate2D circleCoordinate = CLLocationCoordinate2DMake(speedTrap.location.latitude, speedTrap.location.longitude);
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:circleCoordinate radius:kRegionOverlayRadius];
        [self.mapView addAnnotation:speedTrap];
        [self.mapView addOverlay:circle];
    }
}

- (void)configureRegionsForSpeedTraps:(NSArray *)speedTraps radius:(CLLocationDistance)radius {
    [self unregisterMonitoredRegions];
    
    for (Trap *speedTrap in speedTraps) {
        // Create a region.
        CLLocationCoordinate2D regionCenter = CLLocationCoordinate2DMake(speedTrap.location.latitude, speedTrap.location.longitude);
        CLCircularRegion *circularRegion = [[CLCircularRegion alloc] initWithCenter:regionCenter radius:radius identifier:speedTrap.objectId];
        circularRegion.notifyOnEntry = YES;
        circularRegion.notifyOnExit = NO;
        
        // Register region for monitoring.
        [self.locationManager startMonitoringForRegion:circularRegion];
        
        // Schedule a notification for the region.
        [self scheduleLocalNotificationForRegion:circularRegion];
    }
}

- (void)scheduleLocalNotificationForRegion:(CLCircularRegion *)region {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:@"Heads up! A speed trap has been reported near you. <Region: %@>", region.identifier];
    notification.regionTriggersOnce = NO;
    notification.region = region;
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)unregisterMonitoredRegions {
    // Unregister regions currently being monitored.
    [self.locationManager.monitoredRegions enumerateObjectsUsingBlock:^(CLRegion *region, BOOL *stop) {
        [self.locationManager stopMonitoringForRegion:region];
    }];
}

- (void)deleteSelectedTrap:(Trap *)trap {
    [Trap deleteAllInBackground:@[trap] block:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [TSMessage showNotificationWithTitle:@"Success!" subtitle:@"Speed trap was successfully removed." type:TSMessageNotificationTypeSuccess];
            [self mapView:self.mapView regionDidChangeAnimated:NO];
        } else {
            [TSMessage showNotificationWithTitle:@"Error!" subtitle:error.localizedDescription type:TSMessageNotificationTypeError];
        }
    }];
}


#pragma mark - Map View Delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocation *mapCenter = [[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude];
    [Trap fetchTrapsNearLocation:mapCenter completionHandler:^(NSArray *speedTraps) {
        [self overlayMapWithSpeedTraps:speedTraps radius:kRegionRadius];
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKAnnotationView *pin = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"SpeedTrapPin"];
    pin.image = [[UIImage alloc] init];
    pin.canShowCallout = YES;
    UIImageView *leftCalloutImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"left-callout"]];
    pin.leftCalloutAccessoryView = leftCalloutImage;
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return pin;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    self.selectedTrap = (Trap *)view.annotation;
    
    NSString *alertTitle = @"Delete This Speed Trap";
    NSString *alertMessage = @"Are you sure?";
    
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self deleteSelectedTrap:self.selectedTrap];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:yesAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        [alertView show];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *circleRenderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
        circleRenderer.fillColor = [kRedColor colorWithAlphaComponent:0.2];
        circleRenderer.strokeColor = [kRedColor colorWithAlphaComponent:0.75];
        circleRenderer.lineWidth = 1.0;
        return circleRenderer;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    // Ensure that code only executes once.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MKCoordinateRegion region;
        region.center = userLocation.coordinate;
        region.span = MKCoordinateSpanMake(0.1, 0.1);
        [mapView setRegion:region animated:YES];
    });
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error.localizedDescription);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (self.isMonitoring) {
        [Trap fetchTrapsNearLocation:self.currentLocation completionHandler:^(NSArray *speedTraps) {
            [self configureRegionsForSpeedTraps:speedTraps radius:kRegionRadius];
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entering region: %@", region.identifier);
    [TSMessage showNotificationWithTitle:@"Heads up!" subtitle:@"A speed trap has been reported near you." type:TSMessageNotificationTypeMessage];
    [manager stopMonitoringForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exiting region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Monitoring region: %@", region.identifier);
    [manager performSelector:@selector(requestStateForRegion:) withObject:region afterDelay:0.1];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Error for region <%@>: %@", region.identifier, error.localizedDescription);
    [TSMessage showNotificationWithTitle:@"Heads up!" subtitle:@"A speed trap has been reported near you." type:TSMessageNotificationTypeMessage];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (state == CLRegionStateInside) {
        NSLog(@"You are already inside region: %@", region.identifier);
        [self locationManager:manager didEnterRegion:region];
    }
}


#pragma mark - TSMessageView Delegate

- (void)customizeMessageView:(TSMessageView *)messageView {
    messageView.alpha = 0.9;
}


#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self deleteSelectedTrap:self.selectedTrap];
    }
}


#pragma mark - Actions

- (IBAction)onMonitorSwitchToggled:(UISwitch *)sender {
    self.monitoring = sender.isOn;
    if (sender.isOn) {
        [self startMonitoringForSpeedTraps];
    } else {
        [self stopMonitoringForSpeedTraps];
    }
}

- (IBAction)onLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint touchPoint = [gesture locationInView:self.mapView];
    CLLocationCoordinate2D touchCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    CLLocation *touchLocation = [[CLLocation alloc] initWithLatitude:touchCoordinate.latitude longitude:touchCoordinate.longitude];
    PFGeoPoint *touchGeoPoint = [PFGeoPoint geoPointWithLocation:touchLocation];
    Trap *speedTrap = [Trap object];
    speedTrap.location = touchGeoPoint;
    [speedTrap saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [TSMessage showNotificationWithTitle:@"Success!" subtitle:@"Speed trap has been reported." type:TSMessageNotificationTypeSuccess];
            [Trap fetchTrapsNearLocation:touchLocation completionHandler:^(NSArray *speedTraps) {
                [self overlayMapWithSpeedTraps:speedTraps radius:kRegionOverlayRadius];
            }];
        } else {
            [TSMessage showNotificationWithTitle:@"Error!" subtitle:error.localizedDescription type:TSMessageNotificationTypeError];
        }
    }];
}

- (IBAction)onReportTrapButtonTapped:(id)sender {
    if (self.isMonitoring) {
        Trap *speedTrap = [Trap object];
        speedTrap.location = [PFGeoPoint geoPointWithLocation:self.currentLocation];
        [speedTrap saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [TSMessage showNotificationWithTitle:@"Success!" subtitle:@"Speed trap has been reported." type:TSMessageNotificationTypeSuccess];
                [Trap fetchTrapsNearLocation:self.currentLocation completionHandler:^(NSArray *speedTraps) {
                    [self overlayMapWithSpeedTraps:speedTraps radius:kRegionOverlayRadius];
                }];
            } else {
                [TSMessage showNotificationWithTitle:@"Error!" subtitle:error.localizedDescription type:TSMessageNotificationTypeError];
            }
        }];
    } else {
        [TSMessage showNotificationWithTitle:@"Whoops!" subtitle:@"Please turn on monitoring to report a speed trap near your current location." type:TSMessageNotificationTypeWarning];
    }
}


#pragma mark - Accessors

- (CLLocation *)currentLocation {
    return self.locationManager.location;
}

- (BOOL)isGPSOn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"useGPS"];
}

@end
