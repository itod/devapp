//
//  EDMemoryCodeRunner.m
//  DevApp
//
//  Created by Todd Ditchendorf on 2/20/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDMemoryCodeRunner.h"
#import <Language/Language.h>

@interface EDMemoryCodeRunner ()
@property (nonatomic, assign) id <EDCodeRunnerDelegate>delegate;
@property (nonatomic, retain) XPInterpreter *interp;
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
    self.delegate = nil;
    self.interp = nil;
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
    TDAssert(_delegate);
    
    
    NSError *err = nil;
    NSString *srcStr = [NSString stringWithContentsOfFile:userCmd encoding:NSUTF8StringEncoding error:&err];
    if (!srcStr) {
        [_delegate codeRunner:identifier didFail:err];
        return;
    }
    
    self.interp = [[[XPInterpreter alloc] init] autorelease];
    
    err = nil;
    if (![_interp interpretString:srcStr error:&err]) {
        [_delegate codeRunner:identifier didFail:err];
        return;
    } else {
        [_delegate codeRunner:identifier didSucceed:nil];
    }
}

@end
