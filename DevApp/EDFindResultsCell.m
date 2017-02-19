//
//  EDFindResultsCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/21/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFindResultsCell.h"
#import "EDUtils.h"

#define IMG_MARGIN_RIGHT 4.0

#define IMG_WIDTH 16.0
#define IMG_HEIGHT 16.0

#define TITLE_MARGIN_TOP -1.0

@interface EDFindResultsCell ()

@end

@implementation EDFindResultsCell

//+ (void)initialize {
//    if ([EDFindResultsCell class] == self) {
//    }
//}


+ (NSSize)preferredIconSize {
    return NSMakeSize(IMG_WIDTH, IMG_HEIGHT);
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSOutlineView *)cv {
    EDAssert([self objectValue]);
    
    //BOOL isMain = [[cv window] isMainWindow];
    //BOOL isHi = [self isHighlighted];
    
    //NSLog(@"%d %d", isMain, isHi);
    
    NSAttributedString *attrStr = nil;
    
    id obj = [self objectValue];
    if ([obj isKindOfClass:[NSAttributedString class]]) {
        attrStr = obj;
        NSString *absPath = [obj string];

        EDAssert([absPath isKindOfClass:[NSString class]]);
        EDAssert([absPath length]);
        
        if ([self isFilePathCell]) {
            NSImage *image = EDIconForFile(absPath);
            EDAssert(image);
            
            NSSize imgSize = [image size];
            NSRect imgSrcRect = NSMakeRect(0.0, 0.0, imgSize.width, imgSize.height);
            NSRect imgDestRect = [self imageRectForBounds:cellFrame];
            [image drawInRect:imgDestRect fromRect:imgSrcRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
        }
    }

    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [attrStr drawInRect:titleRect];
}


- (BOOL)isFilePathCell {
    return [[[[self objectValue] string] pathExtension] isEqualToString:@"py"];
}


- (CGFloat)imageMarginLeft {
    return [self isFilePathCell] ? -38.0 : 0.0;
}


- (NSRect)checkboxRectForBounds:(NSRect)bounds {
    CGFloat x = NSMinX(bounds) + [self imageMarginLeft];
    CGFloat y = NSMinY(bounds);
    CGFloat w = IMG_WIDTH;
    CGFloat h = IMG_HEIGHT;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (NSRect)imageRectForBounds:(NSRect)bounds {
    CGRect r = CGRectZero;
    
    id obj = [self objectValue];
    if ([obj isKindOfClass:[NSAttributedString class]]) {

        CGFloat x = NSMinX(bounds) + [self imageMarginLeft];
        CGFloat y = NSMinY(bounds);
        CGFloat w = IMG_WIDTH;
        CGFloat h = IMG_HEIGHT;

        r = CGRectMake(x, y, w, h);
    }
    
    return r;
}


- (NSRect)titleRectForBounds:(NSRect)bounds {
    NSRect r = [super titleRectForBounds:bounds];
    
    CGFloat marginX = [self imageMarginLeft];
    if ([self isFilePathCell]) marginX += (IMG_WIDTH + IMG_MARGIN_RIGHT);
    r.origin.x += marginX;
    r.size.width -= marginX;
    
    r.origin.y += TITLE_MARGIN_TOP;
    return r;
}

@end
