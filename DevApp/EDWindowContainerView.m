//
//  EXContainerView.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDWindowContainerView.h"
#import "EDMainWindowController.h"
#import "StatusBar.h"
#import <TDAppKit/TDUtils.h>

#define TAB_BORDER_HEIGHT 1.0

@implementation EDWindowContainerView

- (instancetype)initWithFrame:(NSRect)frame {
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

    NSColor *strokeColor = [[self window] isMainWindow] ? [StatusBar mainTopBorderColor] : [StatusBar nonMainTopBorderColor];
    [strokeColor setFill];
    NSRectFill(bounds);

//    [[NSColor redColor] setFill];
//    NSRectFill([self uberViewRectForBounds:bounds]);
//    
//    [[NSColor blueColor] setFill];
//    NSRectFill([self statusBarRectForBounds:bounds]);
    
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
    CGFloat w = 0.0; //bounds.size.width;
    CGFloat h = 0.0; //[self currentTabsListViewHeight];
    
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
    return [self isTabsListViewVisible] ? _tabsListViewHeight : TAB_BORDER_HEIGHT;
}


- (CGFloat)totalCurrentTabsListViewHeight {
    return [self isTabsListViewVisible] ? _tabsListViewHeight + TAB_BORDER_HEIGHT : TAB_BORDER_HEIGHT;
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
