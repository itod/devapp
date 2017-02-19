//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "NSString+EDAdditions.h"

#define HTTPSchemePrefix @"http://"
#define HTTPSSchemePrefix @"https://"
#define FileSchemePrefix @"file://"
#define JavaScriptSchemePrefix @"javascript:"

#define AboutBlank @"about:blank"

@implementation NSString (EDAdditions)

- (NSString *)stringByEnsuringURLSchemePrefix {
    if (![self hasSupportedSchemePrefix]) {
        return [NSString stringWithFormat:@"%@%@", HTTPSchemePrefix, self];
    }
    return self;
}


- (NSString *)stringByTrimmingURLSchemePrefix {
    NSString *s = [[self copy] autorelease];
    
    if ([s hasPrefix:HTTPSchemePrefix]) {
        s = [s substringFromIndex:[HTTPSchemePrefix length]];
    } else if ([s hasPrefix:HTTPSSchemePrefix]) {
        s = [s substringFromIndex:[HTTPSSchemePrefix length]];
    } else if ([s hasPrefix:FileSchemePrefix]) {
        s = [s substringFromIndex:[FileSchemePrefix length]];
    } else if ([s hasPrefix:JavaScriptSchemePrefix]) {
        s = [s substringFromIndex:[JavaScriptSchemePrefix length]];
    }
 
    return s;
}


- (NSString *)stringByEnsuringTLDSuffix {
    if (![self hasTLDSuffix]) {
        return [NSString stringWithFormat:@"%@.com", self];
    }
    return self;
}


- (BOOL)hasHTTPSchemePrefix {
    return [self hasPrefix:HTTPSchemePrefix] || [self hasPrefix:HTTPSSchemePrefix];
}


- (BOOL)hasJavaScriptSchemePrefix {
    return [self hasPrefix:JavaScriptSchemePrefix];
}


- (BOOL)hasSupportedSchemePrefix {
    return [self hasHTTPSchemePrefix] 
        || [self hasPrefix:FileSchemePrefix]
//        || [self hasPrefix:@"mailto:"] 
        || [self hasPrefix:@"about:"]
//        || [self hasPrefix:@"data:"] 
        || [self hasPrefix:@"file:"]
//        || [self hasPrefix:@"feed:"] 
//        || [self hasPrefix:@"rss:"] 
//        || [self hasPrefix:@"itunes:"] 
        || [self hasJavaScriptSchemePrefix];
}


- (BOOL)hasTLDSuffix {
    return (NSNotFound != [self rangeOfString:@"."].location);
}

@end
