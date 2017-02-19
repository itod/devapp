//
//  EDFilesystemOutlineView.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/29/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDNavigatorOutlineView.h"
#import <TDAppKit/TDUtils.h>

static NSGradient *sHiMainGradient = nil;
static NSGradient *sMainGradient = nil;
static NSGradient *sNonMainGradient = nil;

static NSColor *sHiMainColor = nil;
static NSColor *sMainColor = nil;
static NSColor *sNonMainColor = nil;

@interface NSObject (Compiler)
- (void)displayContextMenu:(NSEvent *)evt;
@end

@implementation EDNavigatorOutlineView

+ (void)initialize {
    if ([EDNavigatorOutlineView class] == self) {
        sHiMainGradient = [TDVertGradient(0x9BB4CE, 0x708AB4) retain];
        sMainGradient = [TDVertGradient(0xAFBED8, 0x8296B9) retain];
        sNonMainGradient = [TDVertGradient(0xC2C2C2, 0x9C9C9C) retain];
        
        sHiMainColor = [TDHexColor(0x94AEC3) retain];
        sMainColor = [TDHexColor(0xA2AFCC) retain];
        sNonMainColor = [TDHexColor(0xA8A8A8) retain];
    }
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    
    return self;
}


- (void)dealloc {
    [self killTimer];
    [super dealloc];
}


- (void)editColumn:(NSInteger)column row:(NSInteger)row withEvent:(NSEvent *)evt select:(BOOL)select {
    [super editColumn:column row:row withEvent:evt select:select];
}


- (BOOL)autosaveExpandedItems {
    return YES;
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
    NSGradient *gradient = nil;
    NSColor *strokeColor = nil;
    
    // if the view is focused, use highlight color, otherwise use the out-of-focus highlight color
    if ([[self window] isKeyWindow]) {
        if (self == [[self window] firstResponder]) {
            gradient = sHiMainGradient;
            strokeColor = sHiMainColor;
        } else {
            gradient = sMainGradient;
            strokeColor = sMainColor;
        }
    } else {
        gradient = sNonMainGradient;
        strokeColor = sNonMainColor;
    }
    
    // draw highlight for the visible, selected rows
    for ( ; row < lastVisRow; row++) {
        
        if ([selRowIndexes containsIndex:row]) {

            NSRect rowRect = NSInsetRect([self rectOfRow:row], 0.0, 0.0);

            [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:rowRect] angle:90.0];

            [strokeColor setStroke];
            [NSBezierPath setDefaultLineWidth:1.0];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(floor(NSMinX(rowRect)), TDFloorAlign(NSMinY(rowRect))) toPoint:NSMakePoint(ceil(NSMaxX(rowRect)), TDFloorAlign(NSMinY(rowRect)))];
        }
    }
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

@end
