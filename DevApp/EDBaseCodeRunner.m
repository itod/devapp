//
//  EDBaseCodeRunner.m
//  DevApp
//
//  Created by Todd Ditchendorf on 9/27/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDBaseCodeRunner.h"
#import "TDDispatcherGDC.h"

@interface EDBaseCodeRunner ()
@property (retain) id <TDDispatcher>dispatcher;
@end

@implementation EDBaseCodeRunner

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dispatcher = [[[TDDispatcherGDC alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    [self killResources];

    self.dispatcher = nil;
    
    [super dealloc];
}


- (void)killResources {
}


#pragma mark -
#pragma mark Thread Control

- (void)performOnMainThread:(void (^)(void))block {
    [self.dispatcher performOnMainThread:block];
}


- (void)performOnControlThread:(void (^)(void))block {
    [self.dispatcher performOnControlThread:block];
}


- (void)performOnExecuteThread:(void (^)(void))block {
    [self.dispatcher performOnExecuteThread:block];
}


#pragma mark -
#pragma mark Properties

@end
