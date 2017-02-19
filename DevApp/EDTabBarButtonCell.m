//
//  EDTabBarButtonCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/6/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDTabBarButtonCell.h"
#import <TDAppKit/TDUtils.h>

#define OVAL_WIDTH 7.0

static CGGradientRef sHiBgGrad = NULL;
static CGGradientRef sNonMainHiBgGrad = NULL;

static CGGradientRef sHiSideGrad = NULL;
static CGGradientRef sNonMainHiSideGrad = NULL;

static NSColor *sHiStrokeColor = nil;
static NSColor *sNonMainHiStrokeColor = nil;

static CGGradientRef sIconGrad = nil;
static CGGradientRef sHiIconGrad = nil;
static CGGradientRef sNonMainIconGrad = nil;

static NSColor *sIconStroke = nil;
static NSColor *sHiIconStroke = nil;
static NSColor *sNonMainIconStroke = nil;

static NSShadow *sHiIconShadow = nil;

@implementation EDTabBarButtonCell

+ (void)initialize {
    if ([EDTabBarButtonCell class] == self) {

        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        const CGFloat locs[2] = {0.0, 1.0};
        
        NSArray *colors = nil;
        
        colors = @[TDCGHexaColor(0xdddddd7f), TDCGHexaColor(0xbbbbbb7f), TDCGHexaColor(0xdddddd7f)];
        sHiBgGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, NULL);
        
        colors = @[TDCGHexaColor(0xeeeeee7f), TDCGHexaColor(0xcccccc7f), TDCGHexaColor(0xeeeeee7f)];
        sNonMainHiBgGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexaColor(0x5555557f), TDCGHexaColor(0xdddddd7f)];
        sHiSideGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexaColor(0x9999997f), TDCGHexaColor(0xdddddd7f)];
        sNonMainHiSideGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        sHiStrokeColor = [TDHexColor(0x666666) retain];
        sNonMainHiStrokeColor = [TDHexColor(0xaaaaaa) retain];

        colors = @[TDCGHexColor(0x777777), TDCGHexColor(0x999999)];
        sIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexColor(0x666666), TDCGHexColor(0x888888)];
        sHiIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexColor(0xaaaaaa), TDCGHexColor(0xcccccc)];
        sNonMainIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        CGColorSpaceRelease(cs);
        
        sIconStroke = [TDHexColor(0x666666) retain];
        sHiIconStroke = [TDHexColor(0x555555) retain];
        sNonMainIconStroke = [TDHexColor(0x999999) retain];
        
        sHiIconShadow = [[NSShadow alloc] init];
        [sHiIconShadow setShadowBlurRadius:2.0];
        [sHiIconShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        [sHiIconShadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.6]];
    }
}

+ (CGGradientRef)iconGradientForMain:(BOOL)isMain highlighted:(BOOL)isHi {
    CGGradientRef grad = nil;
    
    if (isHi) {
        grad = isMain ? sHiIconGrad : sNonMainIconGrad;
    } else {
        grad = isMain ? sIconGrad : sNonMainIconGrad;
    }
    return grad;
}


+ (NSColor *)iconStrokeColorForMain:(BOOL)isMain highlighted:(BOOL)isHi {
    NSColor *strokeColor = nil;
    
    if (isHi) {
        strokeColor = isMain ? sHiIconStroke : sNonMainIconStroke;
    } else {
        strokeColor = isMain ? sIconStroke : sNonMainIconStroke;
    }
    return strokeColor;
}


+ (NSShadow *)iconShadowForMain:(BOOL)isMain highlighted:(BOOL)isHi {
    NSShadow *shadow = nil;
    
    if (isHi) {
        shadow = sHiIconShadow;
    } else {
    }
    return shadow;
}


- (void)drawBezelWithFrame:(NSRect)frame inView:(NSButton *)cv {
//    BOOL isHi = [self isHighlighted];
    
    BOOL isOn = NSOnState == [self state];
    if (!isOn) return;

    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    BOOL isMain = [[cv window] isMainWindow];

    frame.origin = TDDeviceFloorAlign(ctx, frame.origin);
    
    CGRect lrect = [self leftOvalRectForBounds:frame];
    CGRect rrect = [self rightOvalRectForBounds:frame];
    
    CGPoint lcenter = CGPointMake(CGRectGetMidX(lrect), CGRectGetMidY(lrect));
    CGPoint rcenter = CGPointMake(CGRectGetMidX(rrect), CGRectGetMidY(rrect));
    
    EDAssert(sHiSideGrad);
    EDAssert(sNonMainHiSideGrad);
    EDAssert(sHiStrokeColor);
    EDAssert(sNonMainHiStrokeColor);
    
    NSColor *stroke = isMain ? sHiStrokeColor : sNonMainHiStrokeColor;
    CGGradientRef bgGrad = isMain ? sHiBgGrad : sNonMainHiBgGrad;
    CGGradientRef sideGrad = isMain ? sHiSideGrad : sNonMainHiSideGrad;
    
    // bg
    CGContextDrawLinearGradient(ctx, bgGrad, CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame)), CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame)), 0);
    
    // stroke
    [stroke setStroke];
    CGContextMoveToPoint(ctx, CGRectGetMinX(frame), CGRectGetMinY(frame));
    CGContextAddLineToPoint(ctx, CGRectGetMinX(frame), CGRectGetMaxY(frame));
    CGContextMoveToPoint(ctx, CGRectGetMaxX(frame) - 1.0, CGRectGetMinY(frame));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(frame) - 1.0, CGRectGetMaxY(frame));
    CGContextStrokePath(ctx);
    
    // left gradient
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, lcenter.x, lcenter.y);
    CGContextScaleCTM(ctx, 1.0, CGRectGetHeight(frame) / OVAL_WIDTH);
    CGContextDrawRadialGradient(ctx, sideGrad, CGPointZero, 0.0, CGPointZero, OVAL_WIDTH/2.0, 0);
    CGContextRestoreGState(ctx);

    // right gradient
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, rcenter.x, rcenter.y);
    CGContextScaleCTM(ctx, 1.0, CGRectGetHeight(frame) / OVAL_WIDTH);
    CGContextDrawRadialGradient(ctx, sideGrad, CGPointZero, 0.0, CGPointZero, OVAL_WIDTH/2.0, 0);
    CGContextRestoreGState(ctx);
}


- (CGRect)leftOvalRectForBounds:(CGRect)bounds {
    CGFloat x = CGRectGetMinX(bounds) - OVAL_WIDTH/2.0 - 1.0;
    CGFloat y = CGRectGetMinY(bounds);
    CGFloat w = OVAL_WIDTH;
    CGFloat h = CGRectGetHeight(bounds);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)rightOvalRectForBounds:(CGRect)bounds {
    CGFloat x = CGRectGetMaxX(bounds) - OVAL_WIDTH/2.0;
    CGFloat y = CGRectGetMinY(bounds);
    CGFloat w = OVAL_WIDTH;
    CGFloat h = CGRectGetHeight(bounds);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}

@end
