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

#import "FNSize.h"
#import "FNPushStyle.h"
#import "FNPopStyle.h"
#import "FNTranslate.h"
#import "FNScale.h"
#import "FNRotate.h"
#import "FNBackground.h"
#import "FNStroke.h"
#import "FNStrokeWeight.h"
#import "FNStrokeCap.h"
#import "FNStrokeJoin.h"
#import "FNFill.h"
#import "FNRect.h"
#import "FNEllipse.h"
#import "FNArc.h"
#import "FNLine.h"

void PerformOnMainThread(void (^block)(void)) {
    assert(block);
    dispatch_async(dispatch_get_main_queue(), block);
}

void TDPerformAfterDelay(dispatch_queue_t q, double delay, void (^block)(void)) {
    assert(block);
    assert(delay >= 0.0);
    
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, q, block);
}

@interface EDMemoryCodeRunner ()
@property (assign) id <EDCodeRunnerDelegate>delegate; // weakref
@property (retain) XPInterpreter *interp;
@property (retain) TDInterpreterSync *debugSync;
@property (copy) NSString *identifier;

@property (retain) NSPipe *stdOutPipe;
@property (retain) NSPipe *stdErrPipe;

@property (assign) BOOL stopped;
@end

@implementation EDMemoryCodeRunner {
    dispatch_queue_t _controlThread;
    dispatch_queue_t _executeThread;
}

- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d {
    TDAssert(d);
    self = [super init];
    if (self) {
        self.delegate = d;

        _controlThread = dispatch_queue_create("CONTROL-THREAD", DISPATCH_QUEUE_SERIAL);
        _executeThread = dispatch_queue_create("EXECUTE-THREAD", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)dealloc {
    [self killResources];
    
    [super dealloc];
}


- (void)killResources {
    self.identifier = nil;
    self.delegate = nil;
    
    self.interp.delegate = nil;
    self.interp.stdOut = nil;
    self.interp.stdErr = nil;
    self.interp = nil;
    
    self.debugSync = nil;

    if (_controlThread) {dispatch_release(_controlThread), _controlThread = NULL;}
    if (_executeThread) {dispatch_release(_executeThread), _executeThread = NULL;}
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.stdOutPipe.fileHandleForReading.readabilityHandler = nil;
    self.stdErrPipe.fileHandleForReading.readabilityHandler = nil;
    
    self.stdOutPipe = nil;
    self.stdErrPipe = nil;
}


#pragma mark -
#pragma mark EDCodeRunner

- (void)stop:(NSString *)identifier {
    TDAssertMainThread();
    
    self.stopped = YES;
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @YES, kEDCodeRunnerDoneKey,
                                 nil];
    
    [self resumeWithInfo:info];
}


- (void)performCommand:(NSString *)cmd identifier:(NSString *)identifier {
    TDAssert([cmd length]);
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @NO, kEDCodeRunnerDoneKey,
                                 cmd, kEDCodeRunnerUserCommandKey,
                                 nil];
    [self resumeWithInfo:info];
}


- (void)setAllBreakpoints:(id)bpPlist identifier:(NSString *)identifier {
    [_interp updateBreakpoints:[XPBreakpointCollection fromPlist:bpPlist]];
}


- (void)clearAllBreakpoints:(NSString *)identifier {
    [_interp updateBreakpoints:nil];
}


- (void)run:(NSString *)userCmd inWorkingDirectory:(NSString *)workingDir exePath:(NSString *)exePath env:(NSDictionary *)envVars breakpointsEnabled:(BOOL)bpEnabled breakpoints:(id)bpPlist identifier:(NSString *)identifier {
    TDAssertMainThread();
    TDAssert(userCmd);
    TDAssert(workingDir);
    TDAssert(identifier);
    TDAssert(self.delegate);

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(canvasDidUpdate:) name:@"CanvasDidUpdateNotification" object:identifier];

    self.identifier = identifier;
    self.debugSync = [[[TDInterpreterSync alloc] init] autorelease];

    self.stdOutPipe = [NSPipe pipe];
    self.stdErrPipe = [NSPipe pipe];
    
    _stdOutPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *fh) {
        NSString *msg = [[[NSString alloc] initWithData:fh.availableData encoding:NSUTF8StringEncoding] autorelease];
        
        PerformOnMainThread(^{
            TDAssert(_delegate);
            [_delegate codeRunner:_identifier messageFromStdOut:msg];
        });
    };

    _stdErrPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *fh) {
        NSString *msg = [[[NSString alloc] initWithData:fh.availableData encoding:NSUTF8StringEncoding] autorelease];
        
        PerformOnMainThread(^{
            TDAssert(_delegate);
            [_delegate codeRunner:_identifier messageFromStdErr:msg];
        });
    };

    TDAssert(_controlThread);
    dispatch_async(_controlThread, ^{
        TDAssertControlThread();
        
        TDAssert(_executeThread);
        dispatch_async(_executeThread, ^{
            
            // load source str
            NSError *err = nil;
            NSString *srcStr = [NSString stringWithContentsOfFile:userCmd encoding:NSUTF8StringEncoding error:&err];
            
            if (!srcStr) {
                id info = [[@{kEDCodeRunnerErrorKey: err, kEDCodeRunnerDoneKey: @YES} mutableCopy] autorelease];
                [self fireDelegateDidFail:info];
                return;
            }

            [self doRun:srcStr filePath:userCmd breakpoints:bpPlist];
        });
        
        [self awaitPause];
    });
}


#pragma mark -
#pragma mark Private MAIN-THREAD

- (void)resumeWithInfo:(NSMutableDictionary *)info {
    TDAssertMainThread();
    
    TDAssert(_controlThread);
    dispatch_async(_controlThread, ^{
        TDAssert(_debugSync);
        [_debugSync resumeWithInfo:info];
        [self awaitPause];
    });
}


#pragma mark -
#pragma mark Private CONTROL-THREAD

- (void)awaitPause {
    // only called on CONTROL-THREAD
    TDAssertControlThread();
    
    TDAssert(_debugSync);
    NSMutableDictionary *info = [_debugSync awaitPause];
    
    BOOL done = [info[kEDCodeRunnerDoneKey] boolValue];
    
    if (done) {
        BOOL success = ![info[kEDCodeRunnerReturnCodeKey] boolValue];
        if (success) {
            [self fireDelegateDidSucceed:info];
        } else {
            [self fireDelegateDidFail:info];
        }
    } else {
        [self fireDelegateDidPause:info];
    }
}


- (void)fireDelegateDidPause:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD
    TDAssertControlThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didPause:info];
    });
}


- (void)fireDelegateDidSucceed:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD or EXECUTE-THREAD
    TDAssertNotMainThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didSucceed:info];
    });
}


- (void)fireDelegateDidFail:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD or EXECUTE-THREAD
    TDAssertNotMainThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didFail:info];
    });
}


- (void)fireDelegateDidUpdate:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD or EXECUTE-THREAD
    TDAssertNotMainThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didUpdate:info];
    });
}


#pragma mark -
#pragma mark Private EXECUTE-THREAD

- (void)pauseWithInfo:(NSMutableDictionary *)inInfo {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    TDAssert(inInfo);
    
    inInfo[kEDCodeRunnerDoneKey] = @NO;
    
    TDAssert(_debugSync);
    [_debugSync pauseWithInfo:inInfo];
    NSMutableDictionary *outInfo = [_debugSync awaitResume];
    
    BOOL done = [outInfo[kEDCodeRunnerDoneKey] boolValue];
    
    if (done) {
        [XPException raise:XPUserInterruptException format:@"User stopped execution."];
        return;
    }
    
    NSMutableString *cmd = [[outInfo[kEDCodeRunnerUserCommandKey] mutableCopy] autorelease];
    TDAssert([cmd length]);
    
    CFStringTrimWhitespace((CFMutableStringRef)cmd);
    
    //get on control thread
    TDAssert(_interp);
    
    NSRange wsRange = [cmd rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *prefix = nil;
    
    if (NSNotFound == wsRange.location) {
        prefix = cmd;
    } else {
        prefix = [cmd substringWithRange:NSMakeRange(0, wsRange.location)];
    }
    
    if ([@"c" isEqualToString:prefix] || [@"continue" isEqualToString:prefix]) {
        [_interp cont];
    } else if ([@"s" isEqualToString:prefix] || [@"step" isEqualToString:prefix]) {
        [_interp stepIn];
    } else if ([@"n" isEqualToString:prefix] || [@"next" isEqualToString:prefix]) {
        [_interp stepOver];
    } else if ([@"r" isEqualToString:prefix] || [@"return" isEqualToString:prefix] || [@"fin" isEqualToString:prefix] || [@"finish" isEqualToString:prefix]) {
        [_interp finish];
    } else if ([@"p" isEqualToString:prefix] || [@"po" isEqualToString:prefix] || [@"print" isEqualToString:prefix]) {
        if (wsRange.length && [cmd length] > NSMaxRange(wsRange)) {
            NSString *suffix = [cmd substringFromIndex:NSMaxRange(wsRange)];
            [_interp print:suffix];
        }
        [self pauseWithInfo:inInfo];
    } else {
        if ([prefix length]) {
            [_interp print:prefix];
        }
        [self pauseWithInfo:inInfo];
    }
}


- (void)loop {
    TDAssertExecuteThread();

    // DO I NEED TO SWITCH TO CONTROL THREAD HERE? YES
    NSTimer *t = [NSTimer timerWithTimeInterval:1.0/30.0 repeats:YES block:^(NSTimer *timer) {
        TDAssertExecuteThread();
        
        if (self.stopped) {
            NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @1, kEDCodeRunnerReturnCodeKey,
                                         @YES, kEDCodeRunnerDoneKey,
                                         [NSError errorWithDomain:XPErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:XPUserInterruptException}], kEDCodeRunnerErrorKey,
                                         nil];
            [self dieWithInfo:info];
        } else {
            TDAssert(self.interp);
            NSError *err = nil;
            [self.interp interpretString:@"draw()" filePath:nil error:&err];
        }
    }];
    
    [[NSRunLoop currentRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
}


- (void)dieWithInfo:(NSMutableDictionary *)info {
    TDAssertExecuteThread();
    
    TDAssert(_debugSync);
    [_debugSync pauseWithInfo:info]; // allow CONTROL-THREAD to complete naturally
    // and then don't await resume
}



- (void)doRun:(NSString *)srcStr filePath:(NSString *)path breakpoints:(id)bpPlist {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunnerDidStartup:self.identifier];
    });
    
    self.interp = [[[XPInterpreter alloc] init] autorelease];
    _interp.delegate = self;
    
    _interp.stdOut = _stdOutPipe.fileHandleForWriting;
    _interp.stdErr = _stdErrPipe.fileHandleForWriting;

    if (_debugSync) {
        _interp.debug = YES;
        _interp.debugDelegate = self;
        _interp.breakpointCollection = [XPBreakpointCollection fromPlist:bpPlist];
    }
    
    BOOL success = NO;
    
    NSError *err = nil;
    success = [_interp interpretString:srcStr filePath:path error:&err];
    
    NSMutableDictionary *info = nil;
    if (success) {
        info = [[@{kEDCodeRunnerReturnCodeKey:@0, kEDCodeRunnerDoneKey:@YES} mutableCopy] autorelease];
    } else {
        info = [[@{kEDCodeRunnerReturnCodeKey:@1, kEDCodeRunnerDoneKey:@YES, kEDCodeRunnerErrorKey:err} mutableCopy] autorelease];
    }
    
    BOOL live = YES;
    if (success && live) {
        [self loop];
        [self pauseWithInfo:[[@{kEDCodeRunnerDoneKey:@NO} mutableCopy] autorelease]];
    } else {
        [self dieWithInfo:info];
    }
}


#pragma mark -
#pragma mark XPInterpreterDelegate

- (void)interpreterDidDeclareNativeFunctions:(XPInterpreter *)i {
    TDAssertExecuteThread();
    [FNAbstractFunction setIdentifier:self.identifier];

    [i declareNativeFunction:[FNSize class]];
    [i declareNativeFunction:[FNPushStyle class]];
    [i declareNativeFunction:[FNPopStyle class]];
    [i declareNativeFunction:[FNTranslate class]];
    [i declareNativeFunction:[FNScale class]];
    [i declareNativeFunction:[FNRotate class]];
    [i declareNativeFunction:[FNBackground class]];
    [i declareNativeFunction:[FNStroke class]];
    [i declareNativeFunction:[FNStrokeWeight class]];
    [i declareNativeFunction:[FNStrokeCap class]];
    [i declareNativeFunction:[FNStrokeJoin class]];
    [i declareNativeFunction:[FNFill class]];
    [i declareNativeFunction:[FNRect class]];
    [i declareNativeFunction:[FNEllipse class]];
    [i declareNativeFunction:[FNArc class]];
    [i declareNativeFunction:[FNLine class]];
}


#pragma mark -
#pragma mark XPInterpreterDebugDelegate

- (void)interpreter:(XPInterpreter *)i didPause:(NSMutableDictionary *)debugInfo {
    TDAssertExecuteThread();
    [self pauseWithInfo:debugInfo];
}


#pragma mark -
#pragma mark Notifications

- (void)canvasDidUpdate:(NSNotification *)n {
    TDAssertExecuteThread();
    [self fireDelegateDidUpdate:nil];
}

@end
