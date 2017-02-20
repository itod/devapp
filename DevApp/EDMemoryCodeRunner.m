//
//  EDMemoryCodeRunner.m
//  DevApp
//
//  Created by Todd Ditchendorf on 2/20/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDMemoryCodeRunner.h"

@interface EDMemoryCodeRunner ()
@property (nonatomic, assign) id <EDCodeRunnerDelegate>delegate;
@end

@implementation EDMemoryCodeRunner

- (id)initWithDelegate:(id <EDCodeRunnerDelegate>)d {
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (void)dealloc {
    self.delegate = nil;
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
    
}

@end
