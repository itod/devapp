//
//  EDAction.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDAction.h"
#import "EDEnvironmentVariable.h"

@implementation EDAction

+ (NSString *)name {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


+ (NSString *)displayName {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


+ (NSString *)iconName {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


+ (NSArray *)facetClassNames {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


- (id)init {
    self = [super init];
    if (self) {
        self.name = [[self class] name];
        self.displayName = [[self class] displayName];
        EDAssert([_name length]);
        EDAssert([_displayName length]);
        self.icon = [NSImage imageNamed:[[self class] iconName]];
        EDAssert(_icon);
        
        NSArray *envVars = [[EDUserDefaults instance] environmentVariables];
        self.environmentVariables = [NSMutableArray arrayWithCapacity:[envVars count]];
        for (NSDictionary *d in envVars) {
            EDEnvironmentVariable *envVar = [EDEnvironmentVariable fromPlist:d];
            EDAssert(envVar);
            if (envVar) [_environmentVariables addObject:envVar];
        }
        
    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    self.displayName = nil;
    self.icon = nil;
    self.commandString = nil;
    self.environmentVariables = nil;
    [super dealloc];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.name = [[self class] name];
        self.displayName = [[self class] displayName];
        self.commandString = plist[@"commandString"];
        
        NSArray *envVars = plist[@"environmentVariables"];
        self.environmentVariables = [NSMutableArray arrayWithCapacity:[envVars count]];
        for (NSDictionary *d in envVars) {
            EDEnvironmentVariable *envVar = [EDEnvironmentVariable fromPlist:d];
            EDAssert(envVar);
            if (envVar) [_environmentVariables addObject:envVar];
        }

        EDAssert([_name length]);
        EDAssert([_displayName length]);
        self.icon = [NSImage imageNamed:[[self class] iconName]];
        EDAssert(_icon);
    }
    return self;
}


- (NSDictionary *)asPlist {
    EDAssert(_commandString);
    EDAssert(_environmentVariables);
    
    NSMutableArray *envVars = [NSMutableArray arrayWithCapacity:[_environmentVariables count]];
    for (EDEnvironmentVariable *envVar in _environmentVariables) {
        id dict = [envVar asPlist];
        EDAssert(dict);
        if (dict) [envVars addObject:dict];
    }
    
    return @{@"commandString": _commandString,
             @"environmentVariables": envVars,
             };
}


//- (id)initWithCoder:(NSCoder *)coder {
//    self.name = [coder decodeObjectForKey:@"name"];
//    self.displayName = [coder decodeObjectForKey:@"displayName"];
//    self.iconName = [coder decodeObjectForKey:@"iconName"];
//    
//    self.icon = [NSImage imageNamed:_iconName];
//    EDAssert(_icon);
//
//    self.pythonExePath = [coder decodeObjectForKey:@"pythonExePath"];
//    self.commandString = [coder decodeObjectForKey:@"commandString"];
//    self.environmentVariables = [NSMutableArray arrayWithArray:[coder decodeObjectForKey:@"environmentVariables"]];
//    return self;
//}
//
//
//- (void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeObject:_name forKey:@"name"];
//    [coder encodeObject:_displayName forKey:@"displayName"];
//    [coder encodeObject:_iconName forKey:@"iconName"];
//    [coder encodeObject:_pythonExePath forKey:@"pythonExePath"];
//    [coder encodeObject:_commandString forKey:@"commandString"];
//    [coder encodeObject:_environmentVariables forKey:@"environmentVariables"];
//}

@end
