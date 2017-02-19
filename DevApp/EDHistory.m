//
//  EDHistory.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/25/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDHistory.h"

@interface EDHistory ()
@property (nonatomic, assign) NSUInteger cursor;
@property (nonatomic, retain) NSMutableArray *list;
@end

@implementation EDHistory

- (id)init {
    self = [super init];
    if (self) {
        [self clear];
    }
    return self;
}


- (void)dealloc {
    self.list = nil;
    [super dealloc];
}


- (id)initWithCoder:(NSCoder *)coder {
    self.cursor = [coder decodeIntegerForKey:@"cursor"];
    self.list = [coder decodeObjectForKey:@"list"];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:_cursor forKey:@"cursor"];
    [coder encodeObject:_list forKey:@"list"];
}


- (void)clear {
    self.cursor = 0;
    self.list = [NSMutableArray array];
}


- (void)fastForward {
    EDAssert(_list);
    
    NSUInteger len = [_list count];

    self.cursor = len;
    EDAssert(_cursor != NSNotFound);
}


- (BOOL)canGoBack {
    EDAssert(_cursor != NSNotFound);
    return _cursor > 1;
}


- (BOOL)canGoForward {
    EDAssert(_cursor != NSNotFound);
    NSUInteger len = [_list count];
    
    return len > 0 && _cursor < len;
}


- (id)current {
    EDAssert(_cursor != NSNotFound);
    EDAssert(_list);
    EDAssert(_cursor <= [_list count]);
    
    id item = nil;
    if (0 == _cursor) {
        EDAssert(0 == [_list count]);
        
    } else {
        item = [_list objectAtIndex:_cursor - 1];
    }
    
    return item;
}


- (void)insert:(id)item {
    EDAssert(_cursor != NSNotFound);
    EDAssert(_cursor <= [_list count]);
    EDAssert(_list);

    NSUInteger c = [_list count];
    if (_cursor != c) {
        NSRange r = NSMakeRange(_cursor, c - _cursor);
        [_list removeObjectsInRange:r];
    }
    [_list addObject:item];

    ++self.cursor;
}


- (id)goBackBy:(NSUInteger)i {
    EDAssert(i > 0 && NSNotFound != i);
    id item = nil;
    
    while (i > 0 && [self canGoBack]) {
        EDAssert(_cursor != NSNotFound);
        EDAssert(_cursor <= [_list count]);
        EDAssert(_list);
        
        EDAssert(_cursor > 0);
        if (_cursor == 0) return nil;
        
        --self.cursor;
        
        EDAssert(NSNotFound != _cursor);
        EDAssert(_cursor < [_list count]);
        EDAssert(_cursor > 0);
        
        item = [_list objectAtIndex:_cursor - 1];
        --i;
    }
    
    return item;
}


- (id)goForwardBy:(NSUInteger)i {
    EDAssert(i > 0 && NSNotFound != i);
    id item = nil;
    
    while (i > 0 && [self canGoForward]) {
        EDAssert(_cursor != NSNotFound);
        EDAssert(_list);
        
        EDAssert(_cursor < [_list count]);

        item = [_list objectAtIndex:_cursor];
        
        ++self.cursor;
        EDAssert(_cursor <= [_list count]);
        --i;
    }
    
    return item;
}


- (NSArray *)backList {
    EDAssert(_cursor != NSNotFound);
    EDAssert(_cursor <= [_list count]);
    EDAssert(_list);
    
    NSArray *result = nil;
    if (_cursor > 1) {
        NSMutableArray *marr = [NSMutableArray arrayWithCapacity:_cursor - 2];
        
        for (NSInteger i = _cursor - 2; i >= 0; --i) {
            id item = [_list objectAtIndex:i];
            [marr addObject:item];
        }
        
        result = [[marr copy] autorelease];
    }
    return result;
}


- (NSArray *)forwardList {
    EDAssert(_cursor != NSNotFound);
    EDAssert(_cursor <= [_list count]);
    EDAssert(_list);
    
    NSUInteger len = [_list count];
    NSArray *result = nil;
    if (_cursor < len) {
        NSMutableArray *marr = [NSMutableArray arrayWithCapacity:len - _cursor];
        
        for (NSInteger i = _cursor; i < len; ++i) {
            id item = [_list objectAtIndex:i];
            [marr addObject:item];
        }
        
        result = [[marr copy] autorelease];
    }
    return result;
}

@end
