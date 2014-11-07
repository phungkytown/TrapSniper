//
//  ReportTrapViewController.m
//  TrapSniper
//
//  Created by Hai Phung on 11/6/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
#import "ReportTrapViewController.h"
#import "Trap.h"

@interface ReportTrapViewController () <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@end


@implementation ReportTrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (CLLocation *location in locations) {
        if (location.horizontalAccuracy <= self.locationManager.desiredAccuracy) {
            [self reportTrapForLocation:location];
            [self.locationManager stopUpdatingLocation];
            break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error.localizedDescription);
}


#pragma mark - Helper Methods

- (void)reportTrapForLocation:(CLLocation *)location {
    Trap *speedTrap = [Trap object];
    speedTrap.location = [PFGeoPoint geoPointWithLocation:location];
    [speedTrap saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"Speed trap reported successfully.");
        }
    }];
}


#pragma mark - Actions

- (IBAction)onReportTrapButtonPressed:(id)sender {
    [self.locationManager startUpdatingLocation];
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
            _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
            
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                [_locationManager requestAlwaysAuthorization];
            }
        }
    }
    return _locationManager;
}

@end
