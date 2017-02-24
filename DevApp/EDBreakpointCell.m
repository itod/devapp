//
//  EDBreakpointCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/21/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDBreakpointCell.h"
#import "EDMainWindowController.h"
#import "EDUtils.h"
#import <Language/XPBreakpoint.h>

#define IMG_MARGIN_LEFT 5.0
#define IMG_MARGIN_RIGHT 4.0

#define IMG_WIDTH 16.0
#define IMG_HEIGHT 16.0

#define TITLE_MARGIN_TOP 2.0

static NSDictionary *sTitleAttrs = nil;
static NSDictionary *sHiTitleAttrs = nil;

@interface EDBreakpointCell ()

@end

@implementation EDBreakpointCell

+ (void)initialize {
    if ([EDBreakpointCell class] == self) {

        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSLeftTextAlignment];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        
        sTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [NSFont controlContentFontOfSize:11.0], NSFontAttributeName,
                       [NSColor controlTextColor], NSForegroundColorAttributeName,
                       paraStyle, NSParagraphStyleAttributeName,
                       nil];
        
        NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
        [textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.4]];
        [textShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        [textShadow setShadowBlurRadius:1.0];
        
        sHiTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSFont controlContentFontOfSize:11.0], NSFontAttributeName,
                         [NSColor highlightColor], NSForegroundColorAttributeName,
                         paraStyle, NSParagraphStyleAttributeName,
                         textShadow, NSShadowAttributeName,
                         nil];
    }
}


+ (NSSize)preferredIconSize {
    return NSMakeSize(IMG_WIDTH, IMG_HEIGHT);
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}


- (void)selectWithFrame:(NSRect)frame inView:(NSView *)cv editor:(NSText *)text delegate:(id)d start:(NSInteger)start length:(NSInteger)len {
    NSRect textFrame = [self editRectForBounds:frame];
    [super selectWithFrame:textFrame inView:cv editor:text delegate:d start:start length:len];
}


- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSOutlineView *)cv {
    //EDAssert([cv isKindOfClass:[NSOutlineView class]]);
    EDAssert([self objectValue]);
    
    //NSOutlineView *ov = (NSOutlineView *)cv;
    //BOOL isSelected = self == [ov selectedCell];

    //BOOL isMain = [[cv window] isMainWindow];
    BOOL isHi = [self isHighlighted];
    
    //NSLog(@"%d %d", isMain, isHi);
    
    NSString *relPath = nil;
    NSString *title = nil;
    
    BOOL wantsImage = YES;
    
    id obj = [self objectValue];
    if ([obj isKindOfClass:[NSAttributedString class]]) {
        relPath = [obj string];
        title = [relPath lastPathComponent];
    } else if ([obj isKindOfClass:[NSString class]]) {
        relPath = obj;
        title = [relPath lastPathComponent];
    } else {
        EDAssert([obj isKindOfClass:[XPBreakpoint class]]);
        title = [obj displayString];
        wantsImage = NO;
    }
    EDAssert(!relPath || [relPath isKindOfClass:[NSString class]]);
    EDAssert(!relPath || [relPath length]);
    EDAssert(title);
    
    NSImage *image = nil;
    if (wantsImage) {
        NSString *absPath = [(id)[[cv window] windowController] absoluteSourceFilePathForRelativeSourceFilePath:relPath];
        if (absPath) {
            EDAssert([absPath isAbsolutePath]);
            
            image = EDIconForFile(absPath);
            EDAssert(image);
            CGSize imgSize = [image size];
            
            CGRect imgSrcRect = CGRectMake(0.0, 0.0, imgSize.width, imgSize.height);
            CGRect imgDestRect = [self imageRectForBounds:frame];
            [image drawInRect:imgDestRect fromRect:imgSrcRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
        }
    }
    
    NSDictionary *attrs = isHi ? sHiTitleAttrs : sTitleAttrs;
    NSRect titleRect = [self titleRectForBounds:frame hasImage:(image != nil)];
    [title drawInRect:titleRect withAttributes:attrs];
}


- (NSRect)imageRectForBounds:(NSRect)bounds {
    CGFloat x = NSMinX(bounds) + IMG_MARGIN_LEFT;
    CGFloat y = NSMinY(bounds);
    CGFloat w = IMG_WIDTH;
    CGFloat h = IMG_HEIGHT;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (NSRect)titleRectForBounds:(NSRect)bounds hasImage:(BOOL)hasImage {
    NSRect r = [super titleRectForBounds:bounds];
    
    CGFloat marginX = hasImage ? IMG_WIDTH + IMG_MARGIN_LEFT + IMG_MARGIN_RIGHT : IMG_MARGIN_RIGHT;
    r.origin.x += marginX;
    r.size.width -= marginX;
    
    r.origin.y += TITLE_MARGIN_TOP;
    r.size.height -= (TITLE_MARGIN_TOP + 1.0);
    return r;
}


- (NSRect)editRectForBounds:(NSRect)bounds {
    BOOL hasImg = ![[self objectValue] isKindOfClass:[XPBreakpoint class]];
    NSRect r = [self titleRectForBounds:bounds hasImage:hasImg];
    r.origin.x -= 2.0;
    r.size.width += 2.0;
    return r;
}

@end
