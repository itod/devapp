//
//  EDPattern.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/31/13.
//
//

#import "EDPattern.h"
#import "EDWildcardPattern.h"
#import "EDRegexPattern.h"

@implementation EDPattern

+ (id)patternWithString:(NSString *)patternStr {
    NSParameterAssert([patternStr length]);
    
    if (![patternStr length]) return nil;
    
    BOOL isRegex = NO;
    
    NSUInteger len = [patternStr length];
    if (len > 2) {
        NSUInteger e = [patternStr rangeOfString:@"/" options:NSBackwardsSearch].location;
        isRegex = ([patternStr hasPrefix:@"/"] && e != NSNotFound && e > 1);
        
//        unichar a = [patternStr characterAtIndex:0];
//        unichar e = [patternStr characterAtIndex:len - 1];
//        
//        isRegex = (a == '/' && e == '/');
    }
    
    Class cls = Nil;
    if (isRegex) {
        cls = [EDRegexPattern class];
    } else {
        cls = [EDWildcardPattern class];
    }

    EDPattern *pat = [[[cls alloc] initWithString:patternStr] autorelease];
    
    NSAssert(pat, @"");
    return pat;
}


- (id)initWithString:(NSString *)s {
    self = [super init];
    if (self) {
        self.string = s;
    }
    return self;
}


- (void)dealloc {
    self.string = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ '%@'>", [self class], _string];
}


- (BOOL)isMatch:(NSString *)s {
    NSAssert1(0, @"must implement abstract method %s", __PRETTY_FUNCTION__);
    return NO;
}


- (void)stringDidChange {
    
}


#pragma mark -
#pragma mark Properties

- (void)setString:(NSString *)s {
    if (s != _string) {
        [_string release];
        _string = [s copy];
        
        [self stringDidChange];
    }
}

@end
