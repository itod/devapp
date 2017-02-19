//
//  EDTabBarStackTraceButtonCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/5/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDTabBarStackTraceButtonCell.h"
#import "EDUtils.h"
#import <TDAppKit/TDUtils.h>

#define BOX_MARGIN_X 7.5
#define BOX_MARGIN_Y 6.0
#define BOX_HEIGHT 2.0
#define MID_BOX_WIDTH 3.0

#define RECTS_LEN 5

@implementation EDTabBarStackTraceButtonCell

//+ (void)initialize {
//    if ([EDTabBarStackTraceButtonCell class] == self) {
//    }
//}


- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)cv {
//    [[NSColor greenColor] set];
//    NSRectFill(frame);

    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    BOOL isHi = [self isHighlighted];
    BOOL isMain = [[cv window] isMainWindow];
    
    CGGradientRef grad = [[self class] iconGradientForMain:isMain highlighted:isHi];
    NSColor *strokeColor = [[self class] iconStrokeColorForMain:isMain highlighted:isHi];
    NSShadow *shadow = [[self class] iconShadowForMain:isMain highlighted:isHi];

    [strokeColor setStroke];
    
    CGRect boxRects[RECTS_LEN];
    boxRects[0] = [self topRectForBounds:frame];
    boxRects[1] = [self bottomRectForBounds:frame];
    boxRects[2] = [self midLeftRectForBounds:frame];
    boxRects[3] = [self midMidRectForBounds:frame];
    boxRects[4] = [self midRightRectForBounds:frame];

    for (NSUInteger i = 0; i < RECTS_LEN; ++i) {
        CGRect boxRect = boxRects[i];
        CGContextAddRect(ctx, boxRect);
        
        CGContextSaveGState(ctx);
        CGContextClip(ctx);
        [shadow set];
        CGContextDrawLinearGradient(ctx, grad, boxRect.origin, CGPointMake(boxRect.origin.x, CGRectGetMaxY(boxRect)), 0);
        CGContextRestoreGState(ctx);
        
        CGContextStrokeRect(ctx, boxRect);
    }
}


- (CGRect)topRectForBounds:(CGRect)bounds {
    CGFloat x = TDFloorAlign(BOX_MARGIN_X);
    CGFloat y = TDFloorAlign(BOX_MARGIN_Y);
    CGFloat w = round(bounds.size.width - BOX_MARGIN_X*2.0);
    CGFloat h = round(BOX_HEIGHT);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)midLeftRectForBounds:(CGRect)bounds {
    CGFloat x = TDFloorAlign(BOX_MARGIN_X);
    CGFloat y = TDFloorAlign(CGRectGetMidY(bounds) - BOX_HEIGHT/2.0);
    CGFloat w = round(MID_BOX_WIDTH);
    CGFloat h = round(BOX_HEIGHT);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)midMidRectForBounds:(CGRect)bounds {
    CGFloat x = TDFloorAlign(CGRectGetMidX(bounds) - MID_BOX_WIDTH/2.0);
    CGFloat y = TDFloorAlign(CGRectGetMidY(bounds) - BOX_HEIGHT/2.0);
    CGFloat w = round(MID_BOX_WIDTH);
    CGFloat h = round(BOX_HEIGHT);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)midRightRectForBounds:(CGRect)bounds {
    CGFloat x = TDFloorAlign(CGRectGetMaxX(bounds) - MID_BOX_WIDTH - BOX_MARGIN_X);
    CGFloat y = TDFloorAlign(CGRectGetMidY(bounds) - BOX_HEIGHT/2.0);
    CGFloat w = round(MID_BOX_WIDTH);
    CGFloat h = round(BOX_HEIGHT);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)bottomRectForBounds:(CGRect)bounds {
    CGFloat x = TDFloorAlign(BOX_MARGIN_X);
    CGFloat y = TDFloorAlign(CGRectGetMaxY(bounds) - BOX_HEIGHT - BOX_MARGIN_Y);
    CGFloat w = round(bounds.size.width - BOX_MARGIN_X*2.0);
    CGFloat h = round(BOX_HEIGHT);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}

@end
