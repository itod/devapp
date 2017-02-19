//
//  EDMidControlBar.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/29/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDMidControlBar.h"

@implementation EDMidControlBar

+ (CGFloat)defaultHeight {
    return 22.0;
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    
    return self;
}
//
//
//- (void)dealloc {
//    
//    [super dealloc];
//}
//
//
//- (void)drawRect:(NSRect)dirtyRect {
//
//}


- (void)awakeFromNib {
    self.mainBgGradient = TDVertGradient(0xefefef, 0xcccccc);
    self.mainBottomBevelColor = [NSColor colorWithDeviceWhite:0.48 alpha:1.0];
    
    self.nonMainBgGradient = TDVertGradient(0xefefef, 0xdfdfdf);
    self.nonMainBottomBevelColor = [NSColor colorWithDeviceWhite:0.7 alpha:1.0];
}

@end
