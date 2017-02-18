//
//  EDRegexPattern.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/31/13.
//
//

#import "EDRegexPattern.h"

@interface EDRegexPattern ()
@property (nonatomic, retain) NSRegularExpression *regex;
@end

@implementation EDRegexPattern

- (void)dealloc {
    self.regex = nil;
    [super dealloc];
}


- (void)stringDidChange {
    NSString *str = self.string;
    NSUInteger strLen = [str length];

    if (!strLen) {
        self.regex = nil;
        return;
    }
    
    //NSLog(@"%@", str);
    
    NSAssert([str hasPrefix:@"/"], @"");
    if (![str hasPrefix:@"/"]) return;
    
    NSUInteger patStart = 1;
    NSUInteger patEnd = [str rangeOfString:@"/" options:NSBackwardsSearch].location;

    NSAssert(NSNotFound != patEnd, @"");
    if (NSNotFound == patEnd) return;

    if (patStart == patEnd) return;
    
    NSRange patRange = NSMakeRange(patStart, patEnd - patStart);
    
    NSString *pattern = [str substringWithRange:patRange];
    //NSLog(@"%@", pattern);
    
    NSString *modStr = nil;
    
    if (patEnd < strLen - 1) {
        modStr = [[str substringFromIndex:patEnd + 1] lowercaseString];
    }
    
    //NSLog(@"%@", modStr);
    BOOL caseSensitiveByDefault = [[NSUserDefaults standardUserDefaults] boolForKey:@"EDRegexPatternsDefaultCaseSensitive"];
    NSRegularExpressionOptions opts = caseSensitiveByDefault ? 0 : NSRegularExpressionCaseInsensitive;
    
    if ([modStr length]) {        
        if ([modStr rangeOfString:@"i"].length) {
            opts |= NSRegularExpressionCaseInsensitive;
        }
        
        if ([modStr rangeOfString:@"m"].length) {
            opts |= NSRegularExpressionAnchorsMatchLines;
        }

        if ([modStr rangeOfString:@"x"].length) {
            opts |= NSRegularExpressionAllowCommentsAndWhitespace;
        }
        
        if ([modStr rangeOfString:@"s"].length) {
            opts |= NSRegularExpressionDotMatchesLineSeparators;
        }
        
        if ([modStr rangeOfString:@"u"].length) {
            opts |= NSRegularExpressionUseUnicodeWordBoundaries;
        }
    }
    
    //NSString *escapedStr = [NSRegularExpression escapedPatternForString:regexStr];
    
    NSError *err = nil;
    self.regex = [NSRegularExpression regularExpressionWithPattern:pattern options:opts error:&err];
    if (!_regex) {
        NSLog(@"could not create Regex from pattern '%@'", self.string);
        if (err) NSLog(@"%@", err);
    }
}


- (BOOL)isMatch:(NSString *)s {
    if (![s length]) return NO;

    NSUInteger numMatches = [[_regex matchesInString:s options:0 range:NSMakeRange(0, [s length])] count];
    NSAssert(NSNotFound != numMatches, @"this would be surprising");
    
    if (NSNotFound == numMatches || 0 == numMatches) {
        return NO;
    } else {
        return YES;
    }
}

@end
