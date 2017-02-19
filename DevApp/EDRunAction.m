//
//  EDRunAction.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDRunAction.h"
#import "EDActionArgumentsFacet.h"
//#import "EDActionPreRunScriptFacet.h"

@implementation EDRunAction

+ (NSString *)name {
    return @"run";
}


+ (NSString *)displayName {
    return NSLocalizedString(@"Run", @"");
}


+ (NSString *)iconName {
    return NSImageNameRightFacingTriangleTemplate;
}


+ (NSArray *)facetClassNames {
    //return @[[EDActionPreRunScriptFacet name], [EDActionArgumentsFacet name]];
    return @[[EDActionArgumentsFacet name]];
}


- (id)init {
    self = [super init];
    if (self) {
        self.commandString = @"$(PROJECT_SOURCE_DIR)/main.py";
    }
    return self;
}


- (void)dealloc {
    
    [super dealloc];
}

@end
