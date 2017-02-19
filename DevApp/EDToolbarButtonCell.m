//
//  EDToolbarButtonCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/30/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDToolbarButtonCell.h"
#import "EDUtils.h"
#import <TDAppKit/TDUtils.h>

#define TAG_RUN 2020
#define TAG_STOP 2030
#define TAG_BREAK 2040
#define TAG_REPL 2045
#define TAG_REF 2050

static CGGradientRef sIconGrad = nil;
static CGGradientRef sHiIconGrad = nil;
static CGGradientRef sNonMainIconGrad = nil;

static CGGradientRef sBookIconGrad = nil;
static CGGradientRef sNonMainBookIconGrad = nil;

static NSColor *sIconStroke = nil;
static NSColor *sHiIconStroke = nil;
static NSColor *sNonMainIconStroke = nil;

static NSShadow *sHiIconShadow = nil;

@implementation EDToolbarButtonCell

+ (void)initialize {
    if ([EDToolbarButtonCell class] == self) {

        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        const CGFloat locs[2] = {0.0, 1.0};
        
        NSArray *colors = nil;
        
        colors = @[TDCGHexColor(0x666666), TDCGHexColor(0x888888)];
        sIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexColor(0xefefef), TDCGHexColor(0xffffff)];
        sHiIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexColor(0x999999), TDCGHexColor(0xbbbbbb)];
        sNonMainIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexColor(0xaaaaaa), TDCGHexColor(0x777777)];
        sBookIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        colors = @[TDCGHexColor(0xdddddd), TDCGHexColor(0xaaaaaa)];
        sNonMainBookIconGrad = CGGradientCreateWithColors(cs, (CFArrayRef)colors, locs);
        
        CGColorSpaceRelease(cs);

        sIconStroke = [TDHexColor(0x555555) retain];
        sHiIconStroke = [TDHexColor(0xffffff) retain];
        sNonMainIconStroke = [TDHexColor(0x9f9f9f) retain];
        
        sHiIconShadow = [[NSShadow alloc] init];
        [sHiIconShadow setShadowBlurRadius:2.0];
        [sHiIconShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        [sHiIconShadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.6]];
    }
}

//- (void)drawRect:(NSRect)dirtyRect {
//
//}


void EDDrawReference(CGContextRef ctx, CGRect frame, NSEdgeInsets insets, CGSize offset, CGGradientRef grad, NSColor *strokeColor, NSShadow *shadow) {
//    frame.origin = TDDeviceFloorAlign(ctx, frame.origin);

    frame.origin.x = TDRoundAlign(frame.origin.x);
    frame.origin.y = TDRoundAlign(frame.origin.y);

    CGRect bookRect = CGRectMake(TDNoop(frame.origin.x + insets.left),
                                 TDNoop(frame.origin.y + insets.top),
                                 round(CGRectGetWidth(frame) - (insets.left + insets.right)),
                                 round(CGRectGetHeight(frame) - (insets.top + insets.bottom)));
    
    bookRect.origin.x += offset.width;
    bookRect.origin.y += offset.height;
    
    CGPoint topMid = CGPointMake(NSMidX(bookRect), NSMinY(bookRect));
    CGPoint botMid = CGPointMake(NSMidX(bookRect), NSMaxY(bookRect));

    CGPoint topLef = CGPointMake(NSMinX(bookRect), NSMinY(bookRect));
    CGPoint botLef = CGPointMake(NSMinX(bookRect), NSMaxY(bookRect));
    
    CGPoint topRit = CGPointMake(NSMaxX(bookRect), NSMinY(bookRect));
    CGPoint botRit = CGPointMake(NSMaxX(bookRect), NSMaxY(bookRect));
    
    CGFloat ctrlw = bookRect.size.width / 6.0;
    CGFloat ctrlh = bookRect.size.height / 4.0;
    
//    CGPoint topLef1 = TDDeviceFloorAlign(ctx, CGPointMake(topMid.x - ctrlw, topMid.y - ctrlh));
//    CGPoint topLef2 = TDDeviceFloorAlign(ctx, CGPointMake(topLef.x + ctrlw, topLef.y - ctrlh));
//    CGPoint botLef1 = TDDeviceFloorAlign(ctx, CGPointMake(botLef.x + ctrlw, botLef.y - ctrlh));
//    CGPoint botLef2 = TDDeviceFloorAlign(ctx, CGPointMake(botMid.x - ctrlw, botMid.y - ctrlh));
//    
//    CGPoint topRit1 = TDDeviceFloorAlign(ctx, CGPointMake(topRit.x - ctrlw, topRit.y - ctrlh));
//    CGPoint topRit2 = TDDeviceFloorAlign(ctx, CGPointMake(topMid.x + ctrlw, topMid.y - ctrlh));
//    CGPoint botRit1 = TDDeviceFloorAlign(ctx, CGPointMake(botMid.x + ctrlw, botMid.y - ctrlh));
//    CGPoint botRit2 = TDDeviceFloorAlign(ctx, CGPointMake(botRit.x - ctrlw, botRit.y - ctrlh));
    
    CGPoint topLef1 = CGPointMake(TDNoop(topMid.x - ctrlw), TDNoop(topMid.y - ctrlh));
    CGPoint topLef2 = CGPointMake(TDNoop(topLef.x + ctrlw), TDNoop(topLef.y - ctrlh));
    CGPoint botLef1 = CGPointMake(TDNoop(botLef.x + ctrlw), TDNoop(botLef.y - ctrlh));
    CGPoint botLef2 = CGPointMake(TDNoop(botMid.x - ctrlw), TDNoop(botMid.y - ctrlh));
    
    CGPoint topRit1 = CGPointMake(TDNoop(topRit.x - ctrlw), TDNoop(topRit.y - ctrlh));
    CGPoint topRit2 = CGPointMake(TDNoop(topMid.x + ctrlw), TDNoop(topMid.y - ctrlh));
    CGPoint botRit1 = CGPointMake(TDNoop(botMid.x + ctrlw), TDNoop(botMid.y - ctrlh));
    CGPoint botRit2 = CGPointMake(TDNoop(botRit.x - ctrlw), TDNoop(botRit.y - ctrlh));
    
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    // do book icon
    
    // begin
    CGMutablePathRef path = CGPathCreateMutable();
    
    // left side
    CGPathMoveToPoint(path, NULL, topMid.x, topMid.y);
    CGPathAddCurveToPoint(path, NULL, topLef1.x, topLef1.y, topLef2.x, topLef2.y, topLef.x, topLef.y);
    //CGPathAddLineToPoint(path, NULL, topLef.x, topLef.y);
    CGPathAddLineToPoint(path, NULL, botLef.x, botLef.y);
    CGPathAddCurveToPoint(path, NULL, botLef1.x, botLef1.y, botLef2.x, botLef2.y, botMid.x, botMid.y);
    //CGPathAddLineToPoint(path, NULL, botMid.x, botMid.y);

    // right side
    CGPathAddCurveToPoint(path, NULL, botRit1.x, botRit1.y, botRit2.x, botRit2.y, botRit.x, botRit.y);
    //CGPathAddLineToPoint(path, NULL, botRit.x, botRit.y);
    CGPathAddLineToPoint(path, NULL, topRit.x, topRit.y);
    CGPathAddCurveToPoint(path, NULL, topRit1.x, topRit1.y, topRit2.x, topRit2.y, topMid.x, topMid.y);
    //CGPathAddLineToPoint(path, NULL, topMid.x, topMid.y);

    // end
    CGPathCloseSubpath(path);
    
    CGContextSaveGState(ctx);
    [shadow set];
    CGContextAddPath(ctx, path);
    CGContextClip(ctx);
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(topLef.x, topLef.y - ctrlh), botLef, 0);
    CGContextRestoreGState(ctx);
    
    [strokeColor setStroke];
    
    CGContextSaveGState(ctx);
    
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);

    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, topMid.x, topMid.y);
    CGContextAddLineToPoint(ctx, botMid.x, botMid.y);
    CGContextStrokePath(ctx);
    
    CGContextRestoreGState(ctx);
    
    CGPathRelease(path);
}


void EDDrawREPL(CGContextRef ctx, CGRect frame, NSEdgeInsets insets, CGSize offset, CGGradientRef grad, NSColor *strokeColor, NSShadow *shadow) {
#define ARROW_WIDTH 5.0
#define STEM 2.0
    
    frame.origin = TDDeviceFloorAlign(ctx, frame.origin);
    CGRect arrowRect = CGRectMake(TDNoop(frame.origin.x + insets.left),
                                  TDNoop(frame.origin.y + insets.top),
                                  round(CGRectGetWidth(frame) - (insets.left + insets.right)),
                                  round(CGRectGetHeight(frame) - (insets.top + insets.bottom)));
    
    arrowRect.origin.x += offset.width;
    arrowRect.origin.y += offset.height;
    
    CGPoint botLef = CGPointMake(NSMinX(arrowRect), NSMinY(arrowRect));
    CGPoint botMidLef = CGPointMake(NSMinX(arrowRect), NSMinY(arrowRect) + STEM);
    
    CGPoint topLef = CGPointMake(NSMinX(arrowRect), NSMaxY(arrowRect));
    CGPoint topMidLef = CGPointMake(NSMinX(arrowRect), NSMaxY(arrowRect) - STEM);
    
    CGPoint midLef = CGPointMake(NSMinX(arrowRect) + ARROW_WIDTH - STEM, NSMidY(arrowRect));
    CGPoint midRit = CGPointMake(NSMinX(arrowRect) + ARROW_WIDTH, NSMidY(arrowRect));
    
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    for (NSUInteger i = 0; i < 3; ++i) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, botLef.x, botLef.y);
        CGPathAddLineToPoint(path, NULL, botMidLef.x, botMidLef.y);
        CGPathAddLineToPoint(path, NULL, midLef.x, midLef.y);
        CGPathAddLineToPoint(path, NULL, topMidLef.x, topMidLef.y);
        CGPathAddLineToPoint(path, NULL, topLef.x, topLef.y);
        CGPathAddLineToPoint(path, NULL, midRit.x, midRit.y);
        CGPathAddLineToPoint(path, NULL, botLef.x, botLef.y);
        CGPathCloseSubpath(path);
        
        CGContextSaveGState(ctx);
        [shadow set];
        CGContextAddPath(ctx, path);
        CGContextClip(ctx);
        CGContextDrawLinearGradient(ctx, grad, topLef, botLef, 0);
        CGContextRestoreGState(ctx);
        
        [strokeColor setStroke];
        
        CGContextSaveGState(ctx);
        CGContextAddPath(ctx, path);
        CGContextStrokePath(ctx);
        CGContextRestoreGState(ctx);
        
        CGPathRelease(path);
        
        CGContextTranslateCTM(ctx, ARROW_WIDTH + 1.0, 0.0);
    }
}


- (void)drawImage:(NSImage *)img withFrame:(NSRect)frame inView:(NSView *)cv {
    NSInteger tag = [cv tag];

    if (TAG_BREAK != tag && TAG_REF != tag && TAG_REPL != tag) {
        if (TAG_RUN == tag) {
            frame.origin.x += 1.0;
        }
        frame.origin.y += 1.0;
        [super drawImage:img withFrame:frame inView:cv];
    } else {
        CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
        
        BOOL isHi = [self isHighlighted] || [self state] == NSOnState;
        BOOL isMain = [[cv window] isMainWindow];
        CGGradientRef grad = nil;
        NSColor *strokeColor = nil;
        NSShadow *shadow = nil;
        
        if (TAG_BREAK == tag) {
            if (isHi) {
                grad = sHiIconGrad;
                strokeColor = sHiIconStroke;
                shadow = sHiIconShadow;
            } else {
                grad = isMain ? sIconGrad : sNonMainIconGrad;
                strokeColor = isMain ? sIconStroke : sNonMainIconStroke;
            }
            
            CGSize offset = CGSizeMake(0.0, 0.0);
#define ARROW_MARGIN_LEFT 0.0
#define ARROW_MARGIN_RIGHT 0.0
#define ARROW_MARGIN_TOP 3.0
#define ARROW_MARGIN_BOTTOM 3.0
            NSEdgeInsets insets = NSEdgeInsetsMake(ARROW_MARGIN_TOP, ARROW_MARGIN_LEFT, ARROW_MARGIN_BOTTOM, ARROW_MARGIN_RIGHT);
            EDDrawBreakpoint(ctx, frame, insets, offset, grad, strokeColor, shadow);
        } else if (TAG_REF == tag) {
            
            grad = isMain ? sBookIconGrad : sNonMainBookIconGrad;
            strokeColor = isMain ? sIconStroke : sNonMainIconStroke;

            CGSize offset = CGSizeMake(-1.0, 0.5);
#define BOOK_MARGIN_LEFT -2.0
#define BOOK_MARGIN_RIGHT -2.0
#define BOOK_MARGIN_TOP 2.0
#define BOOK_MARGIN_BOTTOM 2.0
            NSEdgeInsets insets = NSEdgeInsetsMake(BOOK_MARGIN_TOP, BOOK_MARGIN_LEFT, BOOK_MARGIN_BOTTOM, BOOK_MARGIN_RIGHT);
            EDDrawReference(ctx, frame, insets, offset, grad, strokeColor, shadow);
        } else {
            EDAssert(TAG_REPL == tag);
            
            grad = isMain ? sIconGrad : sNonMainIconGrad;
            strokeColor = isMain ? sIconStroke : sNonMainIconStroke;
            
            CGSize offset = CGSizeMake(0.0, 0.0);
#define REPL_MARGIN_LEFT -4.0
#define REPL_MARGIN_RIGHT 0.0
#define REPL_MARGIN_TOP 0.0
#define REPL_MARGIN_BOTTOM 0.0
            NSEdgeInsets insets = NSEdgeInsetsMake(REPL_MARGIN_TOP, REPL_MARGIN_LEFT, REPL_MARGIN_BOTTOM, REPL_MARGIN_RIGHT);
            EDDrawREPL(ctx, frame, insets, offset, grad, strokeColor, shadow);
        }
    }
}

@end
