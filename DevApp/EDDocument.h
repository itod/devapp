//
//  EDDocument.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TabKit/TKDocument.h>

@class EDBreakpointCollection;
@class EDTarget;
@class EDMainWindowController;

#define DEFAULT_DOC_TYPE_NAME FILE_DOC_TYPE

@interface EDDocument : TKDocument

- (BOOL)storeProjPlistOfType:(NSString *)typeName inDict:(NSMutableDictionary *)dict error:(NSError **)outErr;
- (BOOL)readProjPlistOfType:(NSString *)typeName inDict:(NSDictionary *)dict error:(NSError **)outErr;

- (BOOL)wantsCustomDisplayName;

@property (nonatomic, retain) EDBreakpointCollection *breakpoints;
@property (nonatomic, assign) BOOL breakpointsEnabled;

@property (nonatomic, retain) NSArray *targets;
@property (nonatomic, copy) NSString *selectedTargetName;
@property (nonatomic, retain, readonly) EDTarget *selectedTarget;
@property (nonatomic, retain, readonly) EDMainWindowController *mainWindowController;
@end
