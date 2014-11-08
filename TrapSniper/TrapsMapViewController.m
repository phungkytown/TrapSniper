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
@property (nonatomic) NSMutableArray *regions;

@end

@implementation TrapsMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.locationManager startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

- (void)fetchTrapsNearLocation {
    PFGeoPoint *currentGeoPoint = [PFGeoPoint geoPointWithLocation:self.currentLocation];
    PFQuery *trapsQuery = [Trap query];
    [trapsQuery whereKey:@"location" nearGeoPoint:currentGeoPoint withinMiles:10.0];
    [trapsQuery orderByDescending:@"createdAt"];
    [trapsQuery setLimit:20];
    [trapsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self configureRegionsForTraps:objects radius:100.0];
        }
    }];
}

- (void)configureRegionsForTraps:(NSArray *)speedTraps radius:(CLLocationDistance)radius {
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
        
        // Add a visual representation for the region to the map view.
        MKCircle *regionCircle = [MKCircle circleWithCenterCoordinate:regionCenter radius:radius];
        [self.mapView addOverlay:regionCircle];
    }
    
    NSLog(@"%@", self.regions);
}

- (void)scheduleLocalNotificationForRegion:(CLCircularRegion *)region {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:@"Heads up! There's a speed trap nearby. <Region: %@>", region.identifier];
    notification.regionTriggersOnce = NO;
    notification.region = region;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)updateRegions {
    // Unregister regions currently being monitored.
    for (CLCircularRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    // Remove the overlays from the map view.
    [self.mapView removeOverlays:self.mapView.overlays];
}


#pragma mark - Map View Delegate

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
    // This method could fire frequently.
    // Is this where I want to perform fetches for new region data?
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entering region: %@", region.identifier);
    
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exiting region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Monitoring region: %@", region.identifier);
}


#pragma mark - Actions

- (IBAction)onFetchButtonTapped:(id)sender {
    [self fetchTrapsNearLocation];
}

- (IBAction)onZoomToLocationButtonTapped:(id)sender {
    MKCoordinateSpan currentRegionSpan = self.mapView.region.span;
    if (currentRegionSpan.latitudeDelta > 1.0 || currentRegionSpan.longitudeDelta > 1.0) {
        MKCoordinateRegion region;
        region.center = self.currentLocation.coordinate;
        region.span = MKCoordinateSpanMake(0.1, 0.1);
        [self.mapView setRegion:region animated:YES];
    } else {
        [self.mapView setCenterCoordinate:self.currentLocation.coordinate animated:YES];
    }
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            // If the user has turned off or denied authorization for location services,
            // then do nothing.
        } else {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
            _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
            
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

- (NSMutableArray *)regions {
    if (!_regions) {
        _regions = [NSMutableArray array];
    }
    return _regions;
}

@end
