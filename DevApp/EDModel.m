//
//  EDModel.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/21/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

@implementation EDModel

+ (instancetype)fromPlist:(NSDictionary *)plist {
    return [[[self alloc] initFromPlist:plist] autorelease];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


- (NSDictionary *)asPlist {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}

@end
