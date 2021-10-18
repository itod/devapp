//
//  TDDispatcherGDC.m
//  DevApp
//
//  Created by Todd Ditchendorf on 9/27/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "TDDispatcherGDC.h"

void PerformOnMainThread(void (^block)(void)) {
    assert(block);
    dispatch_async(dispatch_get_main_queue(), block);
}

@implementation TDDispatcherGDC {
    dispatch_queue_t _controlThread;
    dispatch_queue_t _executeThread;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _controlThread = dispatch_queue_create("CONTROL-THREAD", DISPATCH_QUEUE_SERIAL);
        _executeThread = dispatch_queue_create("EXECUTE-THREAD", DISPATCH_QUEUE_SERIAL);

    }
    return self;
}


- (void)dealloc {
    if (_controlThread) {dispatch_release(_controlThread); _controlThread = NULL;}
    if (_executeThread) {dispatch_release(_executeThread); _executeThread = NULL;}

    [super dealloc];
}


- (void)performOnMainThread:(void (^)(void))block {
    TDAssert(block);
    PerformOnMainThread(^{
        TDAssertMainThread();
        block();
    });
}


- (void)performOnControlThread:(void (^)(void))block {
    TDAssert(block);
    TDAssert(_controlThread);
    dispatch_async(_controlThread, ^{
        TDAssertControlThread();
        block();
    });
}


- (void)performOnExecuteThread:(void (^)(void))block {
    TDAssert(block);
    TDAssert(_executeThread);
    dispatch_async(_executeThread, ^{
        TDAssertExecuteThread();
        block();
    });
}

@end
