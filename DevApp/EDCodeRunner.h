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

@protocol EDCodeRunner;
@class EDFileLocation;

@protocol EDCodeRunnerDelegate <NSObject>
- (void)codeRunnerDidStartup:(NSString *)identifier;

- (void)codeRunner:(NSString *)identifier didUpdate:(NSData *)result;
- (void)codeRunner:(NSString *)identifier didSucceed:(NSData *)result;
- (void)codeRunner:(NSString *)identifier didFail:(NSError *)err;

- (void)codeRunner:(NSString *)identifier messageFromStdout:(NSString *)msg;
- (void)codeRunner:(NSString *)identifier messageFromStderr:(NSString *)msg;
@end

@protocol EDCodeRunner <NSObject>

- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d;

- (id <EDCodeRunnerDelegate>)delegate;
- (void)setDelegate:(id <EDCodeRunnerDelegate>)delegate;

- (void)stop:(NSString *)identifier;

- (void)performCommand:(NSString *)cmd identifier:(NSString *)identifier;

- (void)setAllBreakpoints:(NSArray *)bpPlist identifier:(NSString *)identifier;
- (void)clearAllBreakpoints:(NSString *)identifier;

@optional
- (void)run:(NSString *)userCmd inWorkingDirectory:(NSString *)workingDir exePath:(NSString *)exePath env:(NSDictionary *)envVars breakpointsEnabled:(BOOL)bpEnabled breakpoints:(NSArray *)bpPlist identifier:(NSString *)identifier;
@end
