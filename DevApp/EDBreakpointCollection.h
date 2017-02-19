//
//  EDBreakpointCollection.h
//  Editor
//
//  Created by Todd Ditchendorf on 8/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

@class OKBreakpoint;

@interface EDBreakpointCollection : EDModel <NSCopying> // NSSecureCoding>

- (NSArray *)allBreakpoints;
- (NSArray *)allFiles;

- (NSDictionary *)breakpointsDictionaryForFile:(NSString *)path;

- (NSSet *)breakpointsForFile:(NSString *)path;
- (NSArray *)sortedBreakpointsForFile:(NSString *)path;

- (void)addBreakpoint:(OKBreakpoint *)bp;
- (void)removeBreakpoint:(OKBreakpoint *)bp;
- (void)removeBreakpointsForFile:(NSString *)path;
@end
