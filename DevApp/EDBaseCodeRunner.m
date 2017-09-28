//
//  EDBaseCodeRunner.m
//  DevApp
//
//  Created by Todd Ditchendorf on 9/27/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDBaseCodeRunner.h"
#import "SZApplication.h"

#define USE_GCD 1

#if USE_GCD
#import "TDDispatcherGDC.h"
#else
#import "TDDispatcherThread.h"
#endif

@interface EDBaseCodeRunner ()
@property (retain) id <TDDispatcher>dispatcher;
@end

@implementation EDBaseCodeRunner

- (instancetype)init {
    self = [super init];
    if (self) {
#if USE_GCD
        self.dispatcher = [[[TDDispatcherGDC alloc] init] autorelease];
#else
        self.dispatcher = [[[TDDispatcherThread alloc] init] autorelease];
#endif
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
    [self.dispatcher performOnExecuteThread:^ {
        block();
    }];
}


#pragma mark -
#pragma mark Properties

@end
