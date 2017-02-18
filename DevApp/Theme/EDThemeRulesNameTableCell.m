//
//  EDThemeRulesNameTableCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/27/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDThemeRulesNameTableCell.h"

@implementation EDThemeRulesNameTableCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)cv {
    CGRect titleRect = [self titleRectForBounds:cellFrame];

    NSAttributedString *str = [self objectValue];
    EDAssert([str isKindOfClass:[NSAttributedString class]]);
    
    NSColor *bgColor = [[[str attribute:NSBackgroundColorAttributeName atIndex:1 effectiveRange:NULL] retain] autorelease];
    [bgColor setFill];
    [NSBezierPath fillRect:[self backgroundRectForBounds:cellFrame]];
    
    NSMutableAttributedString *mstr = [[str mutableCopy] autorelease];
    [mstr removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0, [mstr length])];
    [mstr drawInRect:titleRect];
}


- (NSRect)titleRectForBounds:(NSRect)bounds {
    CGRect r = [super titleRectForBounds:bounds];
    //r.origin.y += 1.0;
    r.origin.x += 3.0;
    r.size.width -= 3.0;
    return r;
}


- (NSRect)backgroundRectForBounds:(NSRect)bounds {
    CGRect r = bounds;
    r.origin.y += 1.0;
    r.size.height -= 1.0;
    return r;
}

@end
