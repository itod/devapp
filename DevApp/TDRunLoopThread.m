//
//  TDRunLoopThread.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 10/25/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "TDRunLoopThread.h"
#import <TDAppKit/TDUtils.h>

@interface TDRunLoopThread ()
@property (retain) NSThread *thread;
@property (assign) BOOL flag;
@property (copy) NSString *name;
@end

@implementation TDRunLoopThread

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        self.name = name;
    }
    return self;
}


- (void)dealloc {
    self.thread = nil;
    self.name = nil;
    [super dealloc];
}


- (void)start {
    TDAssert([NSThread currentThread] != _thread);
    
    self.thread = [[[NSThread alloc] initWithTarget:self selector:@selector(_threadMain) object:nil] autorelease];
    [_thread setName:[NSString stringWithFormat:@"%@-THREAD", _name]];
    
    [_thread start];
    //TDAssert([_thread isExecuting]);
    TDAssert(![_thread isFinished]);
}


- (void)stop {
    TDAssert([NSThread currentThread] != _thread);
    @synchronized(self) {
        self.flag = YES;
    }
}


- (void)_threadMain {
    TDAssertNotMainThread();
    TDAssert([NSThread currentThread] == _thread);
    
    @autoreleasepool {
        NSRunLoop *loop = [NSRunLoop currentRunLoop];
        NSTimer *dummySrc = [[[NSTimer alloc] initWithFireDate:[NSDate distantFuture]
                                                      interval:0.0
                                                        target:self
                                                      selector:@selector(_threadMain)
                                                      userInfo:nil
                                                       repeats:NO] autorelease];
        [loop addTimer:dummySrc forMode:NSDefaultRunLoopMode];
        
        while ([loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            @synchronized(self) {
                if (self.flag) {
                    self.flag = NO;
                    break;
                }
            }
        }
    }
}


- (void)_performAsync:(NSArray *)args {
    TDAssert([NSThread currentThread] != _thread);
    TDAssert(args);
    TDAssert(_thread);
    TDAssert([_thread isExecuting]);
    TDAssert(![_thread isFinished]);
    [self performSelector:@selector(_async:) onThread:_thread withObject:args waitUntilDone:NO];
}


- (void)_performSync:(NSArray *)args {
    TDAssert([NSThread currentThread] != _thread);
    TDAssert(args);
    TDAssert(_thread);
    TDAssert([_thread isExecuting]);
    TDAssert(![_thread isFinished]);
    [self performSelector:@selector(_sync:) onThread:_thread withObject:args waitUntilDone:YES];
}


- (void)_async:(NSArray *)args {
    TDAssert([NSThread currentThread] == _thread);
    TDAssertNotMainThread();
    
    NSUInteger c = [args count];
    TDAssert(1 == c || 2 == c);
    TDRunBlock block = args[0];
    
    NSError *err = nil;
    id result = block(&err);
    //NSLog(@"%@", result);
    
    TDCompletionBlock completion = nil;
    if (2 == c) {
        completion = args[1];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, err);
        });
    }
}


- (void)_sync:(NSArray *)args {
    TDAssert([NSThread currentThread] == _thread);
    TDAssertNotMainThread();
    TDAssert(1 == [args count]);
    TDBlock block = args[0];
    
    block();
}


- (void)performAsync:(TDBlock)block {
    TDAssert([NSThread currentThread] != _thread);
    NSParameterAssert(block);
    TDAssert(_thread);
    TDAssert([_thread isExecuting]);
    TDAssert(![_thread isFinished]);

    NSArray *args = @[[[block copy] autorelease]];
    [self _performAsync:args];
}


- (void)performAsync:(TDRunBlock)block completion:(TDCompletionBlock)completion {
    TDAssert([NSThread currentThread] != _thread);
    NSParameterAssert(block);
    NSParameterAssert(completion);
    TDAssert(_thread);
    TDAssert([_thread isExecuting]);
    TDAssert(![_thread isFinished]);

    NSArray *args = @[[[block copy] autorelease], [[completion copy] autorelease]];
    [self _performAsync:args];
}


- (void)performSync:(TDBlock)block {
    TDAssert([NSThread currentThread] != _thread);
    NSParameterAssert(block);
    TDAssert(_thread);
    TDAssert([_thread isExecuting]);
    TDAssert(![_thread isFinished]);

    NSArray *args = @[[[block copy] autorelease]];
    [self _performSync:args];
}

@end
