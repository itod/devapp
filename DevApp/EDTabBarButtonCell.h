//
//  EDTabBarButtonCell.h
//  Editor
//
//  Created by Todd Ditchendorf on 8/6/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EDTabBarButtonCell : NSButtonCell

+ (CGGradientRef)iconGradientForMain:(BOOL)isMain highlighted:(BOOL)isHi;
+ (NSColor *)iconStrokeColorForMain:(BOOL)isMain highlighted:(BOOL)isHi;
+ (NSShadow *)iconShadowForMain:(BOOL)isMain highlighted:(BOOL)isHi;
@end
