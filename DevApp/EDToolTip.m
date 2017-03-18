//
//  EDToolTip.m
//  Shapes
//
//  Created by Todd Ditchendorf on 12/23/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDToolTip.h"

#define DEFAULT_FONT_NAME @"Lucida Grande"
#define DEFAULT_FONT_SIZE 11.0
#define DEFAULT_LINE_HEIGHT_MULTIPLE 1.18

#define MARGIN 5.0
#define PADDING 10.0
#define CORNER_RADIUS 10.0

@interface EDToolTip ()
+ (NSDictionary *)textAttributes;
+ (NSShadow *)shadow;
+ (NSColor *)backgroundColor;
@end

@implementation EDToolTip

+ (NSShadow *)shadow {
    static NSShadow *sShadow = nil;
    @synchronized(self) {
        if (!sShadow) {
            sShadow = [[NSShadow alloc] init];
            [sShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
            [sShadow setShadowOffset:NSMakeSize(0.0, 0.0)];
            [sShadow setShadowBlurRadius:MARGIN];
        }
    }
    return sShadow;
}


+ (NSColor *)backgroundColor {
    static NSColor *sBgColor = nil;
    @synchronized(self) {
        if (!sBgColor) {
            sBgColor = [[NSColor colorWithDeviceWhite:0.0 alpha:0.4] retain];
        }
    }
    return sBgColor;
}


+ (NSDictionary *)textAttributes {
    static NSDictionary *attrs = nil;
    @synchronized(self) {
        if (!attrs) {
            NSColor *foregroundColor = [NSColor whiteColor];
            NSFont *font = [NSFont fontWithName:DEFAULT_FONT_NAME size:DEFAULT_FONT_SIZE];
            
            NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [paraStyle setAlignment:NSCenterTextAlignment];
            [paraStyle setLineBreakMode:NSLineBreakByWordWrapping];
            [paraStyle setMaximumLineHeight:DEFAULT_FONT_SIZE * DEFAULT_LINE_HEIGHT_MULTIPLE];
            
            NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
            [textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
            [textShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
            [textShadow setShadowBlurRadius:2.0];
            
            attrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                     foregroundColor, NSForegroundColorAttributeName,
                     font, NSFontAttributeName,
                     paraStyle, NSParagraphStyleAttributeName,
                     textShadow, NSShadowAttributeName,
                     [NSNumber numberWithInteger:0], NSBaselineOffsetAttributeName,
                     nil];
        }
    }
    return attrs;
}


- (void)dealloc {
    self.string = nil;
    [super dealloc];
}


- (void)setText:(NSString *)text {
    NSDictionary *attrs = [[self class] textAttributes];
    self.string = [[[NSAttributedString alloc] initWithString:text attributes:attrs] autorelease];
    
    CGSize size = [self size];
    CGRect oldFrame = [self frame];
    CGRect newFrame = CGRectMake(NSMinX(oldFrame), NSMinY(oldFrame), size.width, size.height);
    [self setFrame:newFrame];
}


- (void)setLocation:(CGPoint)p {
    CGRect frame = [self frame];
    frame.origin.x = p.x - MARGIN;
    frame.origin.y = p.y - MARGIN;
    [self setFrame:frame];
}


- (CGSize)size {
    CGSize size = [_string size];
    return CGSizeMake(size.width + MARGIN * 2.0 + PADDING * 2.0, size.height + MARGIN * 2.0 + PADDING * 2.0);
}


- (void)drawRect:(CGRect)dirtyRect {
    CGRect bounds = [self bounds];

    NSBezierPath *bp = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(bounds, MARGIN, MARGIN) xRadius:CORNER_RADIUS yRadius:CORNER_RADIUS];

    [[[self class] shadow] set];
    [[[self class] backgroundColor] setFill];

    [bp fill];
    
    [_string drawAtPoint:CGPointMake(MARGIN + PADDING, MARGIN + PADDING)];
}

@end
