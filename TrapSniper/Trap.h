//
//  Trap.h
//  TrapSniper
//
//  Created by Hai Phung on 11/6/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>

@interface Trap : PFObject <PFSubclassing>

@property (nonatomic) NSString *objectId;
@property (nonatomic) PFGeoPoint *location;
@property (nonatomic) NSDate *createdAt;

+ (NSString *)parseClassName;
+ (void)fetchTrapsNearLocation:(CLLocation *)location completionHandler:(void(^)(NSArray *))completion;

@end
