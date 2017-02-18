//
//  EDColorPickerButtonCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 12/3/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDColorPickerButtonCell.h"
#import <TDAppKit/TDUtils.h>
#import <OkudaKit/OKUtils.h>
#import "EDUtils.h"

@implementation EDColorPickerButtonCell

- (void)dealloc {
    self.fillColor = nil;
    [super dealloc];
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
    NSColor *fillColor = self.fillColor;
    EDAssert([fillColor isKindOfClass:[NSColor class]]);
    
    // stroke
    EDAssert([cv isKindOfClass:[NSButton class]]);
    NSColor *strokeColor = [NSColor blackColor];
    
    EDDrawColorCell(ctx, r, fillColor, strokeColor, isOn, isHi);
}


- (CGRect)borderRectForCellFrame:(CGRect)cellFrame {
    
//    CGFloat x = TDFloorAlign(cellFrame.origin.x) - 1.0;
//    CGFloat y = TDFloorAlign(cellFrame.origin.y);
//    CGFloat w = floor(cellFrame.size.width);
//    CGFloat h = floor(cellFrame.size.height);
    
    CGRect r = CGRectInset(cellFrame, 4.0, 5.0);
    r.origin.x = TDFloorAlign(r.origin.x);
    r.origin.y = TDFloorAlign(r.origin.y);
    r.size.width = floor(r.size.width) - 1.0;
    r.size.height = floor(r.size.height) - 1.0;
    return r;
}

@end
