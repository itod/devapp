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
    EDAssert(_all);
    
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
    EDAssertMainThread();
    EDAssert(_all);
    
    NSMutableArray *result = [NSMutableArray array];

    for (NSSet *bps in [_all allValues]) {
        for (OKBreakpoint *bp in bps) {
            [result addObject:bp];
        }
    }
    
    return result;
}


- (NSArray *)allFiles {
    EDAssertMainThread();
    EDAssert(_all);
    
    return [[_all allKeys] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSDictionary *)breakpointsDictionaryForFile:(NSString *)path {
    EDAssertMainThread();
    EDAssert(_all);

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
    EDAssertMainThread();
    EDAssert(_all);
    EDAssert([path length]);

    NSMutableSet *result = _all[path];
    return result;
}


- (void)addBreakpoint:(OKBreakpoint *)bp {
    EDAssertMainThread();
    EDAssert(_all);
    EDAssert(bp);
    
    NSString *key = [[bp.file copy] autorelease];
    EDAssert([key length]);
    
    NSMutableSet *bps = [self mutableBreakpointsForFile:key];

    if (!bps) {
        bps = [NSMutableSet set];
        _all[key] = bps;
    }
    
    [bps addObject:bp];
}


- (void)removeBreakpoint:(OKBreakpoint *)bp {
    EDAssertMainThread();
    EDAssert(_all);

    NSString *key = [[bp.file copy] autorelease];
    EDAssert([key length]);
    
    NSMutableSet *bps = [self mutableBreakpointsForFile:key];
    EDAssert(bps);
    
    EDAssert([bps containsObject:bp]);
    [bps removeObject:bp];
    
    if (![bps count]) {
        [self removeBreakpointsForFile:key];
    }
}


- (void)removeBreakpointsForFile:(NSString *)path {
    EDAssertMainThread();
    EDAssert(_all);
    EDAssert([path length]);

    [_all removeObjectForKey:path];
}

@end
