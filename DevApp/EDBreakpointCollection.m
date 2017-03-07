//
//  EDBreakpointCollection.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDBreakpointCollection.h"
#import <OkudaKit/OKBreakpoint.h>

@interface EDBreakpointCollection ()
@property (nonatomic, retain) NSMutableDictionary *all;
- (NSMutableSet *)mutableBreakpointsForFile:(NSString *)path;
@end

@implementation EDBreakpointCollection

+ (BOOL)supportsSecureCoding {
    return YES;
}


+ (instancetype)fromPlist:(NSDictionary *)plist {
    return [[[self alloc] initFromPlist:plist] autorelease];
}


- (id)init {
    self = [super init];
    if (self) {
        self.all = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.all = nil;
    [super dealloc];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.all = [NSMutableDictionary dictionary];

        NSArray *plists = plist[@"all"];
        for (NSDictionary *d in plists) {
            OKBreakpoint *bp = [OKBreakpoint fromPlist:d];
            [self addBreakpoint:bp];
        }
    }
    return self;
}


- (NSDictionary *)asPlist {
    TDAssert(_all);
    
    NSArray *bps = [self allBreakpoints];

    NSMutableArray *plists = [NSMutableArray arrayWithCapacity:[bps count]];
    for (OKBreakpoint *bp in bps) {
        [plists addObject:[bp asPlist]];
    }
    
    return @{@"all": plists};
}


- (id)copyWithZone:(NSZone *)zone {
    // deep copy
    NSDictionary *plist = [self asPlist];
    EDBreakpointCollection *col = [EDBreakpointCollection fromPlist:plist];
    return [col retain]; // +1
}


- (NSArray *)allBreakpoints {
    TDAssertMainThread();
    TDAssert(_all);
    
    NSMutableArray *result = [NSMutableArray array];

    for (NSSet *bps in [_all allValues]) {
        for (OKBreakpoint *bp in bps) {
            [result addObject:bp];
        }
    }
    
    return result;
}


- (NSArray *)allFiles {
    TDAssertMainThread();
    TDAssert(_all);
    
    return [[_all allKeys] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSDictionary *)breakpointsDictionaryForFile:(NSString *)path {
    TDAssertMainThread();
    TDAssert(_all);

    NSMutableDictionary *dict = nil;
    NSMutableSet *bps = [self mutableBreakpointsForFile:path];
    
    if (bps)     {
        dict = [NSMutableDictionary dictionaryWithCapacity:[bps count]];
        for (OKBreakpoint *bp in bps) {
            dict[@(bp.lineNumber)] = bp;
        }
    }
    
    return dict;
}


- (NSSet *)breakpointsForFile:(NSString *)path {
    return [[[self mutableBreakpointsForFile:path] copy] autorelease];
}


- (NSArray *)sortedBreakpointsForFile:(NSString *)path {
    return [[[self mutableBreakpointsForFile:path] allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSMutableSet *)mutableBreakpointsForFile:(NSString *)path {
    TDAssertMainThread();
    TDAssert(_all);
    TDAssert([path length]);

    NSMutableSet *result = _all[path];
    return result;
}


- (void)addBreakpoint:(OKBreakpoint *)bp {
    TDAssertMainThread();
    TDAssert(_all);
    TDAssert(bp);
    
    NSString *key = [[bp.file copy] autorelease];
    TDAssert([key length]);
    
    NSMutableSet *bps = [self mutableBreakpointsForFile:key];

    if (!bps) {
        bps = [NSMutableSet set];
        _all[key] = bps;
    }
    
    [bps addObject:bp];
}


- (void)removeBreakpoint:(OKBreakpoint *)bp {
    TDAssertMainThread();
    TDAssert(_all);

    NSString *key = [[bp.file copy] autorelease];
    TDAssert([key length]);
    
    NSMutableSet *bps = [self mutableBreakpointsForFile:key];
    TDAssert(bps);
    
    TDAssert([bps containsObject:bp]);
    [bps removeObject:bp];
    
    if (![bps count]) {
        [self removeBreakpointsForFile:key];
    }
}


- (void)removeBreakpointsForFile:(NSString *)path {
    TDAssertMainThread();
    TDAssert(_all);
    TDAssert([path length]);

    [_all removeObjectForKey:path];
}

@end
