//
//  FlatStyleExtraButton.m
//  Shapes
//
//  Created by Todd Ditchendorf on 6/15/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "FlatStyleExtraButton.h"
#import "FlatTabStyle.h"
#import <TDAppKit/TDUtils.h>

#define STROKE_LEN 10.0
#define STROKE_WIDTH 2.0

@implementation FlatStyleExtraButton

//static NSGradient *sDormantBgGradient = nil;
//static NSGradient *sNonMainDormantBgGradient = nil;
//
//static NSGradient *sHoverBgGradient = nil;
//static NSGradient *sNonMainHoverBgGradient = nil;
//
//static NSGradient *sActiveBgGradient = nil;
//
//static NSColor *sStrokeColor = nil;
//static NSColor *sNonMainStrokeColor = nil;
//
//static NSColor *sIconColor = nil;
//static NSColor *sActiveIconColor = nil;
//static NSColor *sNonMainIconColor = nil;

+ (void)initialize {
    if ([FlatStyleExtraButton class] == self) {
        // normal fill
//        sDormantBgGradient        = [[NSGradient alloc] initWithStartingColor:TDHexColor(0xdddddd) endingColor:TDHexColor(0xcccccc)];
//        sNonMainDormantBgGradient = [[NSGradient alloc] initWithStartingColor:TDHexColor(0xefefef) endingColor:TDHexColor(0xdfdfdf)];
//
//        sHoverBgGradient          = [[NSGradient alloc] initWithStartingColor:TDHexColor(0xcccccc) endingColor:TDHexColor(0xbbbbbb)];
//        sNonMainHoverBgGradient   = [[NSGradient alloc] initWithStartingColor:TDHexColor(0xcccccc) endingColor:TDHexColor(0xbbbbbb)];
//
//        sActiveBgGradient         = [[NSGradient alloc] initWithStartingColor:TDHexColor(0xcccccc) endingColor:TDHexColor(0xbbbbbb)];
//
//        // normal stroke color
//        sStrokeColor = [TDHexColor(0x777777) retain];
//        sNonMainStrokeColor = [TDHexColor(0x999999) retain];
//
//        // normal stroke color
//        sIconColor = [TDHexColor(0x444444) retain];
//        sActiveIconColor = [TDHexColor(0x222222) retain];
//        sNonMainIconColor = [TDHexColor(0x666666) retain];
    }
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setButtonType:NSMomentaryPushInButton];
        [self setImagePosition:NSImageOnly];
        [self setBordered:NO];
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}


- (BOOL)isSelected {
    return YES;
}


#pragma mark -
#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect {
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    NSRect bounds = [self bounds];
    
    // fill bg gradient
    NSGradient *bgGrad = [FlatTabStyle bgGradientForButton:self];
    NSColor *stroke = [FlatTabStyle strokeColorForButton:self];
    NSColor *iconColor = [FlatTabStyle iconColorForButton:self];
    
    [bgGrad drawInRect:bounds angle:90.0];
    [stroke setStroke];
    
    // TOP STROKE
//    CGFloat y = TDCeilAlign(NSMinY(bounds));
//    CGContextMoveToPoint(ctx, NSMinX(bounds), y);
//    CGContextAddLineToPoint(ctx, NSMaxX(bounds), y);
//    CGContextStrokePath(ctx);

    // LEFT STROKE
    CGFloat x = TDFloorAlign(NSMinX(bounds));
    CGContextMoveToPoint(ctx, x, NSMinY(bounds));
    CGContextAddLineToPoint(ctx, x, NSMaxY(bounds));
    CGContextStrokePath(ctx);
    
    [iconColor set];
    CGContextSetLineWidth(ctx, STROKE_WIDTH);
    
    if (self.isAdd) {
        CGContextMoveToPoint(ctx, ceil(NSMidX(bounds) - STROKE_LEN*0.5), ceil(NSMidY(bounds)));
        CGContextAddLineToPoint(ctx, ceil(NSMidX(bounds) + STROKE_LEN*0.5), ceil(NSMidY(bounds)));
        
        CGContextMoveToPoint(ctx, ceil(NSMidX(bounds)), ceil(NSMidY(bounds) - STROKE_LEN*0.5));
        CGContextAddLineToPoint(ctx, ceil(NSMidX(bounds)), ceil(NSMidY(bounds) + STROKE_LEN*0.5));
        CGContextStrokePath(ctx);
    } else {
        CGSize box = CGSizeMake(12.0, 12.0);
        
        CGContextSaveGState(ctx); {
            CGContextTranslateCTM(ctx, round(NSMidX(bounds) - box.width*0.5), round(NSMidY(bounds) - box.height*0.5));
            CGContextSetLineCap(ctx, kCGLineCapButt);
            CGContextSetLineJoin(ctx, kCGLineJoinMiter);
            
            // Left Arrow
            CGContextSaveGState(ctx); {
                static CGMutablePathRef path = NULL;
                if (!path) {
                    path = CGPathCreateMutable();
                    CGPathMoveToPoint(path, NULL, 0.00, 0.00);
                    CGPathAddLineToPoint(path, NULL, 3.00, 0.00);
                    CGPathAddLineToPoint(path, NULL, 7.00, 6.00);
                    CGPathAddLineToPoint(path, NULL, 3.00, 12.00);
                    CGPathAddLineToPoint(path, NULL, 0.00, 12.00);
                    CGPathAddLineToPoint(path, NULL, 4.00, 6.00);
                    CGPathAddLineToPoint(path, NULL, 0.00, 0.00);
                    CGPathCloseSubpath(path);
                }
                CGContextAddPath(ctx, path);
                CGContextFillPath(ctx);
            } CGContextRestoreGState(ctx);
            
            // Right Arrow
            CGContextSaveGState(ctx); {
                static CGMutablePathRef path = NULL;
                if (!path) {
                    path = CGPathCreateMutable();
                    CGPathMoveToPoint(path, NULL, 5.00, 0.00);
                    CGPathAddLineToPoint(path, NULL, 8.00, 0.00);
                    CGPathAddLineToPoint(path, NULL, 12.00, 6.00);
                    CGPathAddLineToPoint(path, NULL, 8.00, 12.00);
                    CGPathAddLineToPoint(path, NULL, 5.00, 12.00);
                    CGPathAddLineToPoint(path, NULL, 9.00, 6.00);
                    CGPathAddLineToPoint(path, NULL, 5.00, 0.00);
                    CGPathCloseSubpath(path);
                }
                CGContextAddPath(ctx, path);
                CGContextFillPath(ctx);
            } CGContextRestoreGState(ctx);
            
        } CGContextRestoreGState(ctx);
    }
}


- (void)viewDidMoveToWindow {
    NSWindow *win = [self window];
    if (win) {
        [self setNeedsDisplay:YES];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:win];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidResignMainNotification object:win];
    }
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    [self setNeedsDisplay:YES];
}

@end

