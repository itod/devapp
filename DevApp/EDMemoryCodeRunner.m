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
#import "TDDispatcherGDC.h"
#import "TDTrigger.h"

#import <Language/Language.h>
#import "XPMemorySpace.h"

#import "FNRedraw.h"
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

//typedef NSError *(^EDExecuteBlock)(void);

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
@property (copy) NSString *filePath;

@property (retain) NSPipe *stdOutPipe;
@property (retain) NSPipe *stdErrPipe;

@property (retain) id <TDDispatcher>dispatcher;
@property (retain) TDTrigger *trigger;
@property (retain) NSDictionary *event;

@property (assign) BOOL stopped;
@property (assign) BOOL paused;
@end

@implementation EDMemoryCodeRunner {
    dispatch_queue_t _triggerFireQueue;
    CGPoint _mouseLocation;
}

- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d {
    TDAssert(d);
    self = [super init];
    if (self) {
        self.delegate = d;
        _triggerFireQueue = dispatch_queue_create("TRIGGER-FIRE-THREAD", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)dealloc {
    [self killResources];

    if (_triggerFireQueue) {dispatch_release(_triggerFireQueue), _triggerFireQueue = NULL;}
    
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
    
    self.dispatcher = nil;
    self.trigger = nil;
    self.event = nil;
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


- (void)handleEvent:(NSDictionary *)evtTab {
    TDAssertMainThread();
    self.event = [[evtTab copy] autorelease];
    [self.trigger fire];
}


- (void)run:(NSString *)userCmd inWorkingDirectory:(NSString *)workingDir exePath:(NSString *)exePath env:(NSDictionary *)envVars breakpointsEnabled:(BOOL)bpEnabled breakpoints:(id)bpPlist identifier:(NSString *)identifier {
    TDAssertMainThread();
    TDAssert(userCmd);
    TDAssert(workingDir);
    TDAssert(identifier);
    TDAssert(self.delegate);

    self.identifier = identifier;
    self.debugSync = [[[TDInterpreterSync alloc] init] autorelease];
    self.dispatcher = [[[TDDispatcherGDC alloc] init] autorelease];

    self.stdOutPipe = [NSPipe pipe];
    self.stdErrPipe = [NSPipe pipe];
    
    self.stopped = NO;
    self.paused = NO;
    
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
                TDAssert(err);
                NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             @YES, kEDCodeRunnerDoneKey,
                                             err, kEDCodeRunnerErrorKey,
                                             nil];
                [self fireDelegateDidFail:info];
            } else {
                [self doRun:srcStr filePath:userCmd breakpoints:bpPlist];
            }
        }];
        
        [self awaitPause];
    }];
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
    
    BOOL done = [[info objectForKey:kEDCodeRunnerDoneKey] boolValue];
    
    if (done) {
        BOOL success = ![[info objectForKey:kEDCodeRunnerReturnCodeKey] boolValue];
        if (success) {
            [self fireDelegateDidSucceed:info];
        } else {
            [self fireDelegateDidFail:info];
        }
    } else {
        // TODO must distinguish sleep (waiting for scheduled draw) vs paused (hit bp)
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
    
    BOOL done = NO;
    id doneObj = [inInfo objectForKey:kEDCodeRunnerDoneKey];
    if (doneObj) {
        done = [doneObj boolValue];
    } else {
        [inInfo setObject:@(done) forKey:kEDCodeRunnerDoneKey];
    }
    
    TDAssert(self.debugSync);
    [self.debugSync pauseWithInfo:inInfo];
    
    if (done) {
        // allow CONTROL-THREAD to complete naturally by not awaiting resume
        return;
    }
    
    NSMutableDictionary *outInfo = [self.debugSync awaitResume];

    self.paused = NO;
    TDAssert(self.interp);
    self.interp.paused = NO;

    done = [[outInfo objectForKey:kEDCodeRunnerDoneKey] boolValue];
    
    if (done) {
        [XPException raise:XPUserInterruptException format:@"User stopped execution."];
        return;
    }
    
    NSMutableString *cmd = [[[outInfo objectForKey:kEDCodeRunnerUserCommandKey] mutableCopy] autorelease];
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


- (void)doRun:(NSString *)srcStr filePath:(NSString *)path breakpoints:(id)bpPlist {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    
    [self fireDelegateDidStartup];
    
    self.filePath = path;
    
    self.interp = [[[XPInterpreter alloc] initWithDelegate:self] autorelease];
    
    _interp.stdOut = _stdOutPipe.fileHandleForWriting;
    _interp.stdErr = _stdErrPipe.fileHandleForWriting;

    if (self.debugSync) {
        _interp.debug = YES;
        _interp.debugDelegate = self;
        _interp.breakpointCollection = [XPBreakpointCollection fromPlist:bpPlist];
    }
    
    NSError *err = nil;
    [_interp interpretString:srcStr filePath:path error:&err];
    
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
    
    _mouseLocation = CGPointZero;
    [self updateMouseLocation:_mouseLocation];
    
    // EVENT LOOP
    {
        NSError *err = nil;
        do {
            if (self.stopped) {
                err = [NSError errorWithDomain:XPErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: XPUserInterruptException}];
                break;
            }
            if (self.paused) {
                TDAssert(self.interp);
                self.interp.paused = YES;
            }
            
            BOOL wantsDraw = YES;
            
            // handle event or draw
            if (self.event) {
                wantsDraw = NO;
                err = [self processEvent];
                if (err) break;
                wantsDraw = [[SZApplication instance] redrawForIdentifier:self.identifier];
            }
            
            if (wantsDraw) {
                [[SZApplication instance] setRedraw:NO forIdentifier:self.identifier];
                err = [self draw];
                if (err) break;
            }
            
            self.trigger = [TDTrigger trigger];
            
            if ([[SZApplication instance] loopForIdentifier:self.identifier]) {
                [self updateLater];
            }
            
            [self.trigger await];
            self.trigger = nil;
            
        } while (1);
        
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @YES, kEDCodeRunnerDoneKey,
                                     nil];
        if (err) {
            [info setObject:err forKey:kEDCodeRunnerErrorKey];
            [info setObject:@1 forKey:kEDCodeRunnerReturnCodeKey];
            [self fireDelegateDidFail:info]; // ??
        } else {
            [info setObject:@0 forKey:kEDCodeRunnerReturnCodeKey];
            [self pauseWithInfo:info];
        }
    }
}


- (void)updateMouseLocation:(CGPoint)loc {
    TDAssert(self.interp.globals);
    [self.interp.globals setObject:[XPObject number:_mouseLocation.x] forName:@"pmouseX"];
    [self.interp.globals setObject:[XPObject number:_mouseLocation.y] forName:@"pmouseY"];
    
    _mouseLocation = CGPointMake(round(loc.x), round(loc.y));
    [self.interp.globals setObject:[XPObject number:_mouseLocation.x] forName:@"mouseX"];
    [self.interp.globals setObject:[XPObject number:_mouseLocation.y] forName:@"mouseY"];
}


- (NSError *)processEvent {
    TDAssertExecuteThread();
    
    NSString *type = [self.event objectForKey:@"type"];
    [self updateMouseLocation:[[self.event objectForKey:@"mouseLocation"] pointValue]];

    self.event = nil;
    
    NSError *err  = nil;
    XPObject *handler = [_interp.globals objectForName:type];
    if (handler && handler.isFunctionObject) {
        [self.interp interpretString:[NSString stringWithFormat:@"%@()", type] filePath:self.filePath error:&err];
    }
    return err;
}


- (NSError *)draw {
    NSError *err  = nil;
    XPObject *handler = [_interp.globals objectForName:@"draw"];
    if (handler && handler.isFunctionObject) {
        [self.interp interpretString:@"draw()" filePath:self.filePath error:&err];

        [self fireDelegateDidUpdate:nil];
    }
    return err;
}


- (void)updateLater {
    TDAssertExecuteThread();
    
    static double duration = 1.0/30;

    TDAssert(_triggerFireQueue);
    TDPerformAfterDelay(_triggerFireQueue, duration, ^{
        [self.trigger fire];
    });
}


#pragma mark -
#pragma mark XPInterpreterDelegate

- (void)interpreterDidDeclareNativeFunctions:(XPInterpreter *)i {
    TDAssertExecuteThread();
    [FNAbstractFunction setIdentifier:self.identifier];

    [i declareNativeFunction:[FNRedraw class]];
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

@end
