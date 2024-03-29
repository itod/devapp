//
//  EDCodeRunner.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/26/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kEDCodeRunnerCompileTimeError 0
#define kEDCodeRunnerRuntimeError 1

#define kEDCodeRunnerDoneKey @"done"
#define kEDCodeRunnerUserCommandKey @"userCommand"
#define kEDCodeRunnerReturnCodeKey @"returnCode"
#define kEDCodeRunnerFrameStackKey @"frameStack"
#define kEDCodeRunnerLineNumberKey @"lineNumber"
#define kEDCodeRunnerRangeKey @"range"
#define kEDCodeRunnerErrorKey @"error"

@protocol EDCodeRunner;
@class EDFileLocation;
@class EDBreakpointCollection;

@protocol EDCodeRunnerDelegate <NSObject>
- (void)codeRunnerDidStartup:(NSString *)identifier;
- (void)codeRunnerWillCallSetup:(NSString *)identifier;

- (void)codeRunner:(NSString *)identifier didPause:(NSDictionary *)info;
- (void)codeRunnerWillResume:(NSString *)identifier;

- (void)codeRunner:(NSString *)identifier didSucceed:(NSDictionary *)info;
- (void)codeRunner:(NSString *)identifier didFail:(NSDictionary *)info;
- (void)codeRunner:(NSString *)identifier didUpdate:(NSDictionary *)info;

- (void)codeRunner:(NSString *)identifier messageFromStdOut:(NSString *)msg;
- (void)codeRunner:(NSString *)identifier messageFromStdErr:(NSString *)msg;
@end

@protocol EDCodeRunner <NSObject>

@optional
- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d;
- (void)killResources;

- (id <EDCodeRunnerDelegate>)delegate;
- (void)setDelegate:(id <EDCodeRunnerDelegate>)delegate;

- (void)stop:(NSString *)identifier;

- (void)performCommand:(NSString *)cmd identifier:(NSString *)identifier;

- (void)setAllBreakpoints:(NSArray *)bpPlist identifier:(NSString *)identifier;
- (void)clearAllBreakpoints:(NSString *)identifier;

- (void)handleEvent:(NSDictionary *)evtTab;

- (void)run:(NSString *)userCmd workingDirectory:(NSString *)workingDir exePath:(NSString *)exePath env:(NSDictionary *)envVars breakpoints:(id)bpPlist identifier:(NSString *)identifier;
@end
