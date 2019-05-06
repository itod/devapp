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
#import <TDThreadUtils/TDLinkedQueue.h>
#import "TDDispatcherGDC.h"

#import <Language/Language.h>
#import "XPMemorySpace.h"
#import "XPFunctionSymbol.h"

#import "FNFrameRate.h"
#import "FNRedraw.h"
#import "FNLoop.h"
#import "FNShapeMode.h"
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
#import "FNContains.h"

#define kEDEventCategoryKey @"catetory"
#define kEDEventTypeKey @"type"
#define kEDEventMouseLocationKey @"mouseLocation"
#define kEDEventButtonNumberKey @"buttonNumber"

#define TD_INF (-(1e23f))

typedef NS_ENUM(NSUInteger, EDEventCategory) {
    EDEventCategoryInputDevice = 0, // mouse, keyboard, trackpad
    EDEventCategoryStop,
    EDEventCategoryPause,
    EDEventCategoryDraw,
    EDEventCategoryEnterDebug,
    EDEventCategoryExitDebug,
};

void TDPerformAfterDelay(dispatch_queue_t q, double delay, void (^block)(void)) {
    assert(block);
    assert(delay >= 0.0);

    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, q, block);
}

@interface PKToken ()
@property (nonatomic, readwrite) NSUInteger lineNumber;
@end

@interface EDMemoryCodeRunner ()
@property (assign) id <EDCodeRunnerDelegate>delegate; // weakref
@property (retain) XPInterpreter *interp;
@property (retain) TDInterpreterSync *debugSync;
@property (copy) NSString *identifier;
@property (copy) NSString *filePath;

@property (retain) NSPipe *stdOutPipe;
@property (retain) NSPipe *stdErrPipe;

@property (retain) id <TDDispatcher>dispatcher;
@property (retain) TDLinkedQueue *eventQueue;

@property (nonatomic, assign) BOOL waiting;

@property (nonatomic, retain) XPNode *drawBlockNode;
@property (nonatomic, retain) NSMutableDictionary *callBlockNodeCache;
@end

@implementation EDMemoryCodeRunner {
    CGPoint _mouseLocation;
}

- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d {
    TDAssert(d);
    self = [super init];
    if (self) {
        self.delegate = d;
    }
    return self;
}


- (void)dealloc {
    [self killResources];

    [super dealloc];
}


- (void)killResources {
    [self stopObservingCanvasDebugUpdate];

    self.delegate = nil;

    self.interp.delegate = nil;
    self.interp.stdOut = nil;
    self.interp.stdErr = nil;
    self.interp = nil;

    self.debugSync = nil;
    self.identifier = nil;
    self.filePath = nil;

    self.stdOutPipe.fileHandleForReading.readabilityHandler = nil;
    self.stdErrPipe.fileHandleForReading.readabilityHandler = nil;
    
    self.stdOutPipe = nil;
    self.stdErrPipe = nil;
    
    self.dispatcher = nil;
    self.eventQueue = nil;
    
    self.drawBlockNode = nil;
    self.callBlockNodeCache = nil;
}


- (void)startObservingCanvasDebugUpdate {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(canvasDidDebugUpdate:) name:FNCanvasDidDebugUpdateNotification object:self.identifier];
}


- (void)stopObservingCanvasDebugUpdate {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FNCanvasDidDebugUpdateNotification object:nil];
}


#pragma mark -
#pragma mark EDCodeRunner

- (void)stop:(NSString *)identifier {
    TDAssertMainThread();
    
    id stopEvt = @{kEDEventCategoryKey: @(EDEventCategoryStop)};
    TDAssert(_eventQueue);
    [_eventQueue put:stopEvt];

    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @YES, kEDCodeRunnerDoneKey,
                                 nil];
    
    [self resumeWithInfo:info];
}


- (void)performCommand:(NSString *)cmd identifier:(NSString *)identifier {
    TDAssertMainThread();
    TDAssert([cmd length]);
    
    if ([cmd isEqualToString:@"pause"]) {
        id pauseEvt = @{kEDEventCategoryKey: @(EDEventCategoryPause)};
        TDAssert(_eventQueue);
        [_eventQueue put:pauseEvt];
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @NO, kEDCodeRunnerDoneKey,
                                 cmd, kEDCodeRunnerUserCommandKey,
                                 nil];

    [self fireDelegateWillResume];
    [self resumeWithInfo:info];
}


- (void)setAllBreakpoints:(id)bpPlist identifier:(NSString *)identifier {
    TDAssertMainThread();
    
    XPBreakpointCollection *bpColl = nil;
    EDEventCategory evtCat = EDEventCategoryExitDebug;
    
    if (bpPlist) {
        bpColl = [XPBreakpointCollection fromPlist:bpPlist];
        evtCat = EDEventCategoryEnterDebug;
    }
    
    [_interp updateBreakpoints:bpColl];

    id evt = @{kEDEventCategoryKey: @(evtCat)};
    TDAssert(_eventQueue);
    [_eventQueue put:evt];
}


- (void)clearAllBreakpoints:(NSString *)identifier {
    TDAssertMainThread();
    [_interp updateBreakpoints:nil];
}


- (void)handleEvent:(NSDictionary *)evtTab {
    TDAssertMainThread();
    
    id inputDeviceEvt = [NSMutableDictionary dictionaryWithDictionary:evtTab];
    [inputDeviceEvt setObject:@(EDEventCategoryInputDevice) forKey:kEDEventCategoryKey];

    TDAssert(_eventQueue);
    [_eventQueue put:inputDeviceEvt];
}


- (void)run:(NSString *)userCmd workingDirectory:(NSString *)workingDir exePath:(NSString *)exePath env:(NSDictionary *)envVars breakpoints:(id)bpPlist identifier:(NSString *)identifier {
    TDAssertMainThread();
    TDAssert(userCmd);
    TDAssert(workingDir);
    TDAssert(identifier);
    TDAssert(_delegate);

    self.identifier = identifier;
    self.debugSync = [[[TDInterpreterSync alloc] init] autorelease];
    self.dispatcher = [[[TDDispatcherGDC alloc] init] autorelease];
    self.eventQueue = [[[TDLinkedQueue alloc] init] autorelease];

    self.stdOutPipe = [NSPipe pipe];
    self.stdErrPipe = [NSPipe pipe];
    
    self.drawBlockNode = nil;
    self.callBlockNodeCache = [NSMutableDictionary dictionary];
    
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
    TDAssert(_dispatcher);
    [_dispatcher performOnMainThread:block];
}


- (void)performOnControlThread:(void (^)(void))block {
    TDAssert(_dispatcher);
    [_dispatcher performOnControlThread:block];
}


- (void)performOnExecuteThread:(void (^)(void))block {
    TDAssert(_dispatcher);
    [_dispatcher performOnExecuteThread:block];
}


#pragma mark -
#pragma mark Private MAIN-THREAD

- (void)resumeWithInfo:(NSMutableDictionary *)info {
    TDAssertMainThread();
    
    [self performOnControlThread:^{
        TDAssert(_debugSync);

        [_debugSync resumeWithInfo:info];
        [self awaitPause];
    }];
}


#pragma mark -
#pragma mark Private CONTROL-THREAD

- (void)awaitPause {
    // only called on CONTROL-THREAD
    TDAssertControlThread();
    
    TDAssert(_debugSync);
    NSMutableDictionary *info = [_debugSync awaitPause];
    
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
        TDAssert(_delegate);
        TDAssert(self.identifier);
        [_delegate codeRunnerDidStartup:self.identifier];
    }];

}


- (void)fireDelegateWillCallSetup {
    // called on EXECUTE-THREAD
    TDAssertExecuteThread();
    
    [self performOnMainThread:^{
        TDAssert(_delegate);
        TDAssert(self.identifier);
        [_delegate codeRunnerWillCallSetup:self.identifier];
    }];

}


- (void)fireDelegateDidPause:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD
    TDAssertControlThread();
    
    [self performOnMainThread:^{
        TDAssert(_delegate);
        TDAssert(self.identifier);
        [_delegate codeRunner:self.identifier didPause:info];
    }];
}


- (void)fireDelegateWillResume {
    // called on CONTROL-THREAD or MAIN-THREAD

    [self performOnMainThread:^{
        TDAssert(_delegate);
        TDAssert(self.identifier);
        [_delegate codeRunnerWillResume:self.identifier];
    }];
}


- (void)fireDelegateDidSucceed:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD or EXECUTE-THREAD
    TDAssertNotMainThread();
    
    [self performOnMainThread:^{
        TDAssert(_delegate);
        TDAssert(self.identifier);
        [_delegate codeRunner:self.identifier didSucceed:info];
    }];
}


- (void)fireDelegateDidFail:(NSMutableDictionary *)info {
    // called on CONTROL-THREAD or EXECUTE-THREAD
    TDAssertNotMainThread();
    
    [self performOnMainThread:^{
        TDAssert(_delegate);
        TDAssert(self.identifier);
        [_delegate codeRunner:self.identifier didFail:info];
    }];
}


- (void)fireDelegateDidUpdate:(NSMutableDictionary *)info {
    // EXECUTE-THREAD
    TDAssertExecuteThread();
    
    [self performOnMainThread:^{
        TDAssert(_delegate);
        TDAssert(self.identifier);
        [_delegate codeRunner:self.identifier didUpdate:info];
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
    
    TDAssert(_debugSync);
    [_debugSync pauseWithInfo:inInfo];
    
    if (done) {
        // allow CONTROL-THREAD to complete naturally by not awaiting resume
        return;
    }
    
    NSMutableDictionary *outInfo = [_debugSync awaitResume];

    TDAssert(_interp);
    _interp.paused = NO;

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

    if (bpPlist) {
        [_interp updateBreakpoints:[XPBreakpointCollection fromPlist:bpPlist]];
        [self enterDebug];
    }
    
    // default "setup()" - just create reasonably-sized context
    [FNSize setupCanvasWithSize:CGSizeMake(480.0, 640.0) globals:_interp.globals];
    
    NSError *err = nil;
    [_interp interpretString:srcStr filePath:path error:&err];
    
    if (!err) {
        [self fireDelegateWillCallSetup];
        
        TDAssert(!err);
        XPNode *setupBlockNode = [self callBlockNodeForFunctionNamed:@"setup"];
        if (setupBlockNode) {
            [_interp eval:setupBlockNode filePath:path error:&err];
        }
    }
    
    if (!err) {
        [self fireDelegateWillResume];
        
        _mouseLocation = CGPointMake(TD_INF, TD_INF);
        [self updateMouseLocation:_mouseLocation button:-1];
        
        // EVENT LOOP
        err = nil;
        id evtTab = @{kEDEventCategoryKey: @(EDEventCategoryDraw)};

        do {
            @autoreleasepool {
                
                BOOL wantsDraw = NO;
                EDEventCategory evtCat = [[evtTab objectForKey:kEDEventCategoryKey] unsignedIntegerValue];

                if (EDEventCategoryStop == evtCat) {
                    err = [[NSError errorWithDomain:XPErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: XPUserInterruptException}] retain]; //+1
                    break;
                }
                
                else if (EDEventCategoryPause == evtCat) {
                    TDAssert(_interp);
                    _interp.paused = YES;
                }
                
                else if (EDEventCategoryInputDevice == evtCat) {
                    BOOL didHandle = [self processInputDeviceEvent:evtTab error:&err];
                    if (err) {[err retain]; break;} //+1
                    if (didHandle) {
                        wantsDraw = [[SZApplication instance] redrawForIdentifier:self.identifier] && ![[SZApplication instance] loopForIdentifier:self.identifier];
                    }
                }
                
                else if (EDEventCategoryDraw == evtCat) {
                    wantsDraw = YES;
                }
                
                else if (EDEventCategoryEnterDebug == evtCat) {
                    [self enterDebug];
                }
                
                else if (EDEventCategoryExitDebug == evtCat) {
                    [self exitDebug];
                }
                
                else {
                    TDAssert(0);
                }
                
                if (wantsDraw) {
                    BOOL didDraw = [self draw:&err];
                    if (err) {[err retain]; break;} //+1
                    [self renderContextToSharedImage];
                    
                    // if there's no draw() func, disable looping
                    if (didDraw) {
                        if ([[SZApplication instance] loopForIdentifier:self.identifier]) {
                            [self scheduleDraw];
                        }
                    } else {
                        [[SZApplication instance] setLoop:NO forIdentifier:self.identifier];
                        break;
                    }
                }
            }

            TDAssert(_eventQueue);
            evtTab = [_eventQueue take]; // blocks
            
        } while (1);
        
        [err autorelease]; //-1
    }
    
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


- (void)enterDebug {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    _interp.debug = YES;
    _interp.debugDelegate = self;

    [self startObservingCanvasDebugUpdate];
}


- (void)exitDebug {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    _interp.debug = NO;
    _interp.debugDelegate = nil;
    
    [self stopObservingCanvasDebugUpdate];
}


- (void)updateMouseLocation:(CGPoint)loc button:(NSInteger)button {
    TDAssert(_interp.globals);
    [_interp.globals setObject:[XPObject number:_mouseLocation.x] forName:@"pmouseX"];
    [_interp.globals setObject:[XPObject number:_mouseLocation.y] forName:@"pmouseY"];
    
    _mouseLocation = CGPointMake(round(loc.x), round(loc.y));
    [_interp.globals setObject:[XPObject number:_mouseLocation.x] forName:@"mouseX"];
    [_interp.globals setObject:[XPObject number:_mouseLocation.y] forName:@"mouseY"];

    [_interp.globals setObject:[XPObject number:button] forName:@"mouseButton"];
}


- (BOOL)processInputDeviceEvent:(NSDictionary *)evtTab error:(NSError **)outErr {
    TDAssertExecuteThread();
    
    BOOL didHandle = NO;
    
    NSString *type = [evtTab objectForKey:kEDEventTypeKey];
    CGPoint loc = [[evtTab objectForKey:kEDEventMouseLocationKey] pointValue];
    NSInteger button = [[evtTab objectForKey:kEDEventButtonNumberKey] integerValue];
    [self updateMouseLocation:loc button:button];
    
    TDAssert(_interp);
    XPNode *blockNode = [self callBlockNodeForFunctionNamed:type];
    if (blockNode) {
        [_interp eval:blockNode filePath:self.filePath error:outErr];
        didHandle = YES;
    }

    return didHandle;
}


- (XPNode *)drawBlockNode {
    if (!_drawBlockNode) {
        self.drawBlockNode = [self callBlockNodeForFunctionNamed:@"draw"];
    }
    return _drawBlockNode;
}


- (XPNode *)callBlockNodeForFunctionNamed:(NSString *)name {
    XPNode *result = [_callBlockNodeCache objectForKey:name];
    if (result) {
        return result;
    }
    
    XPObject *handler = [_interp.globals objectForName:name];
    if (handler && handler.isFunctionObject) {
        // (BLOCK (CALL (LOAD draw)))
        NSError *err = nil;
        NSString *input = [NSString stringWithFormat:@"%@()", name];
        result = [_interp parseInput:input error:&err];
        TDAssert(result);
        TDAssert(!err);
        
        [_callBlockNodeCache setObject:result forKey:name];
        //        PKToken *drawTok = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"draw" doubleValue:0.0];
        //        drawTok.tokenKind = TOKEN_KIND_BUILTIN_SYMBOL;
        //        XPNode *drawNode = [XPNode nodeWithToken:drawTok];
        //
        //        PKToken *loadTok = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"LOAD" doubleValue:0.0];
        //        loadTok.tokenKind = XP_TOKEN_KIND_LOAD;
        //        XPNode *loadNode = [XPNode nodeWithToken:loadTok];
        //
        //        PKToken *callTok = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"CALL" doubleValue:0.0];
        //        callTok.tokenKind = XP_TOKEN_KIND_CALL;
        //        XPNode *callNode = [XPNode nodeWithToken:callTok];
        //
        //        PKToken *blockTok = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"BLOCK" doubleValue:0.0];
        //        blockTok.tokenKind = XP_TOKEN_KIND_BLOCK;
        //        self.drawBlockNode = [XPNode nodeWithToken:blockTok];
        //
        //        // build
        //        [loadNode addChild:drawNode];
        //        [callNode addChild:loadNode];
        //        [_drawBlockNode addChild:callNode];
        //
        //        // line number
        //        XPObject *handler = [_interp.globals objectForName:@"draw"];
        //        TDAssert(handler && handler.isFunctionObject);
        //
        XPFunctionSymbol *sym = handler.value;
        NSInteger lineNumber = sym.blockNode.lineNumberNode.token.lineNumber;
        result.token.lineNumber = lineNumber;
    }
    return result;
}


- (BOOL)draw:(NSError **)outErr {
    TDAssertExecuteThread();
    
    BOOL didDraw = NO;
    
    [[SZApplication instance] setRedraw:NO forIdentifier:self.identifier];

    if (self.drawBlockNode) {
        [_interp eval:self.drawBlockNode filePath:self.filePath error:outErr];
        //[_interp interpretString:@"draw()" filePath:self.filePath error:outErr];
        didDraw = YES;
    }
    
    return didDraw;
}


- (void)renderContextToSharedImage {
    TDAssertExecuteThread();
    // Render ctx as img for use in UI/MainThread
    NSGraphicsContext *g = [[SZApplication instance] graphicsContextForIdentifier:self.identifier];
    CGContextRef ctx = [g graphicsPort];
    CGSize size = CGSizeMake(CGBitmapContextGetWidth(ctx), CGBitmapContextGetHeight(ctx));
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    NSImage *img = [[[NSImage alloc] initWithCGImage:cgimg size:size] autorelease];
    CGImageRelease(cgimg);
    
    [[SZApplication instance] setSharedImage:img forIdentifier:self.identifier];

    [self fireDelegateDidUpdate:nil];
}


- (void)scheduleDraw {
    TDAssertExecuteThread();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        TDAssertMainThread();
        if (self.waiting) return;
        self.waiting = YES;

        double frameRate = 1.0 / [[SZApplication instance] frameRateForIdentifier:self.identifier];
        TDPerformAfterDelay(dispatch_get_main_queue(), frameRate, ^{
            TDAssertMainThread();
            self.waiting = NO;

            id drawEvt = @{kEDEventCategoryKey: @(EDEventCategoryDraw)};
            TDAssert(_eventQueue);
            [_eventQueue put:drawEvt];
        });
    });
}


- (void)canvasDidDebugUpdate:(NSNotification *)n {
    TDAssertExecuteThread();
    [self renderContextToSharedImage];
}


#pragma mark -
#pragma mark XPInterpreterDelegate

- (void)interpreterDidDeclareNativeFunctions:(XPInterpreter *)i {
    TDAssertExecuteThread();
    [FNAbstractFunction setIdentifier:self.identifier];

    [i declareNativeFunction:[FNFrameRate class]];
    [i declareNativeFunction:[FNRedraw class]];
    [i declareNativeFunction:[FNLoop class]];
    [i declareNativeFunction:[FNShapeMode class]];
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
    [i declareNativeFunction:[FNContains class]];

    TDAssert(i.globals);
    [i declareNativeVariable:[XPObject number:M_PI] forName:@"PI"];
    [i declareNativeVariable:[XPObject number:M_PI_2] forName:@"HALF_PI"];
    [i declareNativeVariable:[XPObject number:M_PI_4] forName:@"QUARTER_PI"];
    [i declareNativeVariable:[XPObject number:M_PI*2.0] forName:@"TWO_PI"];

    [i declareNativeVariable:[XPObject number:0] forName:@"CORNER"];
    [i declareNativeVariable:[XPObject number:1] forName:@"CORNERS"];
    [i declareNativeVariable:[XPObject number:2] forName:@"CENTER"];
    [i declareNativeVariable:[XPObject number:3] forName:@"RADIUS"];
}


#pragma mark -
#pragma mark XPInterpreterDebugDelegate

- (void)interpreter:(XPInterpreter *)i didPause:(NSMutableDictionary *)debugInfo {
    TDAssertExecuteThread();
    [self pauseWithInfo:debugInfo];
}

@end
