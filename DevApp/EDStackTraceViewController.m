//
//  EDStackTraceViewController.m
//  Editor
//
//  Created by Todd Ditchendorf on 12/17/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDStackTraceViewController.h"
#import "EDStackTraceContainerView.h"
#import "EDNavTabBarItem.h"
#import "EDTabBarStackTraceButtonCell.h"
#import "EDFileLocation.h"
#import <TDAppKit/TDTabBarItem.h>
#import <TDAppKit/TDUtils.h>
#import <Language/XPStackFrame.h>

static NSDictionary *sAttrsTab = nil;
static NSDictionary *sDisAttrsTab = nil;
static NSDictionary *sSelAttrsTab = nil;

static NSRegularExpression *sRegex = nil;

@interface EDStackTraceViewController ()
@property (nonatomic, retain) NSArray *debugInfo;
@end

@implementation EDStackTraceViewController

+ (void)initialize {
    if ([EDStackTraceViewController class] == self) {

        static NSDictionary *sIndexAttrs = nil;
        static NSDictionary *sDisIndexAttrs = nil;
        static NSDictionary *sSelIndexAttrs = nil;
        
        static NSDictionary *sFuncNameAttrs = nil;
        static NSDictionary *sDisFuncNameAttrs = nil;
        static NSDictionary *sSelFuncNameAttrs = nil;
        
        static NSDictionary *sPathAttrs = nil;
        static NSDictionary *sDisPathAttrs = nil;
        static NSDictionary *sSelPathAttrs = nil;
        
        sRegex = [[NSRegularExpression alloc] initWithPattern:@"(?:(.*)\\n?>\\s+)?((?:[^\\(]+)(?:/(?:[^.]+\\.py))?)\\((\\d+)\\)(.+)?" options:NSRegularExpressionDotMatchesLineSeparators error:nil];

        NSMutableParagraphStyle *paraStyle = nil;
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.9]];
        [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        [shadow setShadowBlurRadius:2.0];

        NSFont *font = [NSFont systemFontOfSize:11.0];
        NSFont *boldFont = [NSFont boldSystemFontOfSize:11.0];
        
        NSColor *color = [NSColor blackColor];
        NSColor *disabledColor = [NSColor grayColor];
        NSColor *selectedColor = [NSColor whiteColor];
        
        paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSTextAlignmentRight];
        [paraStyle setLineBreakMode:NSLineBreakByClipping];

        sIndexAttrs
            = @{NSFontAttributeName: font,
                NSForegroundColorAttributeName: color,
                NSParagraphStyleAttributeName: paraStyle,
                };
        sDisIndexAttrs
            = @{NSFontAttributeName: font,
                NSForegroundColorAttributeName: disabledColor,
                NSParagraphStyleAttributeName: paraStyle,
                };
        sSelIndexAttrs
            = @{NSFontAttributeName: boldFont,
                NSForegroundColorAttributeName: selectedColor,
                NSParagraphStyleAttributeName: paraStyle,
                NSShadowAttributeName: shadow,
                };
        

        paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSTextAlignmentLeft];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];

        sFuncNameAttrs
            = @{NSFontAttributeName: font,
                NSForegroundColorAttributeName: color,
                NSParagraphStyleAttributeName: paraStyle,
                };
        sDisFuncNameAttrs
            = @{NSFontAttributeName: font,
                NSForegroundColorAttributeName: disabledColor,
                NSParagraphStyleAttributeName: paraStyle,
                };
        sSelFuncNameAttrs
            = @{NSFontAttributeName: boldFont,
                NSForegroundColorAttributeName: selectedColor,
                NSParagraphStyleAttributeName: paraStyle,
                NSShadowAttributeName: shadow,
                };
        

        paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSTextAlignmentLeft];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingHead];

        sPathAttrs
            = @{NSFontAttributeName: font,
                NSForegroundColorAttributeName: color,
                NSParagraphStyleAttributeName: paraStyle,
                };
        sDisPathAttrs
            = @{NSFontAttributeName: font,
                NSForegroundColorAttributeName: disabledColor,
                NSParagraphStyleAttributeName: paraStyle,
                };
        sSelPathAttrs
            = @{NSFontAttributeName: boldFont,
                NSForegroundColorAttributeName: selectedColor,
                NSParagraphStyleAttributeName: paraStyle,
                NSShadowAttributeName: shadow,
                };
        
        sAttrsTab
            = [@{@"index": sIndexAttrs,
                @"funcName": sFuncNameAttrs,
                @"displayPath": sPathAttrs,
                } retain];
        sDisAttrsTab
            = [@{@"index": sDisIndexAttrs,
                 @"funcName": sDisFuncNameAttrs,
                 @"displayPath": sDisPathAttrs,
                 } retain];
        sSelAttrsTab
            = [@{@"index": sSelIndexAttrs,
                 @"funcName": sSelFuncNameAttrs,
                 @"displayPath": sSelPathAttrs,
                 } retain];
    }
}


- (id)init {
    self = [self initWithNibName:@"EDStackTraceViewController" bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    self = [super initWithNibName:name bundle:b];
    if (self) {
        self.title = NSLocalizedString(@"Stack Trace", @"");
        self.tabBarItem = [[[EDNavTabBarItem alloc] initWithTitle:self.title image:nil tag:0] autorelease];
        
        NSCell *cell = [[[EDTabBarStackTraceButtonCell alloc] init] autorelease];
        [self.tabBarItem.button setCell:cell];
        [self.tabBarItem.button setToolTip:self.title];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.delegate = nil;
    self.outlineView = nil;
    self.debugInfo = nil;
    [super dealloc];
}


- (void)viewDidLoad {
    EDAssertMainThread();
    EDAssert(_outlineView);
    EDAssert(_outlineView.dataSource == self);
    EDAssert(_outlineView.delegate == self);
    
    NSTableColumn *col = [_outlineView tableColumnWithIdentifier:@"displayPath"];
    [col setHidden:!MULTI_FILE_ENABLED];
}


#pragma mark -
#pragma mark Public

- (void)displayFrameStack:(NSArray *)stack {
    EDAssertMainThread();
    if (![stack count]) return;
    
    NSString *srcDirPath = [_delegate sourceDirPathForStackTraceViewController:self];
    NSUInteger prefixLen = [srcDirPath length];
    EDAssert(prefixLen);
    
    NSMutableArray *vec = [NSMutableArray arrayWithCapacity:[stack count]];
    
    NSUInteger idx = 0;
    for (XPStackFrame *frame in stack) {
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:3];
        
        NSString *absPath = [frame.filePath substringFromIndex:prefixLen];
        NSString *funcName = frame.functionName;
        NSString *lineNumStr = [NSString stringWithFormat:@"%ld", frame.lineNumber];

        EDAssert([absPath length]);
        EDAssert([funcName length]);
        EDAssert([lineNumStr length]);

        if (!absPath || !funcName || !lineNumStr) continue;
        
        d[@"absPath"] = absPath;
        d[@"displayPath"] = [absPath stringByAbbreviatingWithTildeInPath];
        d[@"lineNumber"] = lineNumStr;
        d[@"funcName"] = funcName;
        d[@"enabled"] = [frame.filePath hasPrefix:srcDirPath] ? @YES : @NO;
        d[@"index"] = [NSString stringWithFormat:@"%lu", idx++];
        
        [vec addObject:d];
    }
    
    self.debugInfo = [[vec copy] autorelease];
    [_outlineView reloadData];
    [_outlineView setEnabled:YES];
}


- (void)clearDebugInfo {
    EDAssertMainThread();
    self.debugInfo = nil;
    [_outlineView reloadData];
    [_outlineView setEnabled:NO];
}


- (void)displayContextMenu:(NSEvent *)evt {
    EDAssertMainThread();
//    EDAssert(_contextMenu);
    
}


#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    NSParameterAssert(!item);// || [item isKindOfClass:[NSString class]]);
    
    NSUInteger c = 0;
    
    if (!item) {
        c = [_debugInfo count];
//    } else if ([item isKindOfClass:[NSString class]]) {
//        c = [[_searchResults objectForKey:item] count]; // ???
    } else {
        EDAssert(0);
    }
    
    return c;
}


- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    BOOL result = NO;
    
//    if (!item) {
//        result = YES;
//    } else if ([item isKindOfClass:[NSString class]]) {
//        result = YES;
//    } else {
//        EDAssert([item isKindOfClass:[EDFileLocation class]]);
//        return NO;
//    }
    
    return result;
}


- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item {
    NSParameterAssert(!item); // || [item isKindOfClass:[NSString class]]);
    
    id result = nil;
    
    if (!item) {
        result = _debugInfo[idx];
//    } else if ([item isKindOfClass:[NSString class]]) {
//        result = [[_searchResults objectForKey:item] objectAtIndex:idx];
    } else {
        EDAssert(0);
    }
    
    return result;
}


- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)col byItem:(id)item {
    NSString *identifier = [col identifier];
    id result = nil;
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        result = item[identifier];
        
    } else {
        EDAssert(0);
    }
    
    return result;
}


#pragma mark -
#pragma mark NSOutlineDelegate

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item {
    EDAssertMainThread();
    EDAssert([item isKindOfClass:[NSDictionary class]]);

    if ([item[@"enabled"] boolValue]) {
        NSString *absPath = item[@"absPath"];
        NSUInteger lineNum = [item[@"lineNumber"] integerValue];
        NSUInteger idx = [item[@"index"] integerValue];
        
        EDFileLocation *fileLoc = [EDFileLocation fileLocationWithURLString:absPath lineNumber:lineNum];
        if (fileLoc) {
            TDPerformOnMainThreadAfterDelay(0.0, ^{
                [_delegate stackTraceViewController:self didActivateFileLocation:fileLoc stackFrameIndex:idx];
            });
        }
    }
    
    return YES;
}


- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)col item:(id)item {
    return NO;
}


// dear gods. why is this necessary???. I tried every other way to get this display style, but only this fucked idea worked.
- (void)outlineView:(NSOutlineView *)ov willDisplayCell:(NSTextFieldCell *)cell forTableColumn:(NSTableColumn *)col item:(id)item {

    EDAssertMainThread();
    EDAssert([item isKindOfClass:[NSDictionary class]]);
    EDAssert([cell isKindOfClass:[NSTextFieldCell class]]);
    
    BOOL enabled = [item[@"enabled"] boolValue];
    BOOL selected = [ov itemAtRow:[ov selectedRow]] == item;

    NSString *identifier = [col identifier];
    NSString *str = item[identifier];
    id attrs = nil;
    
    if (selected) {
        attrs = sSelAttrsTab[identifier];
    } else if (!enabled) {
        attrs = sDisAttrsTab[identifier];
    } else {
        attrs = sAttrsTab[identifier];
    }
    
    NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString:str attributes:attrs] autorelease];
    [cell setAttributedStringValue:attrStr];
}

@end
