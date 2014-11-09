//
//  Trap.m
//  TrapSniper
//
//  Created by Hai Phung on 11/6/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import "Trap.h"

@implementation Trap

@dynamic objectId;
@dynamic location;
@dynamic createdAt;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"Trap";
}

+ (void)fetchTrapsNearLocation:(CLLocation *)location completionHandler:(void(^)(NSArray *))completion {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLocation:location];
    PFQuery *trapsQuery = [Trap query];
    [trapsQuery whereKey:@"location" nearGeoPoint:geoPoint withinMiles:5.0];
    [trapsQuery orderByDescending:@"createdAt"];
    [trapsQuery setLimit:20];
    [trapsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            completion(objects);
        }
    }];
}

@end
