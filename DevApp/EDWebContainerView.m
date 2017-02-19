//
//  EDWebContainerView.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDWebContainerView.h"
#import "EDStatusBar.h"
#import "EDFindPanel.h"

#define COMBO_MARGIN_RIGHT 12.0

@implementation EDWebContainerView

//+ (void)initialize {
//    if ([EDWebContainerView class] == self) {
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
    
    self.browserView = nil;
    self.findPanel = nil;
    self.statusBar = nil;
    self.comboField = nil;
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
//    NSRectFill([self browserViewRectForBounds:bounds]);
//
//    [[NSColor blueColor] setFill];
//    NSRectFill([self statusBarRectForBounds:bounds]);
//}


- (void)layoutSubviews {
    EDAssertMainThread();
    EDAssert(_browserView);
    EDAssert(_findPanel);
    EDAssert(_statusBar);
    EDAssert(_comboField);
    
    CGRect bounds = [self bounds];
    
    _browserView.frame = [self browserViewRectForBounds:bounds];
    _findPanel.frame = [self findPanelRectForBounds:bounds];
    _statusBar.frame =  [self statusBarRectForBounds:bounds];
    _comboField.frame =  [self comboFieldRectForBounds:bounds];
    
    [self setNeedsDisplay:YES];
}


- (CGRect)comboFieldRectForBounds:(CGRect)bounds {
    CGRect r = [_comboField frame];
    r.size.width = fabs(NSMaxX(bounds) - (NSMinX(r) + COMBO_MARGIN_RIGHT));
    return r;
}


- (CGRect)browserViewRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat w = fabs(bounds.size.width);
    CGFloat h = bounds.size.height - (y + [self statusBarHeight] + [self findPanelHeight]);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)findPanelRectForBounds:(CGRect)bounds {
    CGRect statusRect = [self statusBarRectForBounds:bounds];
    
    CGFloat h = [self findPanelHeight];
    
    CGFloat x = 0.0;
    CGFloat y = CGRectGetMaxY(bounds) - (statusRect.size.height + h);
    CGFloat w = bounds.size.width;
    
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


- (CGFloat)findPanelHeight {
    return _findPanelVisible ? [EDFindPanel defaultHeight] : 0.0;
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
