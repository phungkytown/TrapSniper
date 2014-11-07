//
//  LocationService.h
//  TrapSniper
//
//  Created by Hai Phung on 11/6/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationService : NSObject <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;

+ (instancetype)sharedService;

@end
