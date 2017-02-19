//
//  EDConsoleContainerView.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDConsoleContainerView.h"
#import "EDConsoleControlBar.h"
//#import "EDStatusBar.h"

@implementation EDConsoleContainerView

+ (void)initialize {
    if ([EDConsoleContainerView class] == self) {
        
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
    
    self.controlBar = nil;
    self.uberView = nil;
//    self.statusBar = nil;
    [super dealloc];
}


//- (void)awakeFromNib {
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc addObserver:self selector:@selector(statusBarVisibleDidChange:) name:EDStatusBarVisibleDidChangeNotification object:nil];
//}


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
//    NSRectFill([self controlBarRectForBounds:bounds]);
//}


- (void)layoutSubviews {
    EDAssertMainThread();
    EDAssert(_controlBar);
//    EDAssert(_uberView);
//    EDAssert(_statusBar);
    
    CGRect bounds = [self bounds];
    
    _controlBar.frame = [self controlBarRectForBounds:bounds];
    _uberView.frame = [self uberViewRectForBounds:bounds];
//    _statusBar.frame = [self statusBarRectForBounds:bounds];
    
    [self setNeedsDisplay:YES];
}


- (CGRect)controlBarRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat w = bounds.size.width;
    CGFloat h = [EDConsoleControlBar defaultHeight];
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)uberViewRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = [EDConsoleControlBar defaultHeight];
    CGFloat w = bounds.size.width;
    CGFloat h = bounds.size.height - [EDConsoleControlBar defaultHeight]; // - [self statusBarHeight];

    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


//- (CGRect)statusBarRectForBounds:(CGRect)bounds {
//    CGFloat h = [self statusBarHeight];
//    
//    CGFloat x = 0.0;
//    CGFloat y = CGRectGetMaxY(bounds) - h;
//    CGFloat w = bounds.size.width;
//    
//    CGRect r = CGRectMake(x, y, w, h);
//    return r;
//}
//
//
//#pragma mark -
//#pragma mark Private
//
//- (CGFloat)statusBarHeight {
//    return [[EDUserDefaults instance] statusBarVisible] ? [EDStatusBar defaultHeight] : 0.0;
//}
//
//
//#pragma mark -
//#pragma mark Notifications
//
//- (void)statusBarVisibleDidChange:(NSNotification *)n {
//    [self setNeedsLayout];
//}

@end
