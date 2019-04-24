//
//  EDStatusBar.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDDraggableBar.h>

@interface StatusBar : TDDraggableBar

+ (CGFloat)defaultHeight;
+ (NSColor *)mainTopBorderColor;
+ (NSColor *)nonMainTopBorderColor;
@end
