//
//  EDStatusView.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/4/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDToolbarStatusView.h"
#import <TDAppKit/TDUtils.h>

#define STATUS_MARGIN_RIGHT 83.0

#define STROKE_CORNER_RADIUS 5.0

#define TEXT_MARGIN_X 10.0
#define TEXT_MARGIN_Y 7.0

static NSGradient *sBgGrad = nil;
static NSGradient *sNonMainBgGrad = nil;

static NSColor *sStrokeColor = nil;
static NSColor *sNonMainStrokeColor = nil;

static NSShadow *sStrokeShadow = nil;
static NSShadow *sNonMainStrokeShadow = nil;

static NSDictionary *sTextAttrs = nil;
static NSDictionary *sNonMainTextAttrs = nil;

@implementation EDToolbarStatusView

+ (void)initialize {
    if ([EDToolbarStatusView class] == self) {
        sBgGrad = [TDVertGradient(0xEBEFF6, 0xE6E9EF) retain];
        sNonMainBgGrad = [TDVertGradient(0xEEEEEE, 0xEFEFEF) retain];
        
        sStrokeColor = [TDHexColor(0x999999) retain];
        sNonMainStrokeColor = [TDHexColor(0xcccccc) retain];
        
        sStrokeShadow = [[NSShadow alloc] init];
        [sStrokeShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
        [sStrokeShadow setShadowOffset:NSMakeSize(0.0, 0.0)];
        [sStrokeShadow setShadowBlurRadius:2.0];
        
        sNonMainStrokeShadow = [[NSShadow alloc] init];
        [sNonMainStrokeShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.15]];
        [sNonMainStrokeShadow setShadowOffset:NSMakeSize(0.0, 0.0)];
        [sNonMainStrokeShadow setShadowBlurRadius:2.0];
        
        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSLeftTextAlignment];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        
//        NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
//        [textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
//        [textShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
//        [textShadow setShadowBlurRadius:1.0];
        
        sTextAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                      [NSFont controlContentFontOfSize:11.0], NSFontAttributeName,
                      [NSColor darkGrayColor], NSForegroundColorAttributeName,
                      paraStyle, NSParagraphStyleAttributeName,
                      //textShadow, NSShadowAttributeName,
                      nil];

        sNonMainTextAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                      [NSFont controlContentFontOfSize:11.0], NSFontAttributeName,
                      [NSColor grayColor], NSForegroundColorAttributeName,
                      paraStyle, NSParagraphStyleAttributeName,
                      //textShadow, NSShadowAttributeName,
                      nil];
}
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.statusText = nil;
    [super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
    
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGRect bounds = [self bounds];
    
//    [[NSColor redColor] setFill];
//    NSRectFill(bounds);
    
    CGRect statusRect = [self statusRectForBounds:bounds];
    
    BOOL isMain = [[self window] isMainWindow];

    NSGradient *bgGrad = isMain ? sBgGrad : sNonMainBgGrad;
    NSColor *strokeColor = isMain ? sStrokeColor : sNonMainStrokeColor;
    NSShadow *shadow = isMain ? sStrokeShadow : nil;
    EDAssert(bgGrad);
    EDAssert(strokeColor);
    //EDAssert(shadow);

    CGContextSaveGState(ctx);
    
    NSBezierPath *path = TDGetRoundRect(statusRect, STROKE_CORNER_RADIUS, 1.0);
    [path setClip];
    
    [shadow set];
    TDDrawRoundRect(statusRect, STROKE_CORNER_RADIUS, 2.0, bgGrad, strokeColor);

    CGContextRestoreGState(ctx);

    if ([_statusText length]) {
        CGRect textRect = [self statusTextRectForStatusRect:statusRect];
        NSDictionary *attrs = isMain ? sTextAttrs : sNonMainTextAttrs;
        EDAssert(attrs);
        [_statusText drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs];
    }
}


- (CGRect)statusRectForBounds:(CGRect)bounds {
    CGRect r = CGRectInset(bounds, 2.0, 1.0);

//    r.origin.x = TDFloorAlign(r.origin.x);
//    r.origin.y = TDFloorAlign(r.origin.y);
    r.size.width = round(r.size.width) - STATUS_MARGIN_RIGHT;
//    r.size.height = round(r.size.height);
    
    return r;
}


- (CGRect)statusTextRectForStatusRect:(CGRect)statusRect {
    CGFloat x = CGRectGetMinX(statusRect) + TEXT_MARGIN_X;
    CGFloat y = CGRectGetMinY(statusRect) + TEXT_MARGIN_Y;
    CGFloat w = statusRect.size.width - TEXT_MARGIN_X*2.0;
    CGFloat h = statusRect.size.height - TEXT_MARGIN_Y*2.0;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    NSWindow *win = [self window];
    if (win) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:win];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidResignMainNotification object:win];
        
        NSWindowController *wc = [win windowController];
        if (wc) { // this can be nil when fullscreen transitioning
            [self bind:@"statusText" toObject:wc withKeyPath:@"statusText" options:nil];
        } else {
            [self unbind:@"statusText"];
        }
    }
}


- (void)removeFromSuperview {
    [self unbind:@"statusText"];
    [super removeFromSuperview];
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    if ([self window]) {
        [self setNeedsDisplay:YES];
    }
}


- (void)setStatusText:(NSString *)s {
    if (s != _statusText) {
        [_statusText release];
        _statusText = [s copy];
        
        [self setNeedsDisplay:YES];
    }
}

@end
