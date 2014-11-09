//
//  TrapsMapViewController.m
//  TrapSniper
//
//  Created by Hai Phung on 11/7/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "TrapsMapViewController.h"
#import "Trap.h"

@interface TrapsMapViewController () <MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, getter=isMonitoring) BOOL monitoring;

@end

@implementation TrapsMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)startMonitoringForSpeedTraps {
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)stopMonitoringForSpeedTraps {
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)overlayMapWithSpeedTraps:(NSArray *)speedTraps radius:(CLLocationDistance)radius {
    [self.mapView removeOverlays:self.mapView.overlays];
    for (Trap *speedTrap in speedTraps) {
        CLLocationCoordinate2D circleCoordinate = CLLocationCoordinate2DMake(speedTrap.location.latitude, speedTrap.location.longitude);
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:circleCoordinate radius:radius];
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
        
        // Keep our own reference to these regions so that we can remove them later.
        [self.monitoredRegions addObject:circularRegion];
        
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
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)unregisterMonitoredRegions {
    // Unregister regions currently being monitored.
    for (CLCircularRegion *region in self.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    [self.monitoredRegions removeAllObjects];
}

#pragma mark - Map View Delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocation *mapCenter = [[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude];
    [Trap fetchTrapsNearLocation:mapCenter completionHandler:^(NSArray *speedTraps) {
        [self overlayMapWithSpeedTraps:speedTraps radius:100.0];
    }];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *circleRenderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
        circleRenderer.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
        circleRenderer.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
        circleRenderer.lineWidth = 3.0;
        return circleRenderer;
    }
    return nil;
}


#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error.localizedDescription);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    // We're using the significant change location service to preserve battery life.
    CLLocation *currentLocation = locations.lastObject;

    if (currentLocation.horizontalAccuracy < 0) {
        return;
    }
    
    // Check for cached locations.
    NSTimeInterval locationTimeInterval = [currentLocation.timestamp timeIntervalSinceNow];
    if (locationTimeInterval < 10.0) {
        [Trap fetchTrapsNearLocation:currentLocation completionHandler:^(NSArray *speedTraps) {
            [self configureRegionsForSpeedTraps:speedTraps radius:100.0];
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    // TODO: Alert for entering region while app is active.
    NSLog(@"Entering region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exiting region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Monitoring region: %@", region.identifier);
}


#pragma mark - Actions

- (IBAction)onZoomToLocationButtonTapped:(id)sender {
    MKCoordinateSpan currentRegionSpan = self.mapView.region.span;
    if (currentRegionSpan.latitudeDelta > 1.0 || currentRegionSpan.longitudeDelta > 1.0) {
        MKCoordinateRegion region;
        region.center = self.currentLocation.coordinate;
        region.span = MKCoordinateSpanMake(0.05, 0.05);
        [self.mapView setRegion:region animated:YES];
    } else {
        [self.mapView setCenterCoordinate:self.currentLocation.coordinate animated:YES];
    }
}

- (IBAction)onStartButtonTapped:(id)sender {
    
    [self startMonitoringForSpeedTraps];
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
            [Trap fetchTrapsNearLocation:touchLocation completionHandler:^(NSArray *speedTraps) {
                [self overlayMapWithSpeedTraps:speedTraps radius:100.0];
            }];
        }
    }];
}


#pragma mark - Accessors

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            // If the user has turned off or denied authorization for location services,
            // then do nothing.
        } else {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
            
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                [_locationManager requestAlwaysAuthorization];
            }
        }
    }
    return _locationManager;
}

- (CLLocation *)currentLocation {
    return self.locationManager.location;
}

-(NSMutableArray *)monitoredRegions {
    if (!_monitoredRegions) {
        _monitoredRegions = [NSMutableArray array];
    }
    return _monitoredRegions;
}

@end
