//
//  EDConsoleControlButtonCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDConsoleControlButtonCell.h"
//#import "EDShellViewController.h"
#import <TDAppKit/TDUtils.h>

#define TAG_TOGGLE_VARS 100

static NSGradient *sHiBgGradient = nil;

static CGGradientRef sIconGrad = nil;
static CGGradientRef sHiIconGrad = nil;
static CGGradientRef sNonMainIconGrad = nil;

static NSColor *sIconStroke = nil;
static NSColor *sHiIconStroke = nil;
static NSColor *sNonMainIconStroke = nil;

@implementation EDConsoleControlButtonCell

+ (void)initialize {
    if ([EDConsoleControlButtonCell class] == self) {
        sHiBgGradient = [TDVertGradient(0xdddddd, 0xbbbbbb) retain];

        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        const CGFloat locs[2] = {0.0, 1.0};
        
        NSArray *colors = nil;
        
        colors = @[TDCGHexColor(0x333333), TDCGHexColor(0x666666)];
        sIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexColor(0x000000), TDCGHexColor(0x333333)];
        sHiIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexColor(0x666666), TDCGHexColor(0x999999)];
        sNonMainIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        CGColorSpaceRelease(cs);
        
        sIconStroke = [TDHexColor(0x444444) retain];
        sHiIconStroke = [TDHexColor(0x222222) retain];
        sNonMainIconStroke = [TDHexColor(0x999999) retain];
    }
}


- (CGFloat)imageAlphaInView:(NSControl *)cv {
    BOOL isMain = [[cv window] isMainWindow];
    BOOL isHi = [self isHighlighted];
    BOOL isDisabled = ![cv isEnabled];

    CGFloat alpha = 0.6; // non main
    if (isHi) {
        alpha = 1.0;
    } else if (isDisabled) {
        alpha = 0.5;
    } else if (isMain) {
        alpha = 0.85;
    }
    return alpha;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(id)cv {
    BOOL isHi = [self isHighlighted];
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    BOOL isVars = TAG_TOGGLE_VARS == [self tag];
    
    if (isHi) {
        [sHiBgGradient drawInRect:cellFrame angle:90.0];

        CGContextSaveGState(ctx);
        [TDHexColor(0xaaaaaa) setStroke];
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, TDCeilAlign(NSMinX(cellFrame)), TDNoop(NSMinY(cellFrame)));
        CGContextAddLineToPoint(ctx, TDCeilAlign(NSMinX(cellFrame)), TDNoop(NSMaxY(cellFrame)));
        CGContextStrokePath(ctx);

        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, TDCeilAlign(NSMaxX(cellFrame) - 1.0), TDNoop(NSMinY(cellFrame)));
        CGContextAddLineToPoint(ctx, TDCeilAlign(NSMaxX(cellFrame) - 1.0), TDNoop(NSMaxY(cellFrame)));
        CGContextStrokePath(ctx);
        CGContextRestoreGState(ctx);
    }
    
    CGRect imgRect = [self imageRectForBounds:cellFrame];

    if (isVars) {
        BOOL isHi = [self isHighlighted];
        BOOL isMain = [[cv window] isMainWindow];

        CGGradientRef grad = nil;
        NSColor *strokeColor = nil;
        
        if (isHi) {
            grad = isMain ? sHiIconGrad : sNonMainIconGrad;
            strokeColor = isMain ? sHiIconStroke : sNonMainIconStroke;
        } else {
            grad = isMain ? sIconGrad : sNonMainIconGrad;
            strokeColor = isMain ? sIconStroke : sNonMainIconStroke;
        }

        CGPoint p1, p2, p3;
        
        CGRect borderRect = [self borderRectForBounds:imgRect];
        CGRect arrowRect = [self arrowRectForBorderRect:borderRect];
        
        [strokeColor setStroke];
        CGContextStrokeRect(ctx, borderRect);
        
        if ([[EDUserDefaults instance] debugLocalVariablesVisible]) {
            p1 = CGPointMake(TDFloorAlign(CGRectGetMaxX(arrowRect)), TDFloorAlign(CGRectGetMinY(arrowRect)));
            p2 = CGPointMake(TDFloorAlign(CGRectGetMaxX(arrowRect)), TDFloorAlign(CGRectGetMaxY(arrowRect)));
            p3 = CGPointMake(TDFloorAlign(CGRectGetMinX(arrowRect)), TDFloorAlign(CGRectGetMidY(arrowRect)));
        } else {
            p1 = CGPointMake(TDFloorAlign(CGRectGetMinX(arrowRect)), TDFloorAlign(CGRectGetMinY(arrowRect)));
            p2 = CGPointMake(TDFloorAlign(CGRectGetMinX(arrowRect)), TDFloorAlign(CGRectGetMaxY(arrowRect)));
            p3 = CGPointMake(TDFloorAlign(CGRectGetMaxX(arrowRect)), TDFloorAlign(CGRectGetMidY(arrowRect)));
        }

        CGContextMoveToPoint(ctx, p1.x, p1.y);
        CGContextAddLineToPoint(ctx, p2.x, p2.y);
        CGContextAddLineToPoint(ctx, p3.x, p3.y);
        CGContextClosePath(ctx);
        
        CGContextClip(ctx);
        
        CGContextDrawLinearGradient(ctx, grad, p1, p2, 0);
        
    } else {
        NSImage *img = [self image];
        
        if (img) {
            CGSize imgSize = [img size];
            CGRect srcRect = CGRectMake(0.0, 0.0, imgSize.width, imgSize.height);
            
            //    destRect.origin.y -= 1.0;
            
            CGFloat alpha = [self imageAlphaInView:cv];
            [img drawInRect:imgRect fromRect:srcRect operation:NSCompositeSourceOver fraction:alpha respectFlipped:YES hints:nil];
        }
    }
}


- (CGRect)borderRectForBounds:(CGRect)bounds {
#define BORDER_MARGIN_X 0.0
#define BORDER_MARGIN_Y 1.0
    bounds = CGRectInset(bounds, BORDER_MARGIN_X, BORDER_MARGIN_Y);
    CGFloat x = TDFloorAlign(bounds.origin.x) + 1.0;
    CGFloat y = TDFloorAlign(bounds.origin.y);
    CGFloat w = round(bounds.size.width);
    CGFloat h = round(bounds.size.height);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)arrowRectForBorderRect:(CGRect)borderRect {
#define ARROW_MARGIN_X 4.0
#define ARROW_MARGIN_Y 2.0
    borderRect = CGRectInset(borderRect, ARROW_MARGIN_X, ARROW_MARGIN_Y);
    CGFloat x = TDFloorAlign(borderRect.origin.x);
    CGFloat y = TDFloorAlign(borderRect.origin.y);
    CGFloat w = round(borderRect.size.width);
    CGFloat h = round(borderRect.size.height);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}

@end
