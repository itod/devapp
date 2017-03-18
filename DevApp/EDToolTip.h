//
//  EDToolTip.h
//  Shapes
//
//  Created by Todd Ditchendorf on 12/23/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EDToolTip : NSView

- (void)setText:(NSString *)text;
- (void)setLocation:(CGPoint)p;

- (CGSize)size;

@property (nonatomic, copy) NSAttributedString *string;
@end
