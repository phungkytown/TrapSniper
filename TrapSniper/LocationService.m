//
//  LocationService.m
//  TrapSniper
//
//  Created by Hai Phung on 11/6/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import "LocationService.h"

@implementation LocationService

+ (instancetype)sharedService {
    static LocationService *sharedService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self alloc] init];
    });
    return sharedService;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        // Check authorization status before instantiating location manager.
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        if (authorizationStatus == kCLAuthorizationStatusRestricted || authorizationStatus == kCLAuthorizationStatusDenied) {
            // Do nothing.
        } else if (authorizationStatus == kCLAuthorizationStatusNotDetermined) {
            
        }
    }
    return self;
}

@end
