//
//  EDMidContainerView.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/25/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDMidContainerView.h"
#import "StatusBar.h"
#import "EDMidControlBar.h"

@implementation EDMidContainerView

//+ (void)initialize {
//    if ([EDMidContainerView class] == self) {
//
//    }
//}


//- (id)initWithFrame:(NSRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//
//    }
//
//    return self;
//}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
        
    self.controlBar = nil;
    self.uberView = nil;
    self.statusBar = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(statusBarVisibleDidChange:) name:EDStatusBarVisibleDidChangeNotification object:nil];
}


#pragma mark -
#pragma mark NSView

- (BOOL)isFlipped {
    return YES;
}


//- (void)drawRect:(NSRect)dirtyRect {
//    EDAssert([self isFlipped]);
//    CGRect bounds = [self bounds];
//    //CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
//
//    [[NSColor redColor] setFill];
//    NSRectFill([self uberViewRectForBounds:bounds]);
//
//    [[NSColor blueColor] setFill];
//    NSRectFill([self statusBarRectForBounds:bounds]);
//}


- (void)layoutSubviews {
    EDAssertMainThread();

    EDAssert(_controlBar);
    EDAssert(_uberView);
    EDAssert(_statusBar);
    
    CGRect bounds = [self bounds];
    
    _controlBar.frame = [self controlBarRectForBounds:bounds];
    _uberView.frame = [self uberViewRectForBounds:bounds];
    _statusBar.frame =  [self statusBarRectForBounds:bounds];
    
    [self setNeedsDisplay:YES];
}


- (CGRect)controlBarRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat w = bounds.size.width;
    CGFloat h = [EDMidControlBar defaultHeight];
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)uberViewRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = [EDMidControlBar defaultHeight];
    CGFloat w = bounds.size.width;
    CGFloat h = bounds.size.height - ([EDMidControlBar defaultHeight] + [self statusBarHeight]);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)statusBarRectForBounds:(CGRect)bounds {
    CGFloat h = [self statusBarHeight];
    
    CGFloat x = 0.0;
    CGFloat y = CGRectGetMaxY(bounds) - h;
    CGFloat w = bounds.size.width;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


#pragma mark -
#pragma mark Private

- (CGFloat)statusBarHeight {
    return [[EDUserDefaults instance] statusBarVisible] ? [StatusBar defaultHeight] : 0.0;
}


#pragma mark -
#pragma mark Notifications

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    NSWindow *win = [self window];
    if (win) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:win];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidResignMainNotification object:win];
    }
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    if ([self window]) {
        [self setNeedsDisplay:YES];
    }
}


- (void)statusBarVisibleDidChange:(NSNotification *)n {
    [self setNeedsLayout];
}

@end
