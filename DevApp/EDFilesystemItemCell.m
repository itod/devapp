//
//  EDFilesystemItemCell.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/21/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFilesystemItemCell.h"
#import "EDFilesystemViewController.h"
#import "EDUtils.h"

#define IMG_MARGIN_LEFT 5.0
#define IMG_MARGIN_RIGHT 4.0

#define IMG_WIDTH 16.0
#define IMG_HEIGHT 16.0

#define PROJ_IMG_MARGIN_TOP 3.0
#define PROJ_IMG_WIDTH 22.0
#define PROJ_IMG_HEIGHT 22.0

#define TITLE_MARGIN_TOP 2.0
#define PROJ_TITLE_MARGIN_TOP 7.0

static NSDictionary *sTitleAttrs = nil;
static NSDictionary *sHiTitleAttrs = nil;
static NSDictionary *sProjTitleAttrs = nil;
static NSDictionary *sHiProjTitleAttrs = nil;

@interface EDFilesystemItemCell ()

@end

@implementation EDFilesystemItemCell

+ (void)initialize {
    if ([EDFilesystemItemCell class] == self) {

        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSTextAlignmentLeft];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        
        sTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [NSFont controlContentFontOfSize:11.0], NSFontAttributeName,
                       [NSColor controlTextColor], NSForegroundColorAttributeName,
                       paraStyle, NSParagraphStyleAttributeName,
                       nil];
        
        sProjTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName,
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

        sHiProjTitleAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName,
                         [NSColor highlightColor], NSForegroundColorAttributeName,
                         paraStyle, NSParagraphStyleAttributeName,
                         textShadow, NSShadowAttributeName,
                         nil];
    }
}


+ (NSSize)preferredIconSize {
    return NSMakeSize(IMG_WIDTH, IMG_HEIGHT);
}


+ (NSSize)projectIconSize {
    return NSMakeSize(PROJ_IMG_WIDTH, PROJ_IMG_HEIGHT);
}


+ (CGFloat)projectItemCellHeight {
    return 28.0;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}


- (NSCellHitResult)hitTestForEvent:(NSEvent *)evt inRect:(NSRect)cellFrame ofView:(NSView *)cv {
    //NSUInteger j = [super hitTestForEvent:evt inRect:cellFrame ofView:cv];
    NSCellHitResult res = NSCellHitContentArea|NSCellHitEditableTextArea;
    return res;
}


- (void)editWithFrame:(NSRect)frame inView:(NSView *)cv editor:(NSText *)text delegate:(id)d event:(NSEvent *)evt {
    NSRect textFrame = [self editRectForBounds:frame];
    [super editWithFrame:textFrame inView:cv editor:text delegate:d event:evt];
}


- (void)selectWithFrame:(NSRect)frame inView:(NSView *)cv editor:(NSText *)text delegate:(id)d start:(NSInteger)start length:(NSInteger)len {
    NSRect textFrame = [self editRectForBounds:frame];
    [super selectWithFrame:textFrame inView:cv editor:text delegate:d start:start length:len];
}


- (NSText *)setUpFieldEditorAttributes:(NSText *)text {
    text = [super setUpFieldEditorAttributes:text];
    
    EDAssert([text isKindOfClass:[NSTextView class]]);
    if ([text isKindOfClass:[NSTextView class]]) {
        NSTextView *tv = (NSTextView *)text;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextStorageWillProcessEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textStorageWillProcessEditing:) name:NSTextStorageWillProcessEditingNotification object:[tv textStorage]];

        [tv setTypingAttributes:sTitleAttrs];
        //[tv setSelectedTextAttributes:sTitleAttrs];
    }

    [text setFont:[sTitleAttrs objectForKey:NSFontAttributeName]];
    [text setTextColor:[sTitleAttrs objectForKey:NSForegroundColorAttributeName]];
    [text setAlignment:[[sTitleAttrs objectForKey:NSParagraphStyleAttributeName] alignment]];

    return text;
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSOutlineView *)cv {
    //EDAssert([cv isKindOfClass:[NSOutlineView class]]);
    //NSOutlineView *ov = (NSOutlineView *)cv;
    //BOOL isSelected = self == [ov selectedCell];

    //BOOL isMain = [[cv window] isMainWindow];
    BOOL isHi = [self isHighlighted];
    
    //NSLog(@"%d %d", isMain, isHi);
    
    NSString *absPath = nil;
    
    id obj = [self objectValue];
    if (!obj) return;
    
    EDAssert(obj);
    
    if ([obj isKindOfClass:[NSAttributedString class]]) {
        absPath = [obj string];
    } else {
        absPath = obj;
    }
    EDAssert([absPath isKindOfClass:[NSString class]]);
    EDAssert([absPath length]);
    
    NSString *title = [absPath lastPathComponent];
    EDAssert(title);
    
    NSImage *image = nil;
    NSRect titleRect;
    NSRect imgDestRect;
    NSDictionary *attrs = nil;

    BOOL dirty = [[(id)[cv window] windowController] filesystemViewController:nil isItemDirtyAtPath:absPath];
    //NSLog(@"path is dirty %@ : %d", absPath, dirty);

    if ([absPath isAbsolutePath]) {
        image = dirty ? EDDirtyIconForFile(absPath) : EDIconForFile(absPath);
        titleRect = [self titleRectForBounds:cellFrame];
        imgDestRect = [self imageRectForBounds:cellFrame];
        attrs = isHi ? sHiTitleAttrs : sTitleAttrs;
    } else {
        // "Project Item"
        image = [NSImage imageNamed:DOC_ICON_NAME];
        titleRect = [self projectTitleRectForBounds:cellFrame];
        imgDestRect = [self projectImageRectForBounds:cellFrame];
        attrs = isHi ? sHiProjTitleAttrs : sProjTitleAttrs;
    }
    EDAssert(image);

    NSSize imgSize = [image size];
    NSRect imgSrcRect = NSMakeRect(0.0, 0.0, imgSize.width, imgSize.height);
    
    [image drawInRect:imgDestRect fromRect:imgSrcRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];

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


- (NSRect)projectImageRectForBounds:(NSRect)bounds {
    CGFloat x = NSMinX(bounds) + IMG_MARGIN_LEFT;
    CGFloat y = NSMinY(bounds) + PROJ_IMG_MARGIN_TOP;
    CGFloat w = PROJ_IMG_WIDTH;
    CGFloat h = PROJ_IMG_HEIGHT;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (NSRect)titleRectForBounds:(NSRect)bounds {
    NSRect r = [super titleRectForBounds:bounds];
    
    CGFloat marginX = IMG_WIDTH + IMG_MARGIN_LEFT + IMG_MARGIN_RIGHT;
    r.origin.x += marginX;
    r.size.width -= marginX;
    
    r.origin.y += TITLE_MARGIN_TOP;
    r.size.height -= (TITLE_MARGIN_TOP + 1.0);
    return r;
}


- (NSRect)projectTitleRectForBounds:(NSRect)bounds {
    NSRect r = [super titleRectForBounds:bounds];
    
    CGFloat marginX = PROJ_IMG_WIDTH + IMG_MARGIN_LEFT + IMG_MARGIN_RIGHT;
    r.origin.x += marginX;
    r.size.width -= marginX;
    
    r.origin.y += PROJ_TITLE_MARGIN_TOP;
    r.size.height -= (TITLE_MARGIN_TOP + 1.0);
    return r;
}


- (NSRect)editRectForBounds:(NSRect)bounds {
    NSRect r = [self titleRectForBounds:bounds];
    r.origin.x -= 2.0;
    r.size.width += 2.0;
    return r;
}


- (void)textStorageWillProcessEditing:(NSNotification *)n {
    NSTextStorage *storage = [n object];
    EDAssert([storage isKindOfClass:[NSTextStorage class]]);
    
    //NSLog(@"%@", [storage string]);
    
    NSString *str = [[storage string] lastPathComponent];
    
    if ([storage length] != [str length]) {
        NSUInteger oldLen = [storage length];
        NSUInteger newLen = [str length];
        NSRange r = NSMakeRange(0, oldLen - newLen);
        [storage deleteCharactersInRange:r];
        
    }
    
    // WTF do I have to do this? -setupFieldEditorAttributes: does not work.
    [storage setAttributes:sTitleAttrs range:NSMakeRange(0, [storage length])];

    //NSLog(@"%@", [storage string]);
}

@end
