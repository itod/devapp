//
//  EDStatusBar.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDStatusBar.h"
#import <TDAppKit/TDUtils.h>

static NSColor *sBorderColor = nil;
static NSColor *sNonMainBorderColor = nil;

static NSColor *sBevelColor = nil;
static NSColor *sNonMainBevelColor = nil;

static NSGradient *sBgGradient = nil;
static NSGradient *sNonMainBgGradient = nil;

@implementation EDStatusBar

+ (void)initialize {
    if ([EDStatusBar class] == self) {
        
        sBorderColor = [[NSColor darkGrayColor] retain];
        sNonMainBorderColor = [TDHexColor(0xaaaaaa) retain];
        
        sBevelColor = [TDHexColor(0xeeeeee) retain];
        sNonMainBevelColor = [[NSColor colorWithDeviceWhite:0.99 alpha:1.0] retain];
        
        NSColor *topColor = nil;
        NSColor *botColor = nil;
        
        topColor = TDHexColor(0xdddddd);
        botColor = TDHexColor(0xaaaaaa);
        sBgGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];

        topColor = TDHexColor(0xefefef);
        botColor = TDHexColor(0xdfdfdf);
        sNonMainBgGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];
    }
}


+ (CGFloat)defaultHeight {
    return 18.0;
}


+ (NSColor *)mainTopBorderColor {
    return sBorderColor;
}


+ (NSColor *)nonMainTopBorderColor {
    return sNonMainBorderColor;
}


- (void)awakeFromNib {
    self.mainTopBorderColor = sBorderColor;
    self.nonMainTopBorderColor = sNonMainBorderColor;
    
    self.mainTopBevelColor = sBevelColor;
    self.nonMainTopBevelColor = sNonMainBevelColor;

    self.mainBgGradient = sBgGradient;
    self.nonMainBgGradient = sNonMainBgGradient;
}

@end
