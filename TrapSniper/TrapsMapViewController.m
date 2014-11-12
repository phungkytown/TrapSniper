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

#define kRegionRadius 50.0
#define kRegionOverlayRadius 500.0
#define kRedColor [UIColor colorWithRed:177.0/255.0 green:29.0/255.0 blue:44.0/255.0 alpha:1.0]

@interface TrapsMapViewController () <MKMapViewDelegate, TSMessageViewProtocol>

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *reportButtonTrailingConstraint;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, getter=isGPSOn) BOOL GPSOn;
@property (nonatomic, getter=isMonitoring) BOOL monitoring;

@end

@implementation TrapsMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [TSMessage setDelegate:self];
    
    // User tracking button.
    MKUserTrackingBarButtonItem *userTrackingButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    
    [self.toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.toolbar setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny];
    [self.toolbar setBarTintColor:[UIColor colorWithRed:177.0/255.0 green:29.0/255.0 blue:44.0/255.0 alpha:1.0]];
    self.toolbar.items = @[userTrackingButtonItem];
    
    // Setup the location manager.
    [self setupLocationManager];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.reportButtonTrailingConstraint.constant = 16;
        [self.view layoutIfNeeded];
    } completion:nil];
}


#pragma mark - Helper Methods

- (void)setupLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    NSLog(@"%@", self.currentLocation);
}

- (void)startMonitoringForSpeedTraps {
    if ([CLLocationManager locationServicesEnabled]) {
        if (self.isGPSOn) {
            [self.locationManager startUpdatingLocation];
        } else {
            [self.locationManager startMonitoringSignificantLocationChanges];
        }
    }
    [TSMessage showNotificationInViewController:self title:@"Monitoring is ON." subtitle:@"You'll be notified when you're near a speed trap." type:TSMessageNotificationTypeMessage duration:1.0];
}

- (void)stopMonitoringForSpeedTraps {
    [self unregisterMonitoredRegions];
    if (self.isGPSOn) {
        [self.locationManager stopUpdatingLocation];
    } else {
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
    [TSMessage showNotificationInViewController:self title:@"Monitoring is OFF." subtitle:nil type:TSMessageNotificationTypeMessage duration:1.0];
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
    notification.alertBody = [NSString stringWithFormat:@"Heads up! There's a speed trap nearby. <Region: %@>", region.identifier];
    notification.regionTriggersOnce = NO;
    notification.region = region;
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)unregisterMonitoredRegions {
    // Unregister regions currently being monitored.
    for (CLCircularRegion *region in self.locationManager.monitoredRegions.allObjects) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    NSLog(@"%@", self.locationManager.monitoredRegions.allObjects);
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
    return pin;
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
        [mapView setRegion:region animated:NO];
    });
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error.localizedDescription);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    if (self.isMonitoring) {
        // We're using the significant change location service to preserve battery life.
        [Trap fetchTrapsNearLocation:self.currentLocation completionHandler:^(NSArray *speedTraps) {
            [self configureRegionsForSpeedTraps:speedTraps radius:kRegionRadius];
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entering region: %@", region.identifier);
    
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Heads up!" message:@"There's a speed trap nearby." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Heads up!" message:@"There's speed trap nearby." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exiting region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Monitoring region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Error for region <%@>: %@", region.identifier, error.localizedDescription);
}


#pragma markk - TSMessageView Delegate

- (void)customizeMessageView:(TSMessageView *)messageView {
    messageView.alpha = 0.85;
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
    
    if (self.isMonitoring) {
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
    } else {
        [TSMessage showNotificationWithTitle:@"Whoops!" subtitle:@"Please turn on monitoring to report speed traps." type:TSMessageNotificationTypeWarning];
    }
    
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
        [TSMessage showNotificationWithTitle:@"Whoops!" subtitle:@"Please turn on monitoring to report speed traps." type:TSMessageNotificationTypeWarning];
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
