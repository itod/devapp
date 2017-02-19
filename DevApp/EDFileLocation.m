//
//  EDFileLocation.m
//  Editor
//
//  Created by Todd Ditchendorf on 9/5/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFileLocation.h"

@interface EDFileLocation ()
@property (nonatomic, retain, readwrite) NSString *URLString;
@property (nonatomic, retain, readwrite) NSImage *icon;
@end

@implementation EDFileLocation

+ (instancetype)fromPlist:(NSDictionary *)plist {
    return [[[self alloc] initFromPlist:plist] autorelease];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.URLString = plist[@"URLString"];
        self.lineNumber = [plist[@"lineNumber"] unsignedIntegerValue];
        self.selectedRange = NSRangeFromString(plist[@"selectedRange"]);
        self.visibleRange = NSRangeFromString(plist[@"visibleRange"]);
    }
    return self;
}


- (NSDictionary *)asPlist {
    EDAssert(self.URLString);
    
    id d = @{@"URLString": _URLString,
             @"lineNumber": @(_lineNumber),
             @"selectedRange": NSStringFromRange(_selectedRange),
             @"visibleRange": NSStringFromRange(_visibleRange),
             };
    
    return d;
}


+ (EDFileLocation *)fileLocationWithURLString:(NSString *)URLString {
    EDFileLocation *res = [[[EDFileLocation alloc] initWithURLString:URLString] autorelease];
    res.lineNumber = 1;
    return res;
}


+ (EDFileLocation *)fileLocationWithURLString:(NSString *)URLString lineNumber:(NSUInteger)lineNum {
    EDFileLocation *res = [[[EDFileLocation alloc] initWithURLString:URLString] autorelease];
    res.lineNumber = lineNum;
    return res;
}


+ (EDFileLocation *)fileLocationWithURLString:(NSString *)URLString selectedRange:(NSRange)selRange {
    EDFileLocation *res = [[[EDFileLocation alloc] initWithURLString:URLString] autorelease];
    res.selectedRange = selRange;
    return res;
}


+ (EDFileLocation *)fileLocationWithURLString:(NSString *)URLString selectedRange:(NSRange)selRange visibleRange:(NSRange)visRange {
    EDFileLocation *res = [[[EDFileLocation alloc] initWithURLString:URLString] autorelease];
    res.selectedRange = selRange;
    res.visibleRange = visRange;
    return res;
}


- (id)initWithURLString:(NSString *)URLString {
    self = [super init];
    if (self) {
        self.URLString = URLString;
        _selected = YES;
        _selectedRange = NSMakeRange(NSNotFound, 0);
        _visibleRange = NSMakeRange(NSNotFound, 0);
    }
    return self;
}


- (void)dealloc {
    self.URLString = nil;
    self.preview = nil;
    self.icon = nil;
    [super dealloc];
}


//- (id)initWithCoder:(NSCoder *)coder {
//    EDAssert(0);
//    self.URLString = [coder decodeObjectForKey:@"URLString"];
//    self.lineNumber = [coder decodeIntegerForKey:@"lineNumber"];
//    self.selectedRange = NSRangeFromString([coder decodeObjectForKey:@"selectedRange"]);
//    self.visibleRange = NSRangeFromString([coder decodeObjectForKey:@"visibleRange"]);
//    self.preview = [coder decodeObjectForKey:@"preview"];
//    self.icon = [coder decodeObjectForKey:@"icon"];
//    self.selected = [coder decodeBoolForKey:@"selected"];
//    return self;
//}
//
//
//- (void)encodeWithCoder:(NSCoder *)coder {
//    EDAssert(0);
//    [coder encodeObject:_URLString forKey:@"URLString"];
//    [coder encodeInteger:_lineNumber forKey:@"lineNumber"];
//    [coder encodeObject:NSStringFromRange(_selectedRange) forKey:@"selectedRange"];
//    [coder encodeObject:NSStringFromRange(_visibleRange) forKey:@"visibleRange"];
//    [coder encodeObject:_preview forKey:@"preview"];
//    [coder encodeObject:_icon forKey:@"icon"];
//    [coder encodeBool:_selected forKey:@"selected"];
//}


- (id)copyWithZone:(NSZone *)zone {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    EDFileLocation *that = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return [that retain]; //+1
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p %@:%lu sel:%@  viz:%@>", [self class], self, [_URLString lastPathComponent], _lineNumber, NSStringFromRange(_selectedRange), NSStringFromRange(_visibleRange)];
}


- (BOOL)isEqual:(id)obj {
    if (![obj isMemberOfClass:[EDFileLocation class]]) {
        return NO;
    }

    EDFileLocation *that = (EDFileLocation *)obj;
    if (_lineNumber != that->_lineNumber) {
        return NO;
    }
    
    if (!NSEqualRanges(_selectedRange, that->_selectedRange)) {
        return NO;
    }
    
    if (![_URLString isEqualToString:that->_URLString]) {
        return NO;
    }

    return YES;
}


- (NSComparisonResult)compare:(EDFileLocation *)that {
    NSComparisonResult result = [_URLString compare:that->_URLString];
    
    if (NSOrderedSame == result) {
        if (_selectedRange.location < that->_selectedRange.location) {
            result = NSOrderedAscending;
        } else if (_selectedRange.location > that->_selectedRange.location) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedSame;
        }
    }
    
    return result;
}


- (NSString *)title {
    return [NSString stringWithFormat:@"%@:%lu", [_URLString lastPathComponent], _lineNumber];
}


- (BOOL)hasSelectedRange {
    return NSNotFound != _selectedRange.location;
}


- (BOOL)hasVisibleRange {
    return NSNotFound != _visibleRange.location;
}


- (void)setSelectedRange:(NSRange)selectedRange {
    _selectedRange = selectedRange;
}

@end
