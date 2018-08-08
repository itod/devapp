//
//  FlatStyleCloseButton.m
//  Browser
//
//  Created by Todd Ditchendorf on 11/6/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FlatStyleCloseButton.h"
#import "FlatTabStyle.h"
#import <TDAppKit/TDUtils.h>

@implementation FlatStyleCloseButton

- (void)drawRect:(NSRect)dirtyRect {
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    NSColor *strokeColor = [FlatTabStyle iconColorForButton:self];

    CGContextSaveGState(ctx); {
        if (TKTabItemPointerStateDormant != self.pointerState) {
            [[FlatTabStyle highlightColorForButton:self] setFill];
            static NSBezierPath *bp = nil;
            if (!bp) {
                bp = [[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:2.0 yRadius:2.0] retain];
            }
            [bp fill];
        }
        
        CGContextSetLineCap(ctx, kCGLineCapButt);
        CGContextSetLineJoin(ctx, kCGLineJoinMiter);
        CGContextSetLineWidth(ctx, 2.0);
        
        [strokeColor setStroke];
        CGRect iconRect = CGRectInset(self.bounds, 3.0, 3.0);

        {
            static CGMutablePathRef path = NULL;
            if (!path) {
                path = CGPathCreateMutable();
                CGPathMoveToPoint(path, NULL, NSMinX(iconRect), NSMinY(iconRect));
                CGPathAddLineToPoint(path, NULL, NSMaxX(iconRect), NSMaxY(iconRect));
            }
            CGContextAddPath(ctx, path);
            CGContextStrokePath(ctx);
        }
        
        {
            static CGMutablePathRef path = NULL;
            if (!path) {
                path = CGPathCreateMutable();
                CGPathMoveToPoint(path, NULL, NSMaxX(iconRect), NSMinY(iconRect));
                CGPathAddLineToPoint(path, NULL, NSMinX(iconRect), NSMaxY(iconRect));
            }
            CGContextAddPath(ctx, path);
            CGContextStrokePath(ctx);
        }
    } CGContextRestoreGState(ctx);
}

@end
