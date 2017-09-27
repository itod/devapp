//
//  EDMemoryCodeRunner.m
//  DevApp
//
//  Created by Todd Ditchendorf on 2/20/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDMemoryCodeRunner.h"
#import "SZApplication.h"
#import <TDThreadUtils/TDInterpreterSync.h>
#import <Language/Language.h>

#import "XPMemorySpace.h"

#import "FNLoop.h"
#import "FNNoLoop.h"
#import "FNNoStroke.h"
#import "FNNoFill.h"
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
#import "FNBezier.h"

//typedef NS_ENUM(NSUInteger, EDCodeRunnerState) {
//    EDCodeRunnerStateInactive,
//    EDCodeRunnerStateActive,
//    EDCodeRunnerStateStopped,
//    EDCodeRunnerStatePaused,
//    EDCodeRunnerStateReceivedEvent,
//};

@interface EDMemoryCodeRunner ()
@property (assign) id <EDCodeRunnerDelegate>delegate; // weakref
@property (retain) XPInterpreter *interp;
@property (retain) TDInterpreterSync *debugSync;
@property (copy) NSString *identifier;
@property (copy) NSString *filePath;

@property (retain) NSPipe *stdOutPipe;
@property (retain) NSPipe *stdErrPipe;

@property (retain) NSRunLoop *runLoop;

@property (assign) BOOL stopped;
@property (assign) BOOL paused;
@end

@implementation EDMemoryCodeRunner

- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d {
    TDAssert(d);
    self = [super init];
    if (self) {
        self.delegate = d;
    }
    return self;
}


- (void)dealloc {

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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.stdOutPipe.fileHandleForReading.readabilityHandler = nil;
    self.stdErrPipe.fileHandleForReading.readabilityHandler = nil;
    
    self.stdOutPipe = nil;
    self.stdErrPipe = nil;
    
    self.runLoop = nil;

    [super killResources];
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
    TDAssertMainThread();
    TDAssert([cmd length]);
    
    if ([cmd isEqualToString:@"pause"]) {
        self.paused = YES;
    }
    
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


- (void)handleMouseEvent:(NSEvent *)evt {
    TDAssertMainThread();
//    [self performCommand:@"receivedEvent" identifier:self.identifier];
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
        
        [self performOnMainThread:^{
            TDAssert(_delegate);
            [_delegate codeRunner:_identifier messageFromStdOut:msg];
        }];
    };

    _stdErrPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *fh) {
        NSString *msg = [[[NSString alloc] initWithData:fh.availableData encoding:NSUTF8StringEncoding] autorelease];
        
        [self performOnMainThread:^{
            TDAssert(_delegate);
            [_delegate codeRunner:_identifier messageFromStdErr:msg];
        }];
    };

    [self performOnControlThread:^{
        [self performOnExecuteThread:^{
            // load source str
            NSError *err = nil;
            NSString *srcStr = [NSString stringWithContentsOfFile:userCmd encoding:NSUTF8StringEncoding error:&err];
            
            if (!srcStr) {
                NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             @YES, kEDCodeRunnerDoneKey,
                                             err, kEDCodeRunnerErrorKey,
                                             nil];
                [self fireDelegateDidFail:info];
                return;
            }
            
            [self doRun:srcStr filePath:userCmd breakpoints:bpPlist];
        }];
        
        [self awaitPause];
    }];
}


#pragma mark -
#pragma mark Private MAIN-THREAD

- (void)resumeWithInfo:(NSMutableDictionary *)info {
    TDAssertMainThread();
    
    [self performOnControlThread:^{
        TDAssert(self.debugSync);

        [self fireDelegateWillResume];

        [self.debugSync resumeWithInfo:info];
        [self awaitPause];
    }];
}


#pragma mark -
#pragma mark Private CONTROL-THREAD

- (void)awaitPause {
    // only called on CONTROL-THREAD
    TDAssertControlThread();
    
    TDAssert(self.debugSync);
    NSMutableDictionary *info = [self.debugSync awaitPause];
    
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


- (void)fireDelegateDidStartup {
    // called on EXECUTE-THREAD
    TDAssertExecuteThread();
    
    [self performOnMainThread:^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunnerDidStartup:self.identifier];
    }];

}


- (void)fireDelegateWillCallSetup {
    // called on EXECUTE-THREAD
    TDAssertExecuteThread();
    
    [self performOnMainThread:^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunnerWillCallSetup:self.identifier];
    }];

}


- (void)fireDelegateDidPause:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD
    TDAssertControlThread();
    
    [self performOnMainThread:^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didPause:info];
    }];
}


- (void)fireDelegateWillResume {
    // called on CONTROL-THREAD
    TDAssertControlThread();
    
    [self performOnMainThread:^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunnerWillResume:self.identifier];
    }];
}


- (void)fireDelegateDidSucceed:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD or EXECUTE-THREAD
    TDAssertNotMainThread();
    
    [self performOnMainThread:^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didSucceed:info];
    }];
}


- (void)fireDelegateDidFail:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD or EXECUTE-THREAD
    TDAssertNotMainThread();
    
    [self performOnMainThread:^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didFail:info];
    }];
}


- (void)fireDelegateDidUpdate:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD or EXECUTE-THREAD
    TDAssertNotMainThread();
    
    [self performOnMainThread:^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didUpdate:info];
    }];
}


#pragma mark -
#pragma mark Private EXECUTE-THREAD

- (void)pauseWithInfo:(NSMutableDictionary *)inInfo {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    TDAssert(inInfo);
    
    if (!inInfo[kEDCodeRunnerDoneKey]) {
        inInfo[kEDCodeRunnerDoneKey] = @NO;
    }
    
    TDAssert(self.debugSync);
    [self.debugSync pauseWithInfo:inInfo];
    NSMutableDictionary *outInfo = [self.debugSync awaitResume];
    
    BOOL done = [outInfo[kEDCodeRunnerDoneKey] boolValue];
    
    if (done) {
        [XPException raise:XPUserInterruptException format:@"User stopped execution."];
        return;
    }
    
    NSMutableString *cmd = [[outInfo[kEDCodeRunnerUserCommandKey] mutableCopy] autorelease];
    TDAssert([cmd length]);
    
    CFStringTrimWhitespace((CFMutableStringRef)cmd);
    
    NSRange wsRange = [cmd rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *prefix = nil;
    
    if (NSNotFound == wsRange.location) {
        prefix = cmd;
    } else {
        prefix = [cmd substringWithRange:NSMakeRange(0, wsRange.location)];
    }
    
    TDAssert(_interp);
    if ([@"pause" isEqualToString:prefix]) {
        [_interp pause];
    } else if ([@"c" isEqualToString:prefix] || [@"continue" isEqualToString:prefix]) {
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


- (BOOL)doRunLoop {
    TDAssertExecuteThread();

    self.runLoop = [NSRunLoop currentRunLoop];
    BOOL repeats = [[SZApplication instance] loopForIdentifier:self.identifier];

    if (repeats) {
        // DO I NEED TO SWITCH TO CONTROL THREAD HERE? YES
        NSTimer *t = [NSTimer timerWithTimeInterval:1.0/30.0 repeats:YES block:^(NSTimer *timer) {
            [self loop];
        }];
        
        [_runLoop addTimer:t forMode:NSDefaultRunLoopMode];
    }
    
    [self loop]; // first loop iter
    [_runLoop run]; // run the loop

    BOOL done = !repeats;
    return done;
}


- (void)loop {
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
        if (self.paused) {
            self.interp.paused = YES;
        }
        
        [self.interp interpretString:@"draw()" filePath:self.filePath error:&err];
        
        if (err) {
            NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @1, kEDCodeRunnerReturnCodeKey,
                                         err, kEDCodeRunnerErrorKey,
                                         nil];
            [self fireDelegateDidFail:info];
        }
    }
}


- (void)dieWithInfo:(NSMutableDictionary *)info {
    TDAssertExecuteThread();
    
    TDAssert(self.debugSync);
    [self.debugSync pauseWithInfo:info]; // allow CONTROL-THREAD to complete naturally
    // and then don't await resume
}


- (id)doRun:(NSString *)srcStr filePath:(NSString *)path breakpoints:(id)bpPlist {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    
    [self fireDelegateDidStartup];
    
    self.filePath = path;
    
    self.interp = [[[XPInterpreter alloc] init] autorelease];
    _interp.delegate = self;
    
    _interp.stdOut = _stdOutPipe.fileHandleForWriting;
    _interp.stdErr = _stdErrPipe.fileHandleForWriting;

    if (self.debugSync) {
        _interp.debug = YES;
        _interp.debugDelegate = self;
        _interp.breakpointCollection = [XPBreakpointCollection fromPlist:bpPlist];
    }
    
    NSError *err = nil;
    id result = [_interp interpretString:srcStr filePath:path error:&err];
    
    NSMutableDictionary *info = nil;
    if (err) {
        info = [[@{kEDCodeRunnerReturnCodeKey:@1, kEDCodeRunnerDoneKey:@YES, kEDCodeRunnerErrorKey:err} mutableCopy] autorelease];
    } else {
        info = [[@{kEDCodeRunnerReturnCodeKey:@0, kEDCodeRunnerDoneKey:@YES} mutableCopy] autorelease];
        
        [self fireDelegateWillCallSetup];
        
        TDAssert(!err);
        XPObject *setup = [_interp.globals objectForName:@"setup"];
        if (setup && setup.isFunctionObject) {
            [_interp interpretString:@"setup()" filePath:path error:&err];
        }
        if (err) {
            info = [[@{kEDCodeRunnerReturnCodeKey:@1, kEDCodeRunnerDoneKey:@YES, kEDCodeRunnerErrorKey:err} mutableCopy] autorelease];
        }
    }
    
    if (!err) {
        BOOL done = [self doRunLoop];
        [self pauseWithInfo:[[@{kEDCodeRunnerDoneKey:@(done)} mutableCopy] autorelease]];
    } else {
        [self dieWithInfo:info];
    }
    
    return result;
}


#pragma mark -
#pragma mark XPInterpreterDelegate

- (void)interpreterDidDeclareNativeFunctions:(XPInterpreter *)i {
    TDAssertExecuteThread();
    [FNAbstractFunction setIdentifier:self.identifier];

    [i declareNativeFunction:[FNLoop class]];
    [i declareNativeFunction:[FNNoLoop class]];
    [i declareNativeFunction:[FNNoStroke class]];
    [i declareNativeFunction:[FNNoFill class]];
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
    [i declareNativeFunction:[FNBezier class]];
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
