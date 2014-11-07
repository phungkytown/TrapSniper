//
//  Trap.m
//  TrapSniper
//
//  Created by Hai Phung on 11/6/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import "Trap.h"

@implementation Trap

@dynamic location;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"Trap";
}

@end
