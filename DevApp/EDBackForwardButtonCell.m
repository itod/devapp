//
//  EDBackForwardButtonCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/25/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDBackForwardButtonCell.h"
#import <TDAppKit/TDUtils.h>

@implementation EDBackForwardButtonCell

//- (NSRect)imageRectForBounds:(NSRect)bounds {
//    CGFloat x = 0.0;
//    CGFloat y = 0.0;
//    CGFloat w = 0.0;
//    CGFloat h = 0.0;
//    
//    CGRect r = CGRectMake(x, y, w, h);
//    return r;
//}


- (CGFloat)imageAlphaInView:(NSControl *)cv {
    BOOL isMain = [[cv window] isMainWindow];
    BOOL isHi = [self isHighlighted];
    BOOL isDisabled = ![cv isEnabled];
    
    CGFloat alpha = 0.4; // non main
    if (isHi) {
        alpha = 0.8;
    } else if (isDisabled) {
        alpha = 0.3;
    } else if (isMain) {
        alpha = 0.6;
    }
    return alpha;
}


//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSControl *)cv {
//    [super drawWithFrame:cellFrame inView:cv];
//    
//    BOOL isMain = [[cv window] isMainWindow];
//    BOOL isHi = [self isHighlighted];
//    BOOL isDisabled = ![cv isEnabled];
//    
//    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
//
//    CGFloat alpha = 0.6; // non main
//    if (isHi) {
//        alpha = 1.0;
//    } else if (isDisabled) {
//        alpha = 0.5;
//    } else if (isMain) {
//        alpha = 0.85;
//    }
//
//}

@end
