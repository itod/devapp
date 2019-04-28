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
        NSString *cmdStr = [NSString stringWithFormat:@"$(PROJECT_SOURCE_DIR)/%@.%@", MAIN_FILE_BASE, MAIN_FILE_EXT];
        self.commandString = cmdStr;
    }
    return self;
}


- (void)dealloc {
    
    [super dealloc];
}

@end
