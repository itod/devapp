//
//  FlatTabStyle.h
//  TKAppKit
//
//  Created by Todd Ditchendorf on 5/3/12.
//  Copyright (c) 2012 Celestial Teapot Software. All rights reserved.
//

#import <TabKit/TKTabListItemStyle.h>

@interface FlatTabStyle : TKTabListItemStyle

+ (NSDictionary *)selectedTitleTextAttributes;

+ (NSGradient *)dormantBgGradient;
+ (NSGradient *)nonMainDormantBgGradient;
+ (NSGradient *)hoverBgGradient;
+ (NSGradient *)nonMainHoverBgGradient;
+ (NSGradient *)selectedBgGradient;
+ (NSGradient *)nonMainSelectedBgGradient;
+ (NSGradient *)activeBgGradient;

+ (NSColor *)strokeColor;
+ (NSColor *)nonMainStrokeColor;
+ (NSColor *)selectedStrokeColor;
+ (NSColor *)nonMainSelectedStrokeColor;
+ (NSColor *)iconColor;
+ (NSColor *)hoverIconColor;
+ (NSColor *)activeIconColor;
+ (NSColor *)nonMainIconColor;

+ (NSGradient *)bgGradientForButton:(id)b;
+ (NSColor *)strokeColorForButton:(id)b;
+ (NSColor *)iconColorForButton:(id)b;
+ (NSColor *)highlightColorForButton:(id)b;

+ (NSGradient *)bgGradientForTab:(id)b;
+ (NSColor *)strokeColorForTab:(id)b;
+ (NSColor *)iconColorForTab:(id)b;

@end
