//
//  EDMemoryCodeRunner.m
//  DevApp
//
//  Created by Todd Ditchendorf on 2/20/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDMemoryCodeRunner.h"
#import <TDThreadUtils/TDInterpreterSync.h>
#import <Language/Language.h>

void PerformOnMainThread(void (^block)(void)) {
    assert(block);
    dispatch_async(dispatch_get_main_queue(), block);
}

@interface EDMemoryCodeRunner ()
@property (nonatomic, assign) id <EDCodeRunnerDelegate>delegate;
@property (nonatomic, retain) XPInterpreter *interp;
@property (nonatomic, retain) TDInterpreterSync *debugSync;
@property (nonatomic, copy) NSString *identifier;

@property (assign) dispatch_queue_t controlThread;
@property (assign) dispatch_queue_t executeThread;
@end

@implementation EDMemoryCodeRunner

- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d {
    TDAssert(d);
    self = [super init];
    if (self) {
        self.delegate = d;

        self.controlThread = dispatch_queue_create("CONTROL-THREAD", DISPATCH_QUEUE_SERIAL);
        self.executeThread = dispatch_queue_create("EXECUTE-THREAD", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)dealloc {
    self.delegate = nil;
    self.interp = nil;
    self.debugSync = nil;

    dispatch_release(_controlThread), _controlThread = NULL;
    dispatch_release(_executeThread), _executeThread = NULL;
    [super dealloc];
}


#pragma mark -
#pragma mark EDCodeRunner

- (void)stop:(NSString *)identifier {
    
}


- (void)performCommand:(NSString *)cmd identifier:(NSString *)identifier {
    
}


- (void)setAllBreakpoints:(NSArray *)bpPlist identifier:(NSString *)identifier {
    
}


- (void)clearAllBreakpoints:(NSString *)identifier {
    
}


- (void)run:(NSString *)userCmd inWorkingDirectory:(NSString *)workingDir exePath:(NSString *)exePath env:(NSDictionary *)envVars breakpointsEnabled:(BOOL)bpEnabled breakpoints:(NSArray *)bpPlist identifier:(NSString *)identifier {
    TDAssertMainThread();
    TDAssert(userCmd);
    TDAssert(workingDir);
    TDAssert(identifier);
    TDAssert(self.delegate);

    self.identifier = identifier;
    self.debugSync = bpEnabled ? [[[TDInterpreterSync alloc] init] autorelease] : nil;

    TDAssert(_controlThread);
    dispatch_async(_controlThread, ^{
        TDAssertControlThread();
        
        TDAssert(_executeThread);
        dispatch_async(_executeThread, ^{
            
            // load source str
            NSError *err = nil;
            NSString *srcStr = [NSString stringWithContentsOfFile:userCmd encoding:NSUTF8StringEncoding error:&err];
            
            if (!srcStr) {
                id info = @{kEDCodeRunnerErrorKey: err, kEDCodeRunnerDoneKey: @YES};
                [self didFail:info];
                return;
            }

            [self doRun:srcStr];
        });
        
        if (bpEnabled) {
            [self await];
        }
    });
}


#pragma mark -
#pragma mark Private MAIN-THREAD

- (void)resume {
    TDAssertMainThread();
    
    TDAssert(_controlThread);
    dispatch_async(_controlThread, ^{
        TDAssert(_debugSync);
        [_debugSync resumeWithInfo:@YES];
        [self await];
    });
}


- (void)stop {
    TDAssertMainThread();
    
    TDAssert(_controlThread);
    dispatch_async(_controlThread, ^{
        TDAssert(_debugSync);
        [_debugSync resumeWithInfo:@NO];
    });
}


#pragma mark -
#pragma mark Private CONTROL-THREAD

- (void)await {
    // only called on CONTROL-THREAD
    TDAssertControlThread();
    
    TDAssert(_debugSync);
    NSDictionary *info = [_debugSync awaitPause];
    
    id result = info[@"result"];
    TDAssert(result);
    
    BOOL done = [info[kEDCodeRunnerDoneKey] boolValue];
    
    [self fireDelegateDidPause:info isDone:done];
}


- (void)fireDelegateDidPause:(NSDictionary *)info isDone:(BOOL)done {
    // only called on CONTROL-THREAD
    TDAssertControlThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didPause:info];
    });
}


#pragma mark -
#pragma mark Private EXECUTE-THREAD

- (void)didSucceed:(NSDictionary *)info {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    NSParameterAssert(info);
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didSucceed:info];
    });
}


- (void)didFail:(NSDictionary *)info {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    NSParameterAssert(info);
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didFail:info];
    });
}


- (void)doRun:(NSString *)srcStr {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunnerDidStartup:self.identifier];
    });
    
    self.interp = [[[XPInterpreter alloc] init] autorelease];
    
    BOOL success = NO;
    
    NSError *err = nil;
    success = [_interp interpretString:srcStr error:&err];
    
    if (success) {
        [self didSucceed:@{kEDCodeRunnerReturnCodeKey:@0, kEDCodeRunnerDoneKey:@YES}];
    } else {
        [self didFail:@{kEDCodeRunnerReturnCodeKey:@1, kEDCodeRunnerDoneKey:@YES, kEDCodeRunnerErrorKey:err}];
    }
}

@end
