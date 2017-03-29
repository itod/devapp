//
//  EDBreakpointListViewController.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDBreakpointListViewController.h"
#import "EDTabBarBreakpointButtonCell.h"
#import "EDNavTabBarItem.h"
#import "EDUtils.h"
#import "EDBreakpointCollection.h"
#import <OkudaKit/OKBreakpoint.h>
#import <TDAppKit/TDUtils.h>
#import <TDAppKit/TDTabBarItem.h>

#define ICON_ID @"icon"
#define NAME_ID @"name"

#define TAG_TOGGLE_SEP 1035
#define TAG_TOGGLE 1040

#define TAG_DELETE_SEP 1045
#define TAG_DELETE 1050

@interface EDBreakpointListViewController ()

@end

@implementation EDBreakpointListViewController

- (id)init {
    self = [self initWithNibName:@"EDBreakpointListView" bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    self = [super initWithNibName:name bundle:b];
    if (self) {
        self.title = NSLocalizedString(@"Breakpoints", @"");
        self.tabBarItem = [[[EDNavTabBarItem alloc] initWithTitle:self.title image:nil tag:0] autorelease];
        
        NSCell *cell = [[[EDTabBarBreakpointButtonCell alloc] init] autorelease];
        [self.tabBarItem.button setCell:cell];
        [self.tabBarItem.button setToolTip:self.title];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.delegate = nil;
    self.outlineView = nil;
    self.contextMenu = nil;
    self.collection = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark TDViewController

- (void)viewDidLoad {
    EDAssert(_outlineView);
    EDAssert(_outlineView.delegate == self);
    EDAssert(_outlineView.dataSource == self);
    EDAssert(_collection);

    [_outlineView expandItem:nil expandChildren:YES];
}


- (void)viewWillAppear:(BOOL)animated {
    [self reloadData];
}


#pragma mark -
#pragma mark Notifications

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    NSWindow *win = [[self view] window];
    if (win) {
        id doc = [[win windowController] document];
        EDAssert(doc);
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:win];
        [nc addObserver:self selector:@selector(breakpointsDidChange:) name:EDBreakpointsDidChangeNotification object:doc];
    }
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    [self reloadData];
}


- (void)breakpointsDidChange:(NSNotification *)n {
    [self reloadData];
    [_outlineView expandItem:nil expandChildren:YES];
}


#pragma mark -
#pragma mark Actions

- (IBAction)menuToggleEnabled:(id)sender {
    EDAssertMainThread();
    
    NSArray *bps = [self selectedBreakpoints];
    EDAssert([bps count]);
    
    BOOL disable = [self selectionWantsDisable];

    for (OKBreakpoint *bp in bps) {
        bp.enabled = !disable;
    }
    
    [self fireBreakpointsDidChange];
}


- (IBAction)menuDelete:(id)sender {
    EDAssertMainThread();
    
    NSArray *bps = [self selectedBreakpoints];
    EDAssert([bps count]);
    for (OKBreakpoint *bp in bps) {
        [_collection removeBreakpoint:bp];
    }
    
    [self fireBreakpointsDidChange];
    [self reloadData];
    [_outlineView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}


- (void)fireBreakpointsDidChange {
    id doc = [[[[self view] window] windowController] document];
    EDAssert(doc);

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:EDBreakpointsDidChangeNotification object:doc];
}


#pragma mark -
#pragma mark Public

- (void)reloadData {
    EDAssertMainThread();
    [_outlineView reloadData];
    [_outlineView expandItem:nil expandChildren:YES];
}


#pragma mark -
#pragma mark Private

// multiple selection
- (NSArray *)selectedBreakpoints {
    EDAssertMainThread();
    NSIndexSet *set = [_outlineView selectedRowIndexes];
    NSMutableArray *bps = [NSMutableArray arrayWithCapacity:[set count]];
    
    NSUInteger row = [set firstIndex];
    while (NSNotFound != row) {
        OKBreakpoint *bp = [_outlineView itemAtRow:row];
        EDAssert([bp isKindOfClass:[OKBreakpoint class]]);
        [bps addObject:bp];
        row = [set indexGreaterThanIndex:row];
    }
    
    return bps;
}


- (OKBreakpoint *)selectedBreakpoint {
    EDAssertMainThread();
    OKBreakpoint *bp = nil;
    
    NSInteger row = [_outlineView selectedRow];
    if (row > -1) {
        bp = [_outlineView itemAtRow:row];
        EDAssert([bp isKindOfClass:[OKBreakpoint class]]);
    }
    
    return bp;
}


#pragma mark -
#pragma mark Right Click

- (void)displayContextMenu:(NSEvent *)evt {
    EDAssertMainThread();
    EDAssert(_contextMenu);
    EDAssert(_outlineView);
    
    [[[self view] window] makeFirstResponder:_outlineView];

    CGPoint locInView = [_outlineView convertPoint:[evt locationInWindow] fromView:nil];
    NSInteger row = [_outlineView rowAtPoint:locInView];
    if (row > -1 && ![[_outlineView selectedRowIndexes] containsIndex:row]) {
        [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }

    [self contextMenuNeedsUpdate:_contextMenu];
    
    NSEvent *click = [NSEvent mouseEventWithType:[evt type]
                                        location:[evt locationInWindow]
                                   modifierFlags:[evt modifierFlags]
                                       timestamp:[evt timestamp]
                                    windowNumber:[evt windowNumber]
                                         context:[evt context]
                                     eventNumber:[evt eventNumber]
                                      clickCount:[evt clickCount]
                                        pressure:[evt pressure]];
    
    [NSMenu popUpContextMenu:_contextMenu withEvent:click forView:_outlineView];
}


#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    NSParameterAssert(!item || [item isKindOfClass:[NSString class]]);

    NSUInteger c = 0;

#if MULTI_FILE_ENABLED
    if (!item) {
        c = [[_collection allFiles] count];
    } else if ([item isKindOfClass:[NSString class]]) {
        c = [[_collection breakpointsForFile:item] count];
    } else {
        EDAssert(0);
    }
#else
    if (!item) {
        c = [[_collection breakpointsForFile:[[_collection allFiles] objectAtIndex:0]] count];
    } else {
        EDAssert(0);
    }
#endif

    return c;
}


- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    BOOL result = NO;

    if (!item) {
        result = YES;
    } else if ([item isKindOfClass:[NSString class]]) {
        result = YES;
    } else {
        EDAssert([item isKindOfClass:[OKBreakpoint class]]);
        return NO;
    }
    
    return result;
}


- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item {
    NSParameterAssert(!item || [item isKindOfClass:[NSString class]]);

    id result = nil;

#if MULTI_FILE_ENABLED
    if (!item) {
        result = [[_collection allFiles] objectAtIndex:idx];
    } else if ([item isKindOfClass:[NSString class]]) {
        result = [[_collection sortedBreakpointsForFile:item] objectAtIndex:idx];
    } else {
        EDAssert(0);
    }
#else
    if (!item) {
        result = [[_collection sortedBreakpointsForFile:[[_collection allFiles] objectAtIndex:0]] objectAtIndex:idx];
    } else {
        EDAssert(0);
    }
#endif

    return result;
}


- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)col byItem:(id)item {
    NSString *identifier = [col identifier];
    BOOL isName = [identifier isEqualToString:@"name"];
    
    id result = nil;
    
    if ([item isKindOfClass:[NSString class]]) {
        if (isName) {
            result = item;
        } else {
            result = nil;
        }
    } else {
        EDAssert([item isKindOfClass:[OKBreakpoint class]]);
        if (isName) {
            result = item;
        } else {
            result = @([item enabled]);
        }
    }
    
    return result;
}


- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)enabled forTableColumn:(NSTableColumn *)col byItem:(id)item {
    NSString *identifier = [col identifier];
    BOOL isIcon = [identifier isEqualToString:@"icon"];
    
    if (isIcon && [item isKindOfClass:[OKBreakpoint class]]) {
        [item setEnabled:[enabled boolValue]];

        [self fireBreakpointsDidChange];
    }
}


- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)data {
    id item = EDPlistFromData(data, nil);
    
    EDAssert([item isKindOfClass:[NSString class]] || [item isKindOfClass:[OKBreakpoint class]]);
    
    return item;
}


- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
    EDAssert([item isKindOfClass:[NSString class]] || [item isKindOfClass:[OKBreakpoint class]]);

    NSData *data = nil;
    if ([item isKindOfClass:[NSString class]]) {
        data = [item dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        data = EDDataFromPlist([item asPlist], nil);
    }
    
    EDAssert([data length]);
    
    return data;
}


#pragma mark -
#pragma mark NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item {
    EDAssertMainThread();
    
    BOOL result = NO;
    NSString *path = nil;
    if ([item isKindOfClass:[OKBreakpoint class]]) {
        path = [item file];
        result = YES;

        EDAssert([path length]);
        EDAssert(_delegate);
        [_delegate breakpointListViewController:self didActivateFileAtPath:path lineNumber:[item lineNumber]];
    }
    
    self.hasSelection = result;
    return result;
}


- (void)outlineView:(NSOutlineView *)ov willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)col item:(id)item {
    NSString *identifier = [col identifier];
    BOOL isIcon = [identifier isEqualToString:@"icon"];
    
    if (isIcon) {
        [cell setTransparent:[item isKindOfClass:[NSString class]]];
    }
}


- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)col item:(id)item {
    return NO;
}


#pragma mark -
#pragma mark NSMenuDelegate

- (BOOL)selectionWantsDisable {
    NSArray *bps = [self selectedBreakpoints];

    BOOL disable = NO;
    for (OKBreakpoint *bp in bps) {
        if (bp.enabled) {
            disable = YES;
            break;
        }
    }
    return disable;
}


- (void)contextMenuNeedsUpdate:(NSMenu *)menu {
    OKBreakpoint *bp = [self selectedBreakpoint];
    
    BOOL hasSelection = bp != nil;
    BOOL disable = [self selectionWantsDisable];

//    EDAssert([menu itemWithTag:TAG_TOGGLE_SEP]);
//    [[menu itemWithTag:TAG_TOGGLE_SEP] setHidden:!hasSelection];
    
    EDAssert([menu itemWithTag:TAG_TOGGLE]);
    [[menu itemWithTag:TAG_TOGGLE] setHidden:!hasSelection];
    [[menu itemWithTag:TAG_TOGGLE] setTitle:disable ? NSLocalizedString(@"Disable", @"") : NSLocalizedString(@"Enable", @"")];

    EDAssert([menu itemWithTag:TAG_DELETE_SEP]);
    [[menu itemWithTag:TAG_DELETE_SEP] setHidden:!hasSelection];
    
    EDAssert([menu itemWithTag:TAG_DELETE]);
    [[menu itemWithTag:TAG_DELETE] setHidden:!hasSelection];
}


- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _contextMenu) {
        [self contextMenuNeedsUpdate:menu];
    }
}

@end
