//
//  FlatTabStyle.m
//  TKAppKit
//
//  Created by Todd Ditchendorf on 5/3/12.
//  Copyright (c) 2012 Celestial Teapot Software. All rights reserved.
//

#import "FlatTabStyle.h"
#import <TabKit/TKTabsListViewController.h>
#import <TabKit/TKTabModel.h>
#import <TabKit/TKTabListItem.h>
#import <TDAppKit/TDUtils.h>
#import <TDAppKit/NSImage+TDAdditions.h>
#import "FlatStyleCloseButton.h"
#import "FlatStyleExtraButton.h"

#define BORDER_STROKE_WIDTH 1.0

#define EXTRA_BUTTON_EXTENT 25.0

#define MIN_EXTENT_FOR_TITLE 42.0

#define TITLE_MARGIN_X 4.0
#define TITLE_HEIGHT 13.0

#define CLOSE_BUTTON_MARGIN_X 5.0
#define CLOSE_BUTTON_WIDTH 14.0
#define CLOSE_BUTTON_HEIGHT 14.0

#define FAVICON_MARGIN_X 4.0
#define FAVICON_MARGIN_Y 3.0
#define FAVICON_WIDTH 16.0
#define FAVICON_HEIGHT 16.0

static NSDictionary *sSelectedTitleAttrs = nil;
static NSDictionary *sNonMainSelectedTitleAttrs = nil;
static NSDictionary *sTitleAttrs = nil;
static NSDictionary *sNonMainTitleAttrs = nil;

static NSColor *sDormantBgColor1 = nil;
static NSGradient *sDormantBgGradient = nil;
static NSColor *sNonMainDormantBgColor1 = nil;
static NSGradient *sNonMainDormantBgGradient = nil;

static NSGradient *sHoverBgGradient = nil;
static NSGradient *sNonMainHoverBgGradient = nil;

static NSColor *sSelectedBgColor1 = nil;
static NSGradient *sSelectedBgGradient = nil;
static NSGradient *sSelectedHoverBgGradient = nil;
static NSColor *sNonMainSelectedBgColor1 = nil;
static NSGradient *sNonMainSelectedBgGradient = nil;

static NSGradient *sActiveBgGradient = nil;

static NSColor *sStrokeColor = nil;
static NSColor *sNonMainStrokeColor = nil;
static NSColor *sSelectedStrokeColor = nil;
static NSColor *sNonMainSelectedStrokeColor = nil;
static NSColor *sDisabledStrokeColor = nil;
static NSColor *sNonMainDisabledStrokeColor = nil;

static NSColor *sIconColor = nil;
static NSColor *sHoverIconColor = nil;
static NSColor *sActiveIconColor = nil;
static NSColor *sNonMainIconColor = nil;
static NSColor *sDisabledIconColor = nil;
static NSColor *sNonMainDisabledIconColor = nil;

static NSDictionary *sHints = nil;

@interface NSObject ()
- (NSImage *)favicon;
@end

@implementation FlatTabStyle

+ (void)load {
    if ([FlatTabStyle class] == self) {
        [TKTabsListViewController registerStyleClass:[FlatTabStyle class] forName:[FlatTabStyle name]];
    }
}


+ (void)initialize {
    if ([FlatTabStyle class] == self) {
        
        NSFont *font = [NSFont systemFontOfSize:11.0];
        
        NSColor *selectedTitleColor = TDGrayColor(0.1);
        NSColor *titleColor = TDGrayColor(0.2);

        NSColor *nonMainSelectedTitleColor = TDGrayColor(0.3);
        NSColor *nonMainTitleColor = TDGrayColor(0.4);

        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSTextAlignmentLeft];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        
        NSShadow *selectedShadow = nil;//[[[NSShadow alloc] init] autorelease];
//        [selectedShadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
//        [selectedShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
//        [selectedShadow setShadowBlurRadius:0.0];
        
        sSelectedTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                               font, NSFontAttributeName,
                               selectedTitleColor, NSForegroundColorAttributeName,
                               paraStyle, NSParagraphStyleAttributeName,
                               selectedShadow, NSShadowAttributeName,
                               nil];
        
        NSShadow *shadow = nil;//[[[NSShadow alloc] init] autorelease];
//        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.3]];
//        [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
//        [shadow setShadowBlurRadius:0.0];
        
        sTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                       font, NSFontAttributeName,
                       titleColor, NSForegroundColorAttributeName,
                       paraStyle, NSParagraphStyleAttributeName,
                       shadow, NSShadowAttributeName,
                       nil];
        
        NSShadow *nonMainShadow = nil;//[[[NSShadow alloc] init] autorelease];
//        [nonMainShadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.3]];
//        [nonMainShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
//        [nonMainShadow setShadowBlurRadius:0.0];
        
        sNonMainSelectedTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      font, NSFontAttributeName,
                                      nonMainSelectedTitleColor, NSForegroundColorAttributeName,
                                      paraStyle, NSParagraphStyleAttributeName,
                                      nonMainShadow, NSShadowAttributeName,
                                      nil];
        
        sNonMainTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                              font, NSFontAttributeName,
                              nonMainTitleColor, NSForegroundColorAttributeName,
                              paraStyle, NSParagraphStyleAttributeName,
                              nonMainShadow, NSShadowAttributeName,
                              nil];
        
        // selected fill
        sSelectedBgColor1          = [TDGrayColor(0.85) retain];
        sSelectedBgGradient        = [[NSGradient alloc] initWithStartingColor:sSelectedBgColor1 endingColor:TDGrayColor(0.80)];
        sSelectedHoverBgGradient   = [[NSGradient alloc] initWithStartingColor:TDGrayColor(0.90) endingColor:TDGrayColor(0.85)];
        sNonMainSelectedBgColor1   = [TDGrayColor(0.95) retain];
        sNonMainSelectedBgGradient = [[NSGradient alloc] initWithStartingColor:sNonMainSelectedBgColor1 endingColor:TDGrayColor(0.87)];
        
        // dormant fill
        sDormantBgColor1           = [TDGrayColor(0.67) retain];
        sDormantBgGradient         = [[NSGradient alloc] initWithStartingColor:sDormantBgColor1 endingColor:TDGrayColor(0.73)];
        sNonMainDormantBgColor1    = [TDGrayColor(0.82) retain];
        sNonMainDormantBgGradient  = [[NSGradient alloc] initWithStartingColor:sNonMainDormantBgColor1 endingColor:TDGrayColor(0.88)];
        
        // hover fill
        sHoverBgGradient           = [[NSGradient alloc] initWithStartingColor:TDGrayColor(0.62) endingColor:TDGrayColor(0.68)];
        sNonMainHoverBgGradient    = [[NSGradient alloc] initWithStartingColor:TDHexColor(0xbbbbbb) endingColor:TDHexColor(0xbfbfbf)];
        
        // active fill
        sActiveBgGradient          = [[NSGradient alloc] initWithStartingColor:TDGrayColor(0.80) endingColor:TDGrayColor(0.73)];

        // selected stroke color
        sSelectedStrokeColor = [TDHexColor(0x777777) retain];
        sNonMainSelectedStrokeColor = [TDHexColor(0xaaaaaa) retain];
        
        // disabled stroke color
        sDisabledStrokeColor = [TDHexColor(0xcccccc) retain];
        sNonMainDisabledStrokeColor = [TDHexColor(0xdddddd) retain];
        
        // normal stroke color
        sStrokeColor = [TDHexColor(0x7a7a7a) retain];
        sNonMainStrokeColor = [TDHexColor(0xaaaaaa) retain];
        
        // button icon color
        sIconColor = [TDGrayColor(0.4) retain];
        sHoverIconColor = [TDGrayColor(0.3) retain];
        sActiveIconColor = [TDGrayColor(0.1) retain];
        sNonMainIconColor = [TDGrayColor(0.5) retain];
        sDisabledIconColor = [TDGrayColor(0.75) retain];
        sNonMainDisabledIconColor = [TDGrayColor(0.8) retain];

        sHints = [[NSDictionary alloc] initWithObjectsAndKeys:
                  @(NSImageInterpolationHigh), NSImageHintInterpolation,
                  nil];
    }
}

+ (NSDictionary *)selectedTitleTextAttributes { return sSelectedTitleAttrs; }

+ (NSGradient *)dormantBgGradient { return sDormantBgGradient; }
+ (NSGradient *)nonMainDormantBgGradient { return sNonMainDormantBgGradient; }
+ (NSGradient *)hoverBgGradient { return sHoverBgGradient; }
+ (NSGradient *)nonMainHoverBgGradient { return sNonMainHoverBgGradient; }
+ (NSGradient *)selectedBgGradient { return sSelectedBgGradient; }
+ (NSGradient *)selectedHoverBgGradient { return sSelectedHoverBgGradient; }
+ (NSGradient *)nonMainSelectedBgGradient { return sNonMainSelectedBgGradient; }
+ (NSGradient *)activeBgGradient { return sActiveBgGradient; }

+ (NSColor *)strokeColor { return sStrokeColor; }
+ (NSColor *)nonMainStrokeColor { return sNonMainStrokeColor; }
+ (NSColor *)selectedStrokeColor { return sSelectedStrokeColor; }
+ (NSColor *)nonMainSelectedStrokeColor { return sNonMainSelectedStrokeColor; }
+ (NSColor *)iconColor { return sIconColor; }
+ (NSColor *)hoverIconColor { return sHoverIconColor; }
+ (NSColor *)activeIconColor { return sActiveIconColor; }
+ (NSColor *)nonMainIconColor { return sNonMainIconColor; }


+ (NSGradient *)bgGradientForButton:(id)b {
    BOOL isMain = [[b window] isMainWindow];
    BOOL isSelected = [b isSelected];
    BOOL isActive = TKTabItemPointerStateActive == [b pointerState];
    BOOL isHover = TKTabItemPointerStateHover == [b pointerState];
    
    NSGradient *bgGrad = nil;
    
    if (isMain) {
        if (isActive) {
            bgGrad = sActiveBgGradient;
        } else if (isSelected) {
            bgGrad = isHover ? sSelectedHoverBgGradient : sSelectedBgGradient;
        } else {
            bgGrad = isHover ? sHoverBgGradient : sDormantBgGradient;
        }
    } else {
        if (isActive) {
            bgGrad = sActiveBgGradient;
        } else if (isSelected) {
            bgGrad = isHover ? sNonMainSelectedBgGradient : sNonMainSelectedBgGradient;
        } else {
            bgGrad = isHover ? sNonMainHoverBgGradient : sNonMainDormantBgGradient;
        }
    }

    TDAssert(bgGrad);
    return bgGrad;
}


+ (NSColor *)strokeColorForButton:(id)b {
    BOOL isMain = [[b window] isMainWindow];
    BOOL isSelected = [b isSelected];
    BOOL isDisabled = ![b isEnabled];

    NSColor *stroke = nil;
    
    if (isMain) {
        if (isDisabled) {
            stroke = sDisabledStrokeColor;
        } else {
            stroke = isSelected ? sSelectedStrokeColor : sStrokeColor;
        }
    } else {
        if (isDisabled) {
            stroke = sNonMainDisabledStrokeColor;
        } else {
            stroke = isSelected ? sNonMainSelectedStrokeColor : sNonMainStrokeColor;
        }
    }

    TDAssert(stroke);
    return stroke;
}


+ (NSColor *)iconColorForButton:(id)b {
    BOOL isMain = [[b window] isMainWindow];
    BOOL isActive = TKTabItemPointerStateActive == [b pointerState];
    BOOL isHover = TKTabItemPointerStateHover == [b pointerState];
    BOOL isDisabled = ![b isEnabled];

    NSColor *iconColor = nil;
    
    if (isMain) {
        if (isDisabled) {
            iconColor = sDisabledIconColor;
        } else if (isActive) {
            iconColor = sActiveIconColor;
        } else {
            iconColor = isHover ? sHoverIconColor : sIconColor;
        }
    } else {
        if (isDisabled) {
            iconColor = sNonMainDisabledIconColor;
        } else {
            iconColor = isActive ? sActiveIconColor : sNonMainIconColor;
        }
    }
    
    TDAssert(iconColor);
    return iconColor;
}


+ (NSColor *)highlightColorForButton:(id)b {
    BOOL isMain = [[b window] isMainWindow];
    BOOL isSelected = [b isSelected];
    
    NSColor *hiColor = nil;
    
    if (isMain) {
        hiColor = isSelected ? sSelectedBgColor1 : sDormantBgColor1;
    } else {
        hiColor = isSelected ? sNonMainSelectedBgColor1 : sNonMainDormantBgColor1;
    }
    
    return TDGrayColorDiff(hiColor, -0.05);
}


+ (NSGradient *)bgGradientForTab:(id)b {
    BOOL isMain = [[b window] isMainWindow];
    BOOL isSelected = [b isSelected];
    BOOL isHover = TKTabItemPointerStateHover == [b pointerState];
    
    NSGradient *bgGrad = nil;
    
    if (isMain) {
        if (isSelected) {
            bgGrad = sSelectedBgGradient;
        } else {
            bgGrad = isHover ? sHoverBgGradient : sDormantBgGradient;
        }
    } else {
        if (isSelected) {
            bgGrad = sNonMainSelectedBgGradient;
        } else {
            bgGrad = isHover ? sNonMainHoverBgGradient : sNonMainDormantBgGradient;
        }
    }
    
    TDAssert(bgGrad);
    return bgGrad;
}


+ (NSColor *)strokeColorForTab:(id)b {
    BOOL isMain = [[b window] isMainWindow];
    BOOL isSelected = [b isSelected];
    
    NSColor *stroke = nil;
    
    if (isMain) {
        stroke = isSelected ? sSelectedStrokeColor : sStrokeColor;
    } else {
        stroke = isSelected ? sNonMainSelectedStrokeColor : sNonMainStrokeColor;
    }
    
    TDAssert(stroke);
    return stroke;
}


+ (NSColor *)iconColorForTab:(id)b {
    BOOL isMain = [[b window] isMainWindow];
    BOOL isActive = TKTabItemPointerStateActive == [b pointerState];
    BOOL isHover = TKTabItemPointerStateHover == [b pointerState];
    
    NSColor *iconColor = nil;
    
    if (isMain) {
        if (isActive) {
            iconColor = sActiveIconColor;
        } else {
            iconColor = isHover ? sHoverIconColor : sIconColor;
        }
    } else {
        iconColor = isActive ? sActiveIconColor : sNonMainIconColor;
    }
    
    TDAssert(iconColor);
    return iconColor;
}


+ (NSString *)name {
    return @"Flat";
}


+ (CGFloat)tabItemExtentForScrollSize:(CGSize)scrollSize isPortrait:(BOOL)isPortrait {
    return 1000000.0;
}


+ (CGFloat)tabItemMinimumExtent {
    return 40.0;
}


+ (CGFloat)preferredTabItemFixedExtent {
    return 24.0;
}


+ (NSFont *)titleFont {
    return [sTitleAttrs objectForKey:NSFontAttributeName];
}


+ (NSTextAlignment)titleTextAlignment {
    return NSTextAlignmentLeft;
}


+ (TKButton *)newCloseTabButtonWithFrame:(CGRect)frame {
    id b = [[FlatStyleCloseButton alloc] initWithFrame:frame];
    TDAssert(b);
    return b;
}


+ (BOOL)displaysClippedItems {
    return NO;
}


+ (BOOL)wantsSquishedItems {
    return YES;
}


+ (BOOL)wantsCloseButton {
    return YES;
}


+ (BOOL)wantsProgressIndicator {
    return YES;
}


+ (BOOL)wantsIcon {
    return YES;
}


+ (BOOL)wantsAddButton {
    return YES;
}


+ (BOOL)wantsOverflowButton {
    return YES;
}


+ (id)newAddButtonWithFrame:(CGRect)frame {
    id b = [[FlatStyleExtraButton alloc] initWithFrame:frame];
    [b setIsAdd:YES];
    TDAssert(b);
    return b;
}


+ (id)newOverflowButtonWithFrame:(CGRect)frame {
    id b = [[FlatStyleExtraButton alloc] initWithFrame:frame];
    TDAssert(b);
    return b;
}


- (CGRect)buttonRectForBounds:(CGRect)bounds addButtonVisible:(BOOL)addButtonVisible overflowButtonVisible:(BOOL)overflowButtonVisible {
    CGFloat x, y, w, h;
    
    x = NSMaxX(bounds);
    y = NSMinY(bounds);
    w = 0.0;
    h = NSHeight(bounds);
    
    if (addButtonVisible) {
        x -= EXTRA_BUTTON_EXTENT;
        w += EXTRA_BUTTON_EXTENT;
    }
    if (overflowButtonVisible) {
        x -= EXTRA_BUTTON_EXTENT;
        w += EXTRA_BUTTON_EXTENT;
    }
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)scrollRectForBounds:(CGRect)bounds buttonRect:(CGRect)buttonRect {
    CGFloat x, y, w, h;
    
    x = NSMinX(bounds);
    y = NSMinY(bounds);
    w = NSWidth(bounds) - NSWidth(buttonRect) + BORDER_STROKE_WIDTH; // 1.0 for the right stroke
    h = NSHeight(bounds);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)addButtonRectForButtonRect:(CGRect)buttonRect addButtonVisible:(BOOL)addButtonVisible overflowButtonVisible:(BOOL)overflowButtonVisible {
    CGFloat x, y, w, h;
    
    x = NSMinX(buttonRect);
    y = NSMinY(buttonRect);
    w = EXTRA_BUTTON_EXTENT;
    h = NSHeight(buttonRect);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)overflowButtonRectForButtonRect:(CGRect)buttonRect addButtonVisible:(BOOL)addButtonVisible overflowButtonVisible:(BOOL)overflowButtonVisible {
    CGFloat x, y, w, h;
    
    x = NSMinX(buttonRect);
    y = NSMinY(buttonRect);
    w = EXTRA_BUTTON_EXTENT;
    h = NSHeight(buttonRect);
    
    if (addButtonVisible) {
        x += EXTRA_BUTTON_EXTENT;
    }
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)tabListItem:(TKTabListItem *)item borderRectForBounds:(CGRect)bounds {
    CGFloat x = TDFloorAlign(bounds.origin.x);
    CGFloat y = TDFloorAlign(bounds.origin.y);
    CGFloat w = round(NSWidth(bounds));
    CGFloat h = round(NSHeight(bounds));
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)tabListItem:(TKTabListItem *)item closeButtonRectForBounds:(CGRect)bounds {
    CGFloat x = round(NSMaxX(bounds) - (CLOSE_BUTTON_WIDTH + CLOSE_BUTTON_MARGIN_X));
    CGFloat y = round(NSMidY(bounds) - CLOSE_BUTTON_HEIGHT*0.5);
    CGFloat w = CLOSE_BUTTON_WIDTH;
    CGFloat h = CLOSE_BUTTON_HEIGHT;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)tabListItem:(TKTabListItem *)item titleRectForBounds:(CGRect)bounds {
    TDAssert(item.showsCloseButton);
    
    CGFloat x = round(NSMinX(bounds) + FAVICON_MARGIN_X + FAVICON_WIDTH + TITLE_MARGIN_X);
    CGFloat y = round(NSMidY(bounds) - TITLE_HEIGHT*0.5) - 1.0;
    CGFloat w = NSWidth(bounds) - (TITLE_MARGIN_X*2.0 + FAVICON_WIDTH + FAVICON_MARGIN_X);
    if (TKTabItemPointerStateDormant != item.pointerState) {
        w -= (CLOSE_BUTTON_WIDTH + CLOSE_BUTTON_MARGIN_X);
    }
    w = round(w);
    CGFloat h = TITLE_HEIGHT;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)tabListItem:(TKTabListItem *)item progressIndicatorRectForBounds:(CGRect)bounds {
    if (item.showsProgressIndicator) {
        return [self iconRectForBounds:bounds];
    } else {
        return CGRectZero;
    }
}


- (CGRect)tabListItem:(TKTabListItem *)item thumbnailRectForBounds:(CGRect)bounds {
    return CGRectZero;
}


- (CGRect)tabListItem:(TKTabListItem *)item iconRectForBounds:(CGRect)bounds {
    if (item.showsProgressIndicator) {
        return CGRectZero;
    } else {
        return [self iconRectForBounds:bounds];
    }
}


- (CGRect)iconRectForBounds:(CGRect)bounds {
    CGFloat x = round(NSMinX(bounds) + FAVICON_MARGIN_X);
    CGFloat y = round(NSMidY(bounds) - FAVICON_HEIGHT*0.5);
    CGFloat w = FAVICON_WIDTH;
    CGFloat h = FAVICON_HEIGHT;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (void)needsDisplayInListItem:(TKTabListItem *)item {
    TDAssert(item.showsCloseButton);
    FlatStyleCloseButton *b = (FlatStyleCloseButton *)item.closeButton;
    TDAssert(b);
    [b setNeedsDisplay:YES];
}


- (void)layoutSubviewsInTabListItem:(TKTabListItem *)item {
    CGRect bounds = [item bounds];

    TDAssert(item.showsCloseButton);
    if (TKTabItemPointerStateDormant == item.pointerState) {
        [item.closeButton setHidden:YES];
    } else {
        [item.closeButton setHidden:NO];
        [item.closeButton setFrame:[self tabListItem:item closeButtonRectForBounds:bounds]];
    }
    if (item.showsProgressIndicator) {
        [item.progressIndicator setFrame:[self tabListItem:item progressIndicatorRectForBounds:bounds]];
    }
}


- (void)drawTabListItem:(TKTabListItem *)item inContext:(CGContextRef)ctx {
    CGRect bounds = [item bounds];
    
    BOOL isSelected = item.isSelected;
    BOOL isMain = [[item window] isMainWindow];
    
#if 0
    CGRect iconRect = [self tabListItem:item iconRectForBounds:bounds];
    CGRect progRect = [self tabListItem:item progressIndicatorRectForBounds:bounds];
    CGRect titleRect = [self tabListItem:item titleRectForBounds:bounds];
    CGRect closeRect = [self tabListItem:item closeButtonRectForBounds:bounds];
    
    [[NSColor redColor] setStroke];
    CGContextStrokeRect(ctx, iconRect);
    [[NSColor greenColor] setStroke];
    CGContextStrokeRect(ctx, progRect);
    [[NSColor blueColor] setStroke];
    CGContextStrokeRect(ctx, titleRect);
    [[NSColor orangeColor] setStroke];
    CGContextStrokeRect(ctx, closeRect);
#else
    // FILL BG GRADIENT
    [[FlatTabStyle bgGradientForTab:item] drawInRect:bounds angle:90.0];
    
    // STROKE COLOR
    [[FlatTabStyle strokeColorForTab:item] setStroke];

    CGContextSetLineWidth(ctx, BORDER_STROKE_WIDTH);
    
    // RIGHT SIDE STROKE
    {
        // side stroke
        CGFloat x = TDRoundAlign(NSMaxX(bounds) - BORDER_STROKE_WIDTH);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, x, NSMinY(bounds));
        CGContextAddLineToPoint(ctx, x, NSMaxY(bounds));
        CGContextStrokePath(ctx);
    }

//    // TOP STROKE
//    {
//        CGFloat y = TDFloorAlign(NSMinY(bounds));
//        CGContextBeginPath(ctx);
//        CGContextMoveToPoint(ctx, NSMinX(bounds), y);
//        CGContextAddLineToPoint(ctx, NSMaxX(bounds), y);
//        CGContextStrokePath(ctx);
//    }
    
    // ICON
    if (item.showsFavicon && !item.showsProgressIndicator) {
        //NSString *URLString = [item.representedObject URLString];
        //NSImage *img = [[FaviconController instance] faviconForURLString:URLString];
        CGRect iconRect = [self iconRectForBounds:bounds];
        NSImage *img = [item.representedObject favicon];
        CGRect srcRect = CGRectMake(0.0, 0.0, img.size.width, img.size.height);
        CGFloat alpha = isMain ? 1.0 : 0.65;
        [img drawInRect:iconRect fromRect:srcRect operation:NSCompositingOperationSourceOver fraction:alpha respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
    }

    // TITLE
    if (NSWidth(bounds) > MIN_EXTENT_FOR_TITLE) {
        CGRect titleRect = [self tabListItem:item titleRectForBounds:bounds];
        NSUInteger opts = NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin;
        NSDictionary *attrs = nil;
        if (isMain) {
            attrs = isSelected ? sSelectedTitleAttrs : sTitleAttrs;
        } else {
            attrs = isSelected ? sNonMainSelectedTitleAttrs : sNonMainTitleAttrs;
        }
        [item.title drawWithRect:titleRect options:opts attributes:attrs context:nil];
    }
    
    // SUBVIEWS ??
    {
        TDAssert(item.showsCloseButton);
        [item.closeButton setNeedsDisplay:YES];
        [item.progressIndicator setNeedsDisplay:YES];
    }
#endif
}

@end
