//
//  EDTestAction.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDTestAction.h"
#import "EDActionArgumentsFacet.h"

@implementation EDTestAction

+ (NSString *)name {
    return @"test";
}


+ (NSString *)displayName {
    return NSLocalizedString(@"Test", @"");
}


+ (NSString *)iconName {
    return NSImageNameListViewTemplate;
}


+ (NSArray *)facetClassNames {
    return @[[EDActionArgumentsFacet name]];
}


- (id)init {
    self = [super init];
    if (self) {
        self.commandString = @"$(PROJECT_SOURCE_DIR)/test.py"; // TODO
    }
    return self;
}


- (void)dealloc {
    
    [super dealloc];
}

@end
