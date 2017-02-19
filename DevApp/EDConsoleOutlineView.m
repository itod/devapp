//
//  EDConsoleOutlineView.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/29/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDConsoleOutlineView.h"
#import <TDAppKit/TDUtils.h>

@interface NSObject (Compiler)
- (void)displayContextMenu:(NSEvent *)evt;
@end

@implementation EDConsoleOutlineView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    
    return self;
}


- (void)dealloc {
    self.selectionColor = nil;
    [self killTimer];
    [super dealloc];
}


#pragma mark -
#pragma mark Right Click

- (void)killTimer {
    if (_timer) {
        [_timer invalidate];
        self.timer = nil;
    }
}


- (void)displayContextMenu:(NSTimer *)t {
    NSEvent *evt = [_timer userInfo];
    [[self delegate] performSelector:@selector(displayContextMenu:) withObject:evt];
    [self killTimer];
}


- (void)rightMouseDown:(NSEvent *)evt {
    NSInteger row = [self rowAtPoint:[self convertPoint:[evt locationInWindow] fromView:nil]];
    if (-1 == row) {
        [self deselectAll:nil];
    }

    self.timer = [NSTimer timerWithTimeInterval:0.0
                                         target:self
                                       selector:@selector(displayContextMenu:)
                                       userInfo:evt
                                        repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}


- (void)editColumn:(NSInteger)column row:(NSInteger)row withEvent:(NSEvent *)evt select:(BOOL)select {
    [super editColumn:column row:row withEvent:evt select:select];
}


- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    // this method is asking us to draw the hightlights for
    // all of the selected rows that are visible inside theClipRect
    
    // 1. get the range of row indexes that are currently visible
    // 2. get a list of selected rows
    // 3. iterate over the visible rows and if their index is selected
    // 4. draw our custom highlight in the rect of that row.
    
    NSRange visRowRange = [self rowsInRect:clipRect];
    NSIndexSet *selRowIndexes = [self selectedRowIndexes];
    NSInteger row = visRowRange.location;
    NSInteger lastVisRow = NSMaxRange(visRowRange);
    NSColor *color = nil;
    
    // if the view is focused, use highlight color, otherwise use the out-of-focus highlight color
    if ([[self window] isKeyWindow]) {
        color = _selectionColor;
    } else {
        color = [_selectionColor colorWithAlphaComponent:0.7];
    }
    
    EDAssert(color);
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    // draw highlight for the visible, selected rows
    for ( ; row < lastVisRow; row++) {
        
        if ([selRowIndexes containsIndex:row]) {
            
            NSRect rowRect = NSInsetRect([self rectOfRow:row], 0.0, 0.0);
            
            [color setFill];
            CGContextFillRect(ctx, rowRect);
        }
    }
}

@end
