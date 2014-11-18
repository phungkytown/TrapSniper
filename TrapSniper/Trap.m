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

+ (void)fetchTrapsNearLocation:(CLLocation *)location completionHandler:(void(^)(NSArray *, NSError *))completion {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLocation:location];
    PFQuery *trapsQuery = [Trap query];
    [trapsQuery whereKey:@"location" nearGeoPoint:geoPoint withinMiles:10.0];
    [trapsQuery orderByDescending:@"createdAt"];
    [trapsQuery setLimit:20];
    [trapsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            completion(objects, nil);
        } else {
            completion(nil, error);
        }
    }];
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.location.latitude, self.location.longitude);
}

- (NSString *)title {
    return @"Speed Trap";
}

- (NSString *)subtitle {
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterLongStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return [NSString stringWithFormat:@"Reported on %@", [dateFormatter stringFromDate:self.createdAt]];
}

@end
