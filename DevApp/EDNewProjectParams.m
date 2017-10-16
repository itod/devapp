//
//  EDNewProjectParams.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDNewProjectParams.h"

@implementation EDNewProjectParams

- (instancetype)init {
    self = [super init];
    if (self) {
        self.name = @".malerei";
    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    [super dealloc];
}

@end
