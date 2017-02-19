//
//  EDTabBarBreakpointButtonCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/5/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDTabBarBreakpointButtonCell.h"
#import "EDUtils.h"
#import <TDAppKit/TDUtils.h>

@implementation EDTabBarBreakpointButtonCell

//+ (void)initialize {
//    if ([EDTabBarBreakpointButtonCell class] == self) {
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
    
#define ARROW_MARGIN_LEFT 7.0
#define ARROW_MARGIN_RIGHT 7.0
#define ARROW_MARGIN_TOP 7.0
#define ARROW_MARGIN_BOTTOM 7.0

    CGSize offset = CGSizeMake(0.0, 0.0);
    NSEdgeInsets insets = NSEdgeInsetsMake(ARROW_MARGIN_TOP, ARROW_MARGIN_LEFT, ARROW_MARGIN_BOTTOM, ARROW_MARGIN_RIGHT);
    EDDrawBreakpoint(ctx, frame, insets, offset, grad, strokeColor, shadow);
}

@end
