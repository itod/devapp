//
//  EDTheme.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/26/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDTheme.h"

@interface EDTheme ()
@end

@implementation EDTheme

+ (EDTheme *)themeWithName:(NSString *)name attributes:(NSDictionary *)attrs {
    EDAssertMainThread();
    EDAssert([name length]);
    EDAssert([attrs count]);
    
    EDTheme *theme = [[[EDTheme alloc] initWithName:name attributes:attrs] autorelease];
    return theme;
}


- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attrs {
    self = [super init];
    if (self) {
        self.name = name;
        self.attributes = attrs;
    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    self.attributes = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p %@ %lu>", [self class], self, _name, [_attributes count]];
}

@end
