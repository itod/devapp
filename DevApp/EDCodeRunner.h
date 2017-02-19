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

- (void)codeRunnerWantsQuit:(NSString *)identifier;

- (void)codeRunner:(NSString *)identifier messageFromStdout:(NSString *)msg;
- (void)codeRunner:(NSString *)identifier messageFromStderr:(NSString *)msg;

@optional
- (NSString *)nameForCodeRunner:(id <EDCodeRunner>)runner;
@end

@protocol EDCodeRunner <NSObject>

- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d prompts:(NSArray *)prompts name:(NSString *)name;

- (id <EDCodeRunnerDelegate>)delegate;
- (void)setDelegate:(id <EDCodeRunnerDelegate>)delegate;

- (void)stop:(NSString *)identifier;

- (void)performCommand:(NSString *)cmd identifier:(NSString *)identifier;

- (void)setAllBreakpoints:(NSArray *)bpPlist identifier:(NSString *)identifier;
- (void)clearAllBreakpoints:(NSString *)identifier;

@optional
// Exedore API
- (void)run:(NSString *)userCmd inWorkingDirectory:(NSString *)workingDir exePath:(NSString *)exePath env:(NSDictionary *)envVars breakpointsEnabled:(BOOL)bpEnabled breakpoints:(NSArray *)bpPlist identifier:(NSString *)identifier;

// Schwartz API
- (void)run:(NSString *)userSource breakpoints:(NSArray *)bpPlist size:(CGSize)size isFlipped:(BOOL)isFlipped identifier:(NSString *)identifier;

// Jedi AutoComplete
- (void)initializeCompletions;
- (NSArray *)completionsFor:(NSString *)source line:(NSUInteger)line col:(NSUInteger)col path:(NSString *)path lineStartIndex:(NSUInteger)lineStartIdx insertionIndex:(NSUInteger)insIdx selectionIndex:(NSUInteger)selIdx;
- (NSArray *)definitionsFor:(NSString *)source line:(NSUInteger)line col:(NSUInteger)col path:(NSString *)path;
@end
