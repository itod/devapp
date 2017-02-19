//
//  EXContainerView.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDWindowContainerView.h"
#import "EDMainWindowController.h"
#import <TDAppKit/TDUtils.h>

#define TAB_BORDER_HEIGHT 1.0

static NSColor *sTabsBorderColor = nil;
static NSColor *sNonMainTabsBorderColor = nil;

@implementation EDWindowContainerView

+ (void)initialize {
    if ([EDWindowContainerView class] == self) {
        
        sTabsBorderColor = [TDHexColor(0x7a7a7a) retain];
        sNonMainTabsBorderColor = [TDHexColor(0xaaaaaa) retain];
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
    
    self.tabsListView = nil;
    self.uberView = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(tabsListViewVisibleDidChange:) name:EDTabsListViewVisibleDidChangeNotification object:nil];
}


- (void)drawRect:(NSRect)dirtyRect {
    EDAssert([self isFlipped]);
    CGRect bounds = [self bounds];
    
//    [[NSColor redColor] setFill];
//    NSRectFill([self uberViewRectForBounds:bounds]);
//    
//    [[NSColor blueColor] setFill];
//    NSRectFill([self statusBarRectForBounds:bounds]);
    
    if ([self isTabsListViewVisible]) {
        CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];

        CGRect tabsRect = [self tabsListViewRectForBounds:bounds];
        CGFloat y = TDFloorAlign(NSMaxY(tabsRect));

        CGContextSetLineWidth(ctx, TAB_BORDER_HEIGHT);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, NSMinX(tabsRect), y);
        CGContextAddLineToPoint(ctx, NSMaxX(tabsRect), y);
        
        NSColor *strokeColor = [[self window] isMainWindow] ? sTabsBorderColor : sNonMainTabsBorderColor;
        [strokeColor setStroke];
        CGContextStrokePath(ctx);
    }
}


- (void)layoutSubviews {
    EDAssertMainThread();
    EDAssert(_tabsListView);
    EDAssert(_uberView);
    
    CGRect bounds = [self bounds];
    
    _tabsListView.frame = [self tabsListViewRectForBounds:bounds];
    _uberView.frame = [self uberViewRectForBounds:bounds];
    
    EDMainWindowController *wc = (id)[[self window] windowController];
    [wc.tabsListViewController.listView reloadData];
    
    [self setNeedsDisplay:YES];
}


- (CGRect)tabsListViewRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat w = bounds.size.width;
    CGFloat h = [self currentTabsListViewHeight];
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)uberViewRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = [self totalCurrentTabsListViewHeight];
    CGFloat w = bounds.size.width;
    CGFloat h = bounds.size.height - y;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


#pragma mark -
#pragma mark Private

- (BOOL)isTabsListViewVisible {
    EDMainWindowController *wc = (id)[[self window] windowController];
    NSUInteger tabCount = [wc.tabModels count];
    return tabCount > 1 && [[EDUserDefaults instance] tabsListViewVisible];
}


- (CGFloat)currentTabsListViewHeight {
    return [self isTabsListViewVisible] ? _tabsListViewHeight : 1.0;
}


- (CGFloat)totalCurrentTabsListViewHeight {
    return [self isTabsListViewVisible] ? _tabsListViewHeight + TAB_BORDER_HEIGHT : 1.0;
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


- (void)tabsListViewVisibleDidChange:(NSNotification *)n {
    [self setNeedsLayout];
}

@end
