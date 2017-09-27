//
//  TDDispatcherThread.m
//  DevApp
//
//  Created by Todd Ditchendorf on 9/27/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "TDDispatcherThread.h"
#import "TDRunLoopThread.h"

@interface TDDispatcherThread ()
@property (retain) TDRunLoopThread *controlThread;
@property (retain) TDRunLoopThread *executeThread;
@end

@implementation TDDispatcherThread

- (instancetype)init {
    self = [super init];
    if (self) {
        self.controlThread = [[[TDRunLoopThread alloc] initWithName:@"CONTROL"] autorelease];
        self.executeThread = [[[TDRunLoopThread alloc] initWithName:@"EXECUTE"] autorelease];

        [self.controlThread start];
        [self.executeThread start];
    }
    return self;
}


- (void)dealloc {
    [_controlThread stop];
    self.controlThread = nil;
    
    [_executeThread stop];
    self.executeThread = nil;

    [super dealloc];
}


- (void)performOnMainThread:(void (^)(void))block {
    TDAssert(block);
    dispatch_async(dispatch_get_main_queue(), ^{
        TDAssertMainThread();
        block();
    });
}


- (void)performOnControlThread:(void (^)(void))block {
    TDAssert(block);
    TDAssert(_controlThread);
    [self.controlThread performAsync:^{
        TDAssertControlThread();
        block();
    }];
}


- (void)performOnExecuteThread:(void (^)(void))block {
    TDAssert(block);
    TDAssert(_executeThread);
    [self.executeThread performAsync:^{
        TDAssertExecuteThread();
        block();
    }];
}

@end
