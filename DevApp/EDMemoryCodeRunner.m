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

@property (nonatomic, retain) NSPipe *stdOutPipe;
@property (nonatomic, retain) NSPipe *stdErrPipe;
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
    
    self.stdOutPipe = nil;
    self.stdErrPipe = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark EDCodeRunner

- (void)stop:(NSString *)identifier {
    
}


- (void)performCommand:(NSString *)cmd identifier:(NSString *)identifier {
    TDAssert([cmd length]);
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[kEDCodeRunnerDoneKey] = @NO;
    info[kEDCodeRunnerUserCommandKey] = cmd;
    
    [self resumeWithInfo:info];
}


// remove??
//- (void)setAllBreakpoints:(NSArray *)bpPlist identifier:(NSString *)identifier {
////    _interp.breakpointCollection = [XPBreakpointCollection fromPlist:bpPlist];
//}


- (void)setBreakpointsCollection:(XPBreakpointCollection *)bpColl identifier:(NSString *)identifier {
    TDAssert(_interp);
    
    _interp.breakpointCollection = bpColl;
}


- (void)clearAllBreakpoints:(NSString *)identifier {
    
}


- (void)run:(NSString *)userCmd inWorkingDirectory:(NSString *)workingDir exePath:(NSString *)exePath env:(NSDictionary *)envVars breakpointsEnabled:(BOOL)bpEnabled breakpoints:(XPBreakpointCollection *)bpColl identifier:(NSString *)identifier {
    TDAssertMainThread();
    TDAssert(userCmd);
    TDAssert(workingDir);
    TDAssert(identifier);
    TDAssert(self.delegate);

    self.identifier = identifier;
    self.debugSync = bpEnabled ? [[[TDInterpreterSync alloc] init] autorelease] : nil;

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
                id info = @{kEDCodeRunnerErrorKey: err, kEDCodeRunnerDoneKey: @YES};
                [self didFail:info];
                return;
            }

            [self doRun:srcStr filePath:userCmd breakpoints:bpColl];
        });
        
        if (bpEnabled) {
            [self awaitPause];
        }
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


- (void)stop {
    TDAssertMainThread();
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[kEDCodeRunnerDoneKey] = @YES;

    TDAssert(_controlThread);
    dispatch_async(_controlThread, ^{
        TDAssert(_debugSync);
        [_debugSync resumeWithInfo:info];
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
    // only called on CONTROL-THREAD
    TDAssertControlThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didPause:info];
    });
}


- (void)fireDelegateDidSucceed:(NSMutableDictionary *)info {
    // only called on CONTROL-THREAD
    TDAssertControlThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didSucceed:info];
    });
}


- (void)fireDelegateDidFail:(NSMutableDictionary *)info {
    // only called on CONTROL-THREAD
    TDAssertControlThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunner:self.identifier didFail:info];
    });
}


#pragma mark -
#pragma mark Private EXECUTE-THREAD

- (void)didPause:(NSMutableDictionary *)info {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    TDAssert(info);
    
    info[kEDCodeRunnerDoneKey] = @NO;
    
    TDAssert(_debugSync);
    [_debugSync pauseWithInfo:info];
    info = [_debugSync awaitResume];
    
    BOOL done = [info[kEDCodeRunnerDoneKey] boolValue];
    
    if (done) {
        TDAssert(0); // is this reached????
        [XPException raise:XPExceptionUserKill format:@"User stopped execution."];
        return;
    }
    
    NSMutableString *cmd = [[info[kEDCodeRunnerUserCommandKey] mutableCopy] autorelease];
    TDAssert([cmd length]);
    
    CFStringTrimWhitespace((CFMutableStringRef)cmd);
    
    //get on control thread
    TDAssert(_interp);
    
    NSRange wsRange = [cmd rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *prefix = [cmd substringWithRange:NSMakeRange(0, wsRange.location)];
    
    if ([@"c" isEqualToString:prefix] || [@"continue" isEqualToString:prefix]) {
        [_interp cont];
    } else if ([@"s" isEqualToString:prefix] || [@"step" isEqualToString:prefix]) {
        [_interp stepIn];
    } else if ([@"n" isEqualToString:prefix] || [@"next" isEqualToString:prefix]) {
        [_interp stepOver];
    } else if ([@"r" isEqualToString:prefix] | [@"return" isEqualToString:prefix]) {
        [_interp finish];
    } else if ([@"p" isEqualToString:prefix] || [@"print" isEqualToString:prefix]) {
        if (wsRange.length && [cmd length] > NSMaxRange(wsRange)) {
            NSString *suffix = [cmd substringFromIndex:NSMaxRange(wsRange)];
            [_interp print:suffix];
        }
    } else {
        TDAssert(0);
    }

}


- (void)didSucceed:(NSMutableDictionary *)info {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    TDAssert(info);
    
    info[kEDCodeRunnerDoneKey] = @YES;
    
    [self.debugSync pauseWithInfo:info];
}


- (void)didFail:(NSMutableDictionary *)info {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    TDAssert(info);
    
    info[kEDCodeRunnerDoneKey] = @YES;

    [self.debugSync pauseWithInfo:info];
}


- (void)doRun:(NSString *)srcStr filePath:(NSString *)path breakpoints:(XPBreakpointCollection *)bpColl {
    // only called on EXECUTE-THREAD
    TDAssertExecuteThread();
    
    PerformOnMainThread(^{
        TDAssert(self.delegate);
        TDAssert(self.identifier);
        [self.delegate codeRunnerDidStartup:self.identifier];
    });
    
    self.interp = [[[XPInterpreter alloc] init] autorelease];
    
    _interp.stdOut = _stdOutPipe.fileHandleForWriting;
    _interp.stdErr = _stdErrPipe.fileHandleForWriting;

    if (_debugSync) {
        _interp.debug = YES;
        _interp.debugDelegate = self;
        _interp.breakpointCollection = bpColl;
    }
    
    BOOL success = NO;
    
    NSError *err = nil;
    success = [_interp interpretString:srcStr filePath:path error:&err];
    
    if (success) {
        [self didSucceed:[[@{kEDCodeRunnerReturnCodeKey:@0, kEDCodeRunnerDoneKey:@YES} mutableCopy] autorelease]];
    } else {
        [self didFail:[[@{kEDCodeRunnerReturnCodeKey:@1, kEDCodeRunnerDoneKey:@YES, kEDCodeRunnerErrorKey:err} mutableCopy] autorelease]];
    }
}


#pragma mark -
#pragma mark XPInterpreterDebugDelegate

- (void)interpreter:(XPInterpreter *)i didPause:(NSMutableDictionary *)debugInfo {
    TDAssertExecuteThread();
    [self didPause:debugInfo];
}


- (void)interpreter:(XPInterpreter *)i didFinish:(NSMutableDictionary *)debugInfo {
    TDAssertExecuteThread();
    [self didSucceed:debugInfo];
}


- (void)interpreter:(XPInterpreter *)i didFail:(NSMutableDictionary *)debugInfo {
    TDAssertExecuteThread();
    [self didFail:debugInfo];
}

@end
