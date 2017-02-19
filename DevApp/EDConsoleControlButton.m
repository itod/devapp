//
//  EDConsoleControlButton.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDConsoleControlButton.h"
#import "EDConsoleControlButtonCell.h"

@implementation EDConsoleControlButton

+ (Class)cellClass {
    return [EDConsoleControlButtonCell class];
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
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

@end
