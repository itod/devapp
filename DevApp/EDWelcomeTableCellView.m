//
//  EDWelcomeTableCellView.m
//  Editor
//
//  Created by Todd Ditchendorf on 9/27/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDWelcomeTableCellView.h"
#import <TDAppKit/TDUtils.h>

@implementation EDWelcomeTableCellView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}


- (void)dealloc {
    self.pathLabel = nil;
    [super dealloc];
}


//- (void)drawRect:(NSRect)dirtyRect {
//	[super drawRect:dirtyRect];
//	
//    CGRect bounds = [self bounds];
//    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
//    
//    CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 0.2);
//    CGContextSetLineWidth(ctx, 2.0);
//    
//    //CGContextFillRect(ctx, bounds);
//    
//    CGContextBeginPath(ctx);
//    CGContextMoveToPoint(ctx, (CGRectGetMinX(bounds)), (CGRectGetMaxY(bounds) - 0.0));
//    CGContextAddLineToPoint(ctx, (CGRectGetMaxX(bounds)), (CGRectGetMaxY(bounds) - 0.0));
//    CGContextStrokePath(ctx);
//}

@end
