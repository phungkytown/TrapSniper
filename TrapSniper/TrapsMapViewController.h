//
//  TrapsMapViewController.h
//  TrapSniper
//
//  Created by Hai Phung on 11/7/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface TrapsMapViewController : UIViewController <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;

@end
