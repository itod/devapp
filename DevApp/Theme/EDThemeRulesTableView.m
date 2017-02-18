//
//  EDThemeRulesTableView.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/27/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDThemeRulesTableView.h"
#import <TDAppKit/TDUtils.h>

@implementation EDThemeRulesTableView

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    // this method is asking us to draw the hightlights for
    // all of the selected rows that are visible inside theClipRect
    
    // 1. get the range of row indexes that are currently visible
    // 2. get a list of selected rows
    // 3. iterate over the visible rows and if their index is selected
    // 4. draw our custom highlight in the rect of that row.
    
    [[self gridColor] setStroke];
    [NSBezierPath setDefaultLineWidth:1.0];

    NSIndexSet *selRowIndexes = [self selectedRowIndexes];

    NSRange visRowRange = [self rowsInRect:clipRect];
    NSInteger lastVisRow = NSMaxRange(visRowRange);
    
    // draw highlight for the visible, selected rows
    for (NSInteger row = visRowRange.location; row < lastVisRow; row++) {
        
        if ([selRowIndexes containsIndex:row]) {
            NSRect rowRect = NSInsetRect([self rectOfRow:row], 0.0, 0.0);
            [NSBezierPath strokeLineFromPoint:NSMakePoint(floor(NSMinX(rowRect)), TDFloorAlign(NSMinY(rowRect))) toPoint:NSMakePoint(ceil(NSMaxX(rowRect)), TDFloorAlign(NSMinY(rowRect)))];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(floor(NSMinX(rowRect)), TDCeilAlign(NSMaxY(rowRect))-1.0) toPoint:NSMakePoint(ceil(NSMaxX(rowRect)), TDCeilAlign(NSMaxY(rowRect))-1.0)];
        }
    }
}

@end
