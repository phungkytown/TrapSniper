//
//  TrapsMapViewController.m
//  TrapSniper
//
//  Created by Hai Phung on 11/7/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "TrapsMapViewController.h"

@interface TrapsMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

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

- (IBAction)onMarkRegionButtonTapped:(id)sender {
    // Create a region from the current location coordinate.
    CLLocationCoordinate2D regionCenter = self.currentLocation.coordinate;
    CLCircularRegion *circularRegion = [[CLCircularRegion alloc] initWithCenter:regionCenter radius:1000.0 identifier:@"Home"];
    [self.locationManager startMonitoringForRegion:circularRegion];
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

@end
