//
//  EDScheme.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDScheme.h"
#import "EDRunAction.h"
#import "EDTestAction.h"

@implementation EDScheme

- (id)init {
    self = [super init];
    if (self) {
        self.name = @"default";
        self.runAction = [[[EDRunAction alloc] init] autorelease];
        //self.testAction = [[[EDTestAction alloc] init] autorelease];
        self.selectedActionName = _runAction.name;
    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    self.selectedActionName = nil;
    self.runAction = nil;
    self.testAction = nil;
    self.actions = nil;
    [super dealloc];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.name = plist[@"name"];
        self.selectedActionName = plist[@"selectedActionName"];
        self.runAction = [EDRunAction fromPlist:plist[@"runAction"]];
        //self.testAction = [EDTestAction fromPlist:plist[@"testAction"]];
        self.selectedActionName = _runAction.name;
    }
    return self;
}


- (NSDictionary *)asPlist {
    EDAssert(_name);
    EDAssert(_selectedActionName);
    return @{@"name": _name,
             @"selectedActionName": _selectedActionName,
             @"runAction": [_runAction asPlist],
             //@"testAction": [_testAction asPlist]
             };
}


//- (id)initWithCoder:(NSCoder *)coder {
//    self.name = [coder decodeObjectForKey:@"name"];
//    self.selectedActionName = [coder decodeObjectForKey:@"selectedActionName"];
//    self.runAction = [coder decodeObjectForKey:@"runAction"];
//    self.testAction = [coder decodeObjectForKey:@"testAction"];
//    return self;
//}
//
//
//- (void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeObject:_name forKey:@"name"];
//    [coder encodeObject:_selectedActionName forKey:@"selectedActionName"];
//    [coder encodeObject:_runAction forKey:@"runAction"];
//    [coder encodeObject:_testAction forKey:@"testAction"];
//}


#pragma mark -
#pragma mark Properties

- (NSArray *)actions {
    if (!_actions) {
        self.actions = @[_runAction]; //, _testAction];
    }
    return _actions;
}

@end
