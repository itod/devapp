//
//  EDEnvironmentVariable.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/22/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDEnvironmentVariable.h"

@implementation EDEnvironmentVariable

- (id)init {
    self = [super init];
    if (self) {
        self.name = NSLocalizedString(@"UNTITLED", @"");
        self.value = NSLocalizedString(@"A value", @"");
    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    self.value = nil;
    [super dealloc];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.name = plist[@"name"];
        self.value = plist[@"value"];
    }
    return self;
}


- (NSDictionary *)asPlist {
    EDAssert(_name);
    EDAssert(_value);
    return @{@"name": _name,
             @"value": _value,
             };
}

@end
