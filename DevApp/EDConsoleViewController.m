//
//  EDConsoleViewController.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDConsoleViewController.h"
#import "EDConsoleContainerView.h"
#import "EDConsoleOutlineView.h"
#import "EDMainWindowController.h"
#import "EDThemeManager.h"
#import "EDTheme.h"
#import "EDHistory.h"
#import <OkudaKit/OKTextView.h>
#import <IDEKit/IDEUberView.h>
#import <TDAppKit/TDUtils.h>
#import <TDAppKit/NSEvent+TDAdditions.h>
#import <Language/XPStackFrame.h>

static NSDictionary *sNameAttrs = nil;
static NSDictionary *sValueAttrs = nil;

@interface EDConsoleViewController ()
@property (nonatomic, retain) NSArray *debugInfo;
@end

@implementation EDConsoleViewController

+ (void)initialize {
    if ([EDConsoleViewController class] == self) {
        
        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSLeftTextAlignment];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
        
        sNameAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName,
                       [NSColor blackColor], NSForegroundColorAttributeName,
                       paraStyle, NSParagraphStyleAttributeName,
                       nil];
        
        sValueAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                         [NSColor blackColor], NSForegroundColorAttributeName,
                         paraStyle, NSParagraphStyleAttributeName,
                         nil];
    }
}


- (id)init {
    self = [self initWithNibName:@"EDConsoleView" bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    self = [super initWithNibName:name bundle:b];
    if (self) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(debugLocalVariablesVisibleDidChange:) name:EDDebugLocalVariablesVisibleDidChangeNotification object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.delegate = nil;
	self.continueButton = nil;
	self.nextButton = nil;
	self.stepButton = nil;
	self.upButton = nil;
    self.varsContainerView = nil;
    self.varsOutlineView = nil;
    self.uberView = nil;
    self.debugInfo = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark TDViewController

- (void)viewDidLoad {
    EDAssertMainThread();
    EDAssert(_varsContainerView);
    EDAssert(_varsOutlineView);
    EDAssert(_varsOutlineView.dataSource == self);
    EDAssert(_varsOutlineView.delegate == self);
    
    EDConsoleContainerView *v = (id)[self view];
    EDAssert([v isKindOfClass:[EDConsoleContainerView class]]);
    
    self.sourceViewController = [[[OKViewController alloc] initWithDefaultNib] autorelease];
    self.sourceViewController.delegate = self;
    
    [self.sourceViewController loadView];
    self.sourceViewController.hasGutterView = NO;
    self.textView = self.sourceViewController.textView;
    
    CGRect uberRect = [v uberViewRectForBounds:[v bounds]];
    self.uberView = [[[IDEUberView alloc] initWithFrame:uberRect dividerStyle:NSSplitViewDividerStyleThin] autorelease];
    [_uberView setAutosaveName:@"consoleUberView"];
    [_uberView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [v addSubview:_uberView];
    v.uberView = _uberView;
    
    _uberView.midView = self.sourceViewController.view;
    
    _uberView.leftTopView = _varsContainerView;
    _uberView.preferredLeftSplitWidth = 360.0;
    
    [self clearDebugInfo];

    if ([[EDUserDefaults instance] debugLocalVariablesVisible]) {
        [_uberView openLeftTopView:nil];
    }

    [self updateThemeInVarsOutlineView];
}


#pragma mark -
#pragma mark Actions

- (IBAction)clear:(id)sender {
    EDAssert(self.textView);
    [self.textView setString:@""];
    
    if ([_delegate isConsolePaused:self] && ![[EDUserDefaults instance] suppressConsolePrompt]) {
        [self appendPrompt];
    }
}


- (IBAction)menuPrintValue:(id)sender {
    EDAssertMainThread();
    NSInteger idx = [_varsOutlineView selectedRow];
    EDAssert(idx >= 0);
    EDAssert(idx < [_debugInfo count]);
    
    NSDictionary *item = _debugInfo[idx];
    EDAssert(item);
    
    NSString *name = item[@"name"];
    EDAssert(name);
    NSString *value = item[@"value"];
    EDAssert(value);
    [self append:[NSString stringWithFormat:@"%@ = %@", name, value]];
    
    [self appendPrompt];
}


#pragma mark -
#pragma mark Notifications

- (void)debugLocalVariablesVisibleDidChange:(NSNotification *)n {
    EDAssertMainThread();
    EDAssert(_varsContainerView);

    BOOL visible = [[EDUserDefaults instance] debugLocalVariablesVisible];

    if (visible) {
        [_uberView openLeftTopView:nil];
    } else {
        [_uberView closeLeftTopView:nil];
    }
}


- (void)selectedThemeDidChange:(NSNotification *)n {
    [super selectedThemeDidChange:n];
    [self updateThemeInVarsOutlineView];
}


- (void)updateThemeInVarsOutlineView {
    EDAssertMainThread();
    EDAssert(_varsOutlineView);
    
    CGFloat fontSize = [[EDUserDefaults instance] selectedFontSize];
    CGFloat padding = fontSize / 2.0;
    [_varsOutlineView setRowHeight:fontSize + padding];
    
    EDTheme *theme = [[EDThemeManager instance] selectedTheme];
    EDAssert(theme);
    
    NSDictionary *defaultAttrs = theme.attributes[@".default"];
    EDAssert([defaultAttrs count]);
    
    NSColor *bgColor = defaultAttrs[NSBackgroundColorAttributeName];
    EDAssert(bgColor);
    [_varsOutlineView setBackgroundColor:bgColor];
    
    // unfortunately, all this BS is necessary or else the scroll view in the OKVC will get borked.
    [(TDColorView *)[self view] setColor:bgColor];

    NSDictionary *selAttrs = theme.attributes[@".selection"];
    EDAssert([selAttrs count]);
    
    NSColor *selColor = selAttrs[NSBackgroundColorAttributeName];
    EDAssert(selColor);
    [_varsOutlineView setSelectionColor:selColor];
    [_varsOutlineView setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark Public


- (void)append:(NSString *)msg {
    // don't append a new prompt if already at prompt
    NSString *trimmedMsg = [msg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *currPrompt = nil;
    if ([self.prompts[0] isEqualToString:trimmedMsg] && [self isAtPrompt:&currPrompt] && [self.prompts[0] isEqualToString:currPrompt]) {
        return;
    }
    
    [super append:msg];
}


- (NSArray *)prompts {
    return @[[_delegate promptForConsole:self]];
}


- (void)handleUserCommand:(NSString *)cmd {
    [super handleUserCommand:cmd];
    EDAssert(_delegate)
    
    if (![cmd length]) {
        cmd = [self.history current];
    }
    [_delegate console:self userIssuedCommand:cmd];
}


- (void)displayStackFrame:(XPStackFrame *)frame {
    EDAssertMainThread();
    
    NSMutableArray *info = [NSMutableArray arrayWithCapacity:[frame.sortedLocalNames count]];
    
    NSUInteger i = 0;
    TDAssert([frame.sortedLocalNames count] == [frame.sortedLocalValues count]);
    for (NSString *name in frame.sortedLocalNames) {
        id val = frame.sortedLocalValues[i++];
        
        id tab = @{@"name": name, @"value": val};
        [info addObject:tab];
    }
    
    self.debugInfo = info;
    
    [_varsOutlineView reloadData];
    [_varsOutlineView setEnabled:YES];
}


- (void)clearDebugInfo {
    EDAssertMainThread();
    self.debugInfo = nil;
    [_varsOutlineView reloadData];
    [_varsOutlineView setEnabled:NO];
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
    //NSString *identifier = [col identifier];
    
    id result = nil;
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        NSString *name = item[@"name"];
        NSString *value = item[@"value"];
        EDAssert(name);
        EDAssert(value);
        
        NSString *str = [NSString stringWithFormat:@"%@ = %@", name, value];
        
        result = [_delegate console:self highlightedStringForString:str];
        
        // make name bold
        NSFont *font = [result attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
        font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSFontBoldTrait];
        [result addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [name length])];
        
        // remove bg color (so selection hilight shows thru)
        [result removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0, [result length])];
        
//    } else {
//        EDAssert([item isKindOfClass:[EDFileLocation class]]);
//        if (isTitle) {
//            result = [item preview];
//        } else {
//            result = @([item selected]);
//        }
    }
    
    return result;
}


#pragma mark -
#pragma mark NSOutlineViewDelegate

- (void)outlineView:(NSOutlineView *)ov sortDescriptorsDidChange:(NSArray *)oldDesc {
    NSArray *descs = [ov sortDescriptors];
    self.debugInfo = [_debugInfo sortedArrayUsingDescriptors:descs];
    [ov reloadData];
    [ov selectColumnIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    [ov setFocusedColumn:-1];
}


#pragma mark -
#pragma mark Right Click

- (void)displayContextMenu:(NSEvent *)evt {
    EDAssertMainThread();
    EDAssert(_contextMenu);
    EDAssert(_varsOutlineView);
    
    [[[self view] window] makeFirstResponder:_varsOutlineView];
    
    CGPoint locInView = [_varsOutlineView convertPoint:[evt locationInWindow] fromView:nil];
    NSInteger row = [_varsOutlineView rowAtPoint:locInView];
    if (row > -1 && ![[_varsOutlineView selectedRowIndexes] containsIndex:row]) {
        [_varsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
        
    NSEvent *click = [NSEvent mouseEventWithType:[evt type]
                                        location:[evt locationInWindow]
                                   modifierFlags:[evt modifierFlags]
                                       timestamp:[evt timestamp]
                                    windowNumber:[evt windowNumber]
                                         context:[evt context]
                                     eventNumber:[evt eventNumber]
                                      clickCount:[evt clickCount]
                                        pressure:[evt pressure]];
    
    [NSMenu popUpContextMenu:_contextMenu withEvent:click forView:_varsOutlineView];
}

@end
