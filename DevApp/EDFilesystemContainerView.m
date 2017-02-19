//
//  EDFilesystemContainerView.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFilesystemContainerView.h"
#import "EDStatusBar.h"

//#define NAVBAR_HEIGHT 24.0
#define NAVBAR_HEIGHT 0.0
#define OUTLINE_UGLY_FUDGE_Y 0.0

@implementation EDFilesystemContainerView

+ (void)initialize {
    if ([EDFilesystemContainerView class] == self) {
        
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
    
//    self.navBar = nil;
    self.scrollView = nil;
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
//    NSRectFill([self scrollViewRectForBounds:bounds]);
//
//    [[NSColor blueColor] setFill];
//    NSRectFill([self statusBarRectForBounds:bounds]);
//}


- (void)layoutSubviews {
    EDAssertMainThread();
//    EDAssert(_navBar);
    EDAssert(_scrollView);
    EDAssert(_statusBar);
    
    CGRect bounds = [self bounds];
    
//    _navBar.frame = [self navBarRectForBounds:bounds];
    _scrollView.frame = [self scrollViewRectForBounds:bounds];
    _statusBar.frame =  [self statusBarRectForBounds:bounds];
    
    [self setNeedsDisplay:YES];
}


//- (CGRect)navBarRectForBounds:(CGRect)bounds {
//    CGFloat x = 0.0;
//    CGFloat y = 0.0;
//    CGFloat w = bounds.size.width;
//    CGFloat h = NAVBAR_HEIGHT;
//
//    CGRect r = CGRectMake(x, y, w, h);
//    return r;
//}


- (CGRect)scrollViewRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = NAVBAR_HEIGHT - OUTLINE_UGLY_FUDGE_Y;
    CGFloat w = bounds.size.width;
    CGFloat h = bounds.size.height - (y + [self statusBarHeight]);
    
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
    return [[EDUserDefaults instance] statusBarVisible] ? [EDStatusBar defaultHeight] : 0.0;
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
