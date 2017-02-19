//
//  EDTabBarFilesystemButtonCell
//  Editor
//
//  Created by Todd Ditchendorf on 8/5/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDTabBarFilesystemButtonCell.h"
#import "EDUtils.h"
#import <TDAppKit/TDUtils.h>

@implementation EDTabBarFilesystemButtonCell

//+ (void)initialize {
//    if ([EDTabBarFilesystemButtonCell class] == self) {
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
    
#define ARROW_MARGIN_LEFT 8.0
#define ARROW_MARGIN_RIGHT 8.0
#define ARROW_MARGIN_TOP 6.0
#define ARROW_MARGIN_BOTTOM 6.0
    
    CGSize offset = CGSizeMake(0.0, 0.0);
    NSEdgeInsets insets = NSEdgeInsetsMake(ARROW_MARGIN_TOP, ARROW_MARGIN_LEFT, ARROW_MARGIN_BOTTOM, ARROW_MARGIN_RIGHT);
    EDDrawFolder(ctx, frame, insets, offset, grad, strokeColor, shadow);
}


static void EDDrawFolder(CGContextRef ctx, CGRect frame, NSEdgeInsets insets, CGSize offset, CGGradientRef grad, NSColor *strokeColor, NSShadow *shadow) {

#define TAB_WIDTH_RATIO 0.5
#define TAB_HEIGHT_RATIO 0.1

#define GAP_MARGIN_X 2.0
#define GAP_MARGIN_Y 2.0

    CGRect iconRect = CGRectMake(frame.origin.x + insets.left,
                                 frame.origin.y + insets.top,
                                 round(CGRectGetWidth(frame) - (insets.left + insets.right)),
                                 round(CGRectGetHeight(frame) - (insets.top + insets.bottom)));
    iconRect.origin = TDDeviceFloorAlign(ctx, iconRect.origin);
    
    
    CGRect tabRect = CGRectMake(CGRectGetMinX(iconRect),
                                CGRectGetMinY(iconRect),
                                round(iconRect.size.width * TAB_WIDTH_RATIO),
                                round(iconRect.size.height * TAB_HEIGHT_RATIO));
    
    CGRect gapRect = tabRect;
    gapRect.size.width += GAP_MARGIN_X;
    gapRect.size.height += GAP_MARGIN_Y;
    gapRect.origin = TDDeviceFloorAlign(ctx, gapRect.origin);

    // create path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(iconRect), CGRectGetMaxY(iconRect));
    CGPathAddLineToPoint(path, NULL, CGRectGetMinX(iconRect), CGRectGetMaxY(gapRect));
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(gapRect), CGRectGetMaxY(gapRect));
    CGFloat topY = CGRectGetMinY(iconRect) + gapRect.size.height/2.0;
    CGPoint topLef = TDDeviceFloorAlign(ctx, CGPointMake(CGRectGetMaxX(gapRect), topY));
    CGPathAddLineToPoint(path, NULL, topLef.x, topLef.y);
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(iconRect), topLef.y);
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(iconRect), CGRectGetMaxY(iconRect));
    CGPathCloseSubpath(path);
    
    // fill folder
    CGContextSaveGState(ctx);
    CGContextAddPath(ctx, path);
    CGContextClip(ctx);
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(CGRectGetMinX(iconRect), CGRectGetMaxY(iconRect)), iconRect.origin, 0);
    CGContextRestoreGState(ctx);

    // fill tab
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, tabRect);
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(CGRectGetMinX(iconRect), CGRectGetMaxY(iconRect)), iconRect.origin, 0);
    CGContextRestoreGState(ctx);

    // stroke folder/tab
    [strokeColor setStroke];
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    CGContextStrokeRect(ctx, tabRect);
    
    CGPathRelease(path);
}

@end
