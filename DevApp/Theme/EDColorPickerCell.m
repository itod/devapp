//
//  EDColorPickerTableCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/27/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDColorPickerCell.h"
#import <TDAppKit/TDUtils.h>
#import "EDUtils.h"

@implementation EDColorPickerCell

//- (void)setButtonType:(NSButtonType)type {
//    [super setButtonType:type];
//}
//
//
//- (NSInteger)highlightsBy {
//    NSInteger i = [super highlightsBy];
//    return i;
//}
//
//
//- (NSInteger)showsStateBy {
//    NSInteger i = [super showsStateBy];
//    return i;
//}


- (NSSize)cellSizeForBounds:(NSRect)bounds {
    return bounds.size;
}


- (NSRect)drawingRectForBounds:(NSRect)bounds {
    return bounds;
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)cv {
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    BOOL isOn = NSOnState == [self state];
    BOOL isHi = [self isHighlighted];
//    if (isOn) {
//        NSLog(@"isOn %d, isHi %d", isOn, isHi);
//    }
    
    CGRect r = [self borderRectForCellFrame:cellFrame];

    // fill
    NSColor *fillColor = [self objectValue];
    EDAssert(!fillColor || [fillColor isKindOfClass:[NSColor class]]);
    
    // stroke
    EDAssert([cv isKindOfClass:[NSTableView class]]);
    NSColor *strokeColor = [(NSTableView *)cv gridColor];
    
    EDDrawColorCell(ctx, r, fillColor, strokeColor, isOn, isHi);
}


- (CGRect)borderRectForCellFrame:(CGRect)cellFrame {
    CGFloat x = TDFloorAlign(cellFrame.origin.x) - 1.0;
    CGFloat y = TDFloorAlign(cellFrame.origin.y);
    CGFloat w = floor(cellFrame.size.width);
    CGFloat h = floor(cellFrame.size.height);

    CGRect r = CGRectMake(x, y, w, h);
    return r;
}

@end
