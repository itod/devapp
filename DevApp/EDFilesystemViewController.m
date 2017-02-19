//
//  EDFilesystemViewController.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFilesystemViewController.h"
#import "EDFilesystemItem.h"
#import "EDFilesystemItemCell.h"
#import "EDTabBarFilesystemButtonCell.h"
#import "EDNavTabBarItem.h"
#import "EDUtils.h"
#import <TDAppKit/TDUtils.h>
#import <TDAppKit/TDTabBarItem.h>
#import <TDAppKit/NSEvent+TDAdditions.h>

#define ICON_ID @"icon"
#define NAME_ID @"name"

#define TAG_PWD 1
#define TAG_PROJ_ROOT 5
#define TAG_COMPUTER 10
#define TAG_HOME 20
#define TAG_DESKTOP 30
#define TAG_DOCUMENTS 40

#define TAG_NEW_FILE 1000
#define TAG_NEW_FOLDER 1004
#define TAG_OPEN_SEP 1005
#define TAG_OPEN 1010
#define TAG_OPEN_WITH 1020
#define TAG_RENAME 1030
#define TAG_REVEAL 1040
#define TAG_DELETE_SEP 1045
#define TAG_DELETE 1050

@interface EDFilesystemItem ()
@property (nonatomic, copy, readwrite) NSString *fullPath;
@property (nonatomic, copy, readwrite) NSString *relativePath;
@property (nonatomic, retain, readwrite) NSMutableArray *children;
@property (nonatomic, retain, readwrite) NSImage *icon;
@end

@interface EDFilesystemViewController ()

@end

@implementation EDFilesystemViewController

- (id)init {
    self = [self initWithNibName:@"EDFilesystemView" bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    self = [super initWithNibName:name bundle:b];
    if (self) {
        self.title = NSLocalizedString(@"Project", @"");
        self.tabBarItem = [[[EDNavTabBarItem alloc] initWithTitle:self.title image:nil tag:0] autorelease];
        
        NSCell *cell = [[[EDTabBarFilesystemButtonCell alloc] init] autorelease];
        [self.tabBarItem.button setCell:cell];
        [self.tabBarItem.button setToolTip:self.title];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.outlineView = nil;
    self.actionPopUpButtonMenu = nil;
    self.navPopUpButton = nil;
    self.navPopUpButtonMenu = nil;
    self.delegate = nil;
    self.projItem = nil;
    self.sourceDirItem = nil;
    self.pwdItem = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark TDViewController

- (void)viewDidLoad {
    EDAssert([self view]);
    EDAssert(_outlineView);
    EDAssert(_outlineView.delegate == self);
    EDAssert(_outlineView.dataSource == self);

    [self setUpDragAndDrop];
    
    [_outlineView setAllowsMultipleSelection:NO]; // ??
    
    [self updateNavBar];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(viewDidMoveToWindow:) name:TDViewControllerViewDidMoveToWindowNotification object:[self view]];
}


- (void)viewDidMoveToWindow:(NSNotification *)n {
    EDAssertMainThread();
    NSWindow *win = [[self view] window];
    if (win) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:win];
    }
}


#pragma mark -
#pragma mark Notifications

- (void)windowDidBecomeMain:(NSNotification *)n {
    [self reloadData];
}


#pragma mark -
#pragma mark Actions

- (IBAction)menuNavigate:(id)sender {
    EDAssertMainThread();
    EDAssert(_navPopUpButton);
    EDAssert(sender == _navPopUpButton);
    
    NSMenuItem *item = [_navPopUpButton selectedItem];
    NSString *path = [item representedObject];
    EDAssert([path isKindOfClass:[NSString class]]);
    EDAssert([path length]);
    
    path = [path stringByExpandingTildeInPath];
    [self changeDir:path];
}


- (IBAction)menuNewFile:(id)sender {
    EDFilesystemItem *fsItem = [self selectedFilesystemItem];
    
    if (!fsItem) fsItem = _pwdItem;
    
    NSString *absPath = fsItem.fullPath;
    
    if (fsItem.isLeaf) {
        absPath = [absPath stringByDeletingLastPathComponent];
    }
    
    [_delegate filesystemViewController:self wantsNewFileInDirPath:absPath];
}


- (IBAction)menuNewFolder:(id)sender {
    EDFilesystemItem *parentItem = [self selectedFilesystemItem];
    
    NSString *parentPath = nil;
    
    if (!parentItem) {
        parentItem = _pwdItem;
        parentPath = parentItem.fullPath;
    } else if (parentItem.isLeaf) {
        parentPath = [parentItem.fullPath stringByDeletingLastPathComponent];
        parentItem = [_pwdItem descendantAtFullPath:parentPath];
    } else {
        parentPath = parentItem.fullPath;
        parentItem = [_pwdItem descendantAtFullPath:parentPath];
    }

    EDAssert(parentItem);
    [_outlineView expandItem:parentItem];

    EDAssert(parentItem);
    EDAssert([parentPath length]);
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSUInteger i = 1;
    NSString *childName = NSLocalizedString(@"Untitled Folder", @"");
    NSString *childPath = [parentPath stringByAppendingPathComponent:childName];
    
    while ([mgr fileExistsAtPath:childPath]) {
        childName = [NSString stringWithFormat:NSLocalizedString(@"Untitled Folder %lu", @""), i++];
        childPath = [parentPath stringByAppendingPathComponent:childName];
    }
    
    NSError *err = nil;
    if (![mgr createDirectoryAtPath:childPath withIntermediateDirectories:NO attributes:nil error:&err]) {
        if (err) NSLog(@"%@", err);
    }
    
    // rebuild filesystem tree. also reloads data
    EDAssert(parentItem);
    [parentItem reloadChildren];
    [_outlineView reloadData];

    [_outlineView expandItem:parentItem];

    EDAssert(parentItem == _pwdItem || [_outlineView isItemExpanded:parentItem]);
    NSInteger colIdx = [_outlineView columnWithIdentifier:NAME_ID];
    
    EDFilesystemItem *childItem = [_pwdItem descendantAtFullPath:childPath];
    EDAssert(childItem);
    
    [_outlineView expandItem:childItem];

    NSInteger rowIdx = [_outlineView rowForItem:childItem];
    EDAssert(rowIdx > -1);
    
    if (rowIdx > -1) {
        [_outlineView editColumn:colIdx row:rowIdx withEvent:[[_outlineView window] currentEvent] select:YES];
    }
}


- (IBAction)menuOpen:(id)sender {
    EDFilesystemItem *fsItem = [self selectedFilesystemItem];
    EDAssert(fsItem);
    if (!fsItem) return;
    
    BOOL isDir = !fsItem.isLeaf;
    if (isDir) {
        [self changeDir:fsItem.fullPath];
    } else {
        [_delegate filesystemViewController:self didActivateItemAtPath:fsItem.fullPath];
    }
}


- (IBAction)menuOpenWith:(id)sender {
    EDFilesystemItem *fsItem = [self selectedFilesystemItem];
    EDAssert(fsItem);
    if (!fsItem) return;
    
    EDAssert(fsItem.isLeaf);
    if (!fsItem.isLeaf) return;

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSWindow *win = [[self view] window];
        
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES);
    if ([paths count]) {
        NSString *appDirPath = paths[0];
        NSURL *appDirFurl = [NSURL fileURLWithPath:appDirPath];
        [panel setDirectoryURL:appDirFurl];
    }
    
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowedFileTypes:@[@"app"]];
    
    [panel beginSheetModalForWindow:win completionHandler:^(NSInteger result) {
        if (NSOKButton == result) {
            NSString *appPath = [[panel URL] relativePath];
            
            [[NSWorkspace sharedWorkspace] openFile:fsItem.fullPath withApplication:appPath andDeactivate:YES];
        }
    }];
}


- (IBAction)menuRename:(id)sender {
    EDAssertMainThread()
    NSInteger rowIdx = [_outlineView selectedRow];
    EDAssert(rowIdx > -1);
    if (rowIdx < 0) return;
    
    NSInteger colIdx = [_outlineView columnWithIdentifier:NAME_ID];
    EDAssert(colIdx > -1);
    if (colIdx < 0) return;
    
    [_outlineView editColumn:colIdx row:rowIdx withEvent:[[_outlineView window] currentEvent] select:YES];
    
//    NSText *fieldEditor = [_outlineView currentEditor];
//    NSString *str = [fieldEditor string];
//    NSString *ext = [str pathExtension];
//    NSUInteger extLen = [ext length];
//    if (extLen) {
//        NSRange r = [str rangeOfString:ext options:NSBackwardsSearch];
//
//        EDAssert(r.length);
//        EDAssert(NSNotFound != r.location);
//        EDAssert(r.location > 0);
//        
//        if (r.length && r.location != NSNotFound && r.location > 1) {
//            r.location -= 1;
//            r.length += 1;
//            
//            [fieldEditor setSelectedRange:NSMakeRange(0, [str length] - r.length)];
//        }
//    }
}


- (IBAction)menuDelete:(id)sender {
    EDFilesystemItem *fsItem = [self selectedFilesystemItem];
    EDAssert(fsItem);
    if (!fsItem) return;
    
    BOOL isDir = !fsItem.isLeaf;
    
    NSString *filename = fsItem.relativePath;
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Delete “%@”?", @""), filename];
    NSString *msg = nil;
    
    if (isDir) {
        msg = NSLocalizedString(@"Are you sure you want to delete the folder “%@”? The folder and all of its contents will be moved to the trash.", @"");
    } else {
        msg = NSLocalizedString(@"Are you sure you want to delete “%@”? The file will be moved to the trash.", @"");
    }
    
    NSString *delete = NSLocalizedString(@"Delete", @"");
    NSString *cancel = NSLocalizedString(@"Cancel", @"");

    NSInteger returnCode = NSRunAlertPanel(title, msg, cancel, delete, nil, filename);
    if (NSAlertAlternateReturn == returnCode) {
        
        NSFileManager *mgr = [NSFileManager defaultManager];
        
        NSString *oldFullPath = fsItem.fullPath;
        
        NSError *err = nil;
        NSURL *srcURL = [NSURL fileURLWithPath:oldFullPath];
        if (![mgr trashItemAtURL:srcURL resultingItemURL:nil error:&err]) {
            if (err) NSLog(@"%@", err);
        }
        
        [self reloadData];
        
        EDFilesystemItem *fsItem = [self selectedFilesystemItem];
        EDAssert(![oldFullPath isEqualToString:fsItem.fullPath]);
        if (fsItem.isLeaf) {
            [_delegate filesystemViewController:self didDeleteItemAtPath:oldFullPath andActivateItemAtPath:fsItem.fullPath];
        }
    }
}


- (IBAction)menuRevealInFinder:(id)sender {
    EDFilesystemItem *fsItem = [self selectedFilesystemItem];
    EDAssert(fsItem);
    if (!fsItem) return;

    [[NSWorkspace sharedWorkspace] selectFile:fsItem.fullPath inFileViewerRootedAtPath:@""];
}


#pragma mark -
#pragma mark Public

- (void)changeDir:(NSString *)dirPath {
    NSParameterAssert([dirPath length]);
    EDAssertMainThread();

    self.pwdItem = [EDFilesystemItem itemWithFullPath:dirPath];
    EDAssert(_pwdItem);
    
    if (!_sourceDirItem) {
        self.sourceDirItem = _pwdItem;
        
        self.projItem = [EDFilesystemItem itemWithFullPath:EDProjectSettingsURL];
        EDAssert(_projItem);
        _projItem.children = (id)@[_sourceDirItem];
    }
    
    //EDAssert([self isViewLoaded]);
    if ([self isViewLoaded]) {
        [_outlineView reloadData];
        [self updateNavBar];
    }
    
    EDAssert(_pwdItem);
    EDAssert(_sourceDirItem);
    EDAssert(_projItem);
}


- (void)selectItemAtPath:(NSString *)fullPath {
    EDAssertMainThread();
    if (!_sourceDirItem) return;
    
    EDAssert(_outlineView);
    EDAssert(_projItem);
    EDAssert(_sourceDirItem);
    
    [_outlineView expandItem:nil];
    [_outlineView expandItem:_sourceDirItem];
    
    if (!fullPath) {
        [_outlineView deselectAll:nil];
    } else {
        NSString *srcDirPath = _sourceDirItem.fullPath;
        
        if (![_sourceDirItem isEqual:_pwdItem]) {
            [self changeDir:srcDirPath];
        }
        
        EDFilesystemItem *fsItem = nil;

        if ([EDProjectSettingsURL isEqualToString:fullPath]) {
            fsItem = _sourceDirItem;
        } else {
            fsItem = [_sourceDirItem descendantAtFullPath:fullPath];
        }
        
        if (fsItem) {
            // First, expand the ancestor path to the selected item.
            
// unfortunately, -parentForItem: returns nil. dunno why. that would have been easier.
//                id item = fsItem;
//                do {
//                    [_outlineView expandItem:item];
//                    item = [_outlineView parentForItem:item];
//                } while (item);

            NSString *itemAbsPath = fsItem.fullPath;
            EDAssert([itemAbsPath hasPrefix:srcDirPath]);
            
            if ([itemAbsPath hasPrefix:srcDirPath]) {
                NSString *itemRelPath = [[itemAbsPath substringFromIndex:[srcDirPath length]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
                EDAssert(![itemRelPath isAbsolutePath]);
                NSArray *comps = [itemRelPath pathComponents];

                NSString *currAbsPath = srcDirPath;
                for (NSString *comp in comps) {
                    currAbsPath = [currAbsPath stringByAppendingPathComponent:comp];
                    id item = [_sourceDirItem descendantAtFullPath:currAbsPath];
                    [_outlineView expandItem:item];
                }
            }
            
            NSInteger rowIdx = [_outlineView rowForItem:fsItem];
            EDAssert(rowIdx > -1);
            
            if (rowIdx > -1) {
                [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIdx] byExtendingSelection:NO];
            }
        }
    }
}


- (void)reloadItemAtPath:(NSString *)fullPath {
    EDAssertMainThread();
    if (!_sourceDirItem) return;
    
    if (!fullPath) {
        [_outlineView deselectAll:nil];
    } else {
        if (![_sourceDirItem isEqual:_pwdItem]) {
            [self changeDir:_sourceDirItem.fullPath];
        }
        
        EDFilesystemItem *fsItem = [_sourceDirItem descendantAtFullPath:fullPath];
        if (fsItem) {
            [_outlineView reloadItem:fsItem];
        }
    }
}


- (void)reloadData {
    EDAssertMainThread();
//    EDAssert(_pwdItem);
    EDAssert(_outlineView);
    
    [_pwdItem reloadChildren];
    [_outlineView reloadData];
}


#pragma mark -
#pragma mark Private

- (void)updateNavBar {
    EDAssert(_navPopUpButton);
    EDAssert(_navPopUpButtonMenu);
    
    if (!_pwdItem) return;

    //[_navPopUpButtonMenu update]; // has no effect
    [self navPopUpButtonMenuNeedsUpdate:_navPopUpButtonMenu];

    [_navPopUpButton synchronizeTitleAndSelectedItem];
}


// multiple selection
- (NSArray *)selectedFilesystemItems {
    NSIndexSet *set = [_outlineView selectedRowIndexes];
    NSMutableArray *fsItems = [NSMutableArray arrayWithCapacity:[set count]];

    NSUInteger row = [set firstIndex];
    while (NSNotFound != row) {
        EDFilesystemItem *fsItem = [_outlineView itemAtRow:row];
        EDAssert(fsItem);
        [fsItems addObject:fsItem];
        row = [set indexGreaterThanIndex:row];
    }
    
    return fsItems;
}


- (NSArray *)filesystemItemsAtRows:(NSIndexSet *)rows {
    NSMutableArray *v = [NSMutableArray arrayWithCapacity:[rows count]];
    
    NSUInteger row = [rows firstIndex];
    while (NSNotFound != row) {
        EDFilesystemItem *fsItem = [_outlineView itemAtRow:row];
        EDAssert([fsItem isKindOfClass:[EDFilesystemItem class]]);
        
        [v addObject:fsItem];
        row = [rows indexGreaterThanIndex:row];
    }
    
    return v;
}


- (EDFilesystemItem *)selectedFilesystemItem {
    EDFilesystemItem *fsItem = nil;

    NSInteger row = [_outlineView selectedRow];
    if (row > -1) {
        fsItem = [_outlineView itemAtRow:row];
    }

    return fsItem;
}


#pragma mark -
#pragma mark Right Click

- (void)displayContextMenu:(NSEvent *)evt {
    EDAssertMainThread();
    EDAssert(_actionPopUpButtonMenu);
    EDAssert(_outlineView);
    
    [[[self view] window] makeFirstResponder:_outlineView];
    
    CGPoint locInView = [_outlineView convertPoint:[evt locationInWindow] fromView:nil];
    NSInteger row = [_outlineView rowAtPoint:locInView];
    if (row > -1) {
        if (![[_outlineView selectedRowIndexes] containsIndex:row]) {
            [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        }

        EDFilesystemItem *item = [self selectedFilesystemItem];
        if ([item isLeaf]) {
            [_delegate filesystemViewController:self didActivateItemAtPath:[item fullPath]];
        }
    }

    [self actionPopUpButtonMenuNeedsUpdate:_actionPopUpButtonMenu];
    
    NSEvent *click = [NSEvent mouseEventWithType:[evt type]
                                        location:[evt locationInWindow]
                                   modifierFlags:[evt modifierFlags]
                                       timestamp:[evt timestamp]
                                    windowNumber:[evt windowNumber]
                                         context:[evt context]
                                     eventNumber:[evt eventNumber]
                                      clickCount:[evt clickCount]
                                        pressure:[evt pressure]];
    
    [NSMenu popUpContextMenu:_actionPopUpButtonMenu withEvent:click forView:_outlineView];
}


#pragma mark -
#pragma mark Drag and Drop

- (void)setUpDragAndDrop {
//    // drag source
    [_outlineView setDraggingSourceOperationMask:NSDragOperationMove|NSDragOperationCopy forLocal:YES];
    [_outlineView setDraggingSourceOperationMask:NSDragOperationNone forLocal:NO];
//    [_outlineView setVerticalMotionCanBeginDrag:YES];
//

    // drag dest
    [_outlineView registerForDraggedTypes:@[[EDFilesystemItem pasteboardType]]];
}


//- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rows atPoint:(NSPoint)p {
//    BOOL result = YES;
//    
//    NSArray *fsItems = [self filesystemItemsAtRows:rows];
//    for (EDFilesystemItem *fsItem in fsItems) {
//        if ([[fsItem.fullPath lastPathComponent] isEqualToString:@"main.py"]) {
//            result = NO;
//            break;
//        }
//    }
//    
//    return result;
//}


- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    BOOL dragOK = YES;

    for (EDFilesystemItem *fsItem in items) {
        if ([[fsItem.fullPath lastPathComponent] isEqualToString:@"main.py"]) {
            dragOK = NO;
            break;
        }
    }
    
    if (dragOK) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:items];
        [pboard setData:data forType:[EDFilesystemItem pasteboardType]];
    }

    return dragOK;
}


- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)destItem proposedChildIndex:(NSInteger)index {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    EDAssertMainThread();
    if (destItem == _projItem) {
        destItem = _pwdItem;
    }
    destItem = destItem ? destItem : _pwdItem;

    EDAssert([destItem isKindOfClass:[EDFilesystemItem class]]);
    BOOL dropOK = ![destItem isLeaf];
    
    NSDragOperation op = NSDragOperationNone;
    
    if (dropOK) {
        NSEvent *evt = [[_outlineView window] currentEvent];
        BOOL isOpt = [evt isOptionKeyPressed];
        op = isOpt ? NSDragOperationCopy : NSDragOperationMove;
    }

    return op;
}


- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)destItem childIndex:(NSInteger)destChildIdx {
    //NSLog(@"%s item: %@, index %ld", __PRETTY_FUNCTION__, destItem, destChildIdx);

    EDAssertMainThread();
    
    [self selectItemAtPath:_pwdItem.fullPath];
    
    if (destItem == _projItem) {
        destItem = _pwdItem;
    }
    destItem = destItem ? destItem : _pwdItem;
    EDAssert(destItem);
    EDAssert(![destItem isLeaf]);

    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *data = [pboard dataForType:[EDFilesystemItem pasteboardType]];
    EDAssert([data isKindOfClass:[NSData class]]);
    
    NSArray *items = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    EDAssert([items isKindOfClass:[NSArray class]]);
    
    BOOL success = YES;

    // dunno why this doesn't work
//    BOOL isCopy = (NSDragOperationCopy & [info draggingSourceOperationMask]);
    
    NSEvent *evt = [[_outlineView window] currentEvent];
    BOOL isCopy = [evt isOptionKeyPressed];
    
    NSString *newSelPath = nil;
    for (EDFilesystemItem *srcItem in items) {
        EDAssert([srcItem isKindOfClass:[EDFilesystemItem class]]);
        
        NSString *srcPath = srcItem.fullPath;
        NSString *destFilename = [srcPath lastPathComponent];
        NSString *destPath = [[destItem fullPath] stringByAppendingPathComponent:destFilename];
        if (!newSelPath) newSelPath = destPath;
        
        if (isCopy) {
            success = [self copyItem:srcItem fromPath:srcPath toPath:destPath];
        } else {
            success = [self moveItem:srcItem fromPath:srcPath toPath:destPath];
        }
        if (!success) break;
    }
    
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        [self reloadData];
        [self selectItemAtPath:newSelPath];
    });
    
    return success;
}


#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    NSParameterAssert(!item || [item isKindOfClass:[EDFilesystemItem class]]);

    EDFilesystemItem *fsItem = item ? item : _projItem;

    NSInteger c = [fsItem numberOfChildren];
    if (c < 0) {
        c = 0;
    }
    return c;
}


- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    NSParameterAssert(!item || [item isKindOfClass:[EDFilesystemItem class]]);

    EDFilesystemItem *fsItem = item ? item : _projItem;

    BOOL result = [fsItem numberOfChildren] != -1;
    return result;
}


- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item {
    NSParameterAssert(!item || [item isKindOfClass:[EDFilesystemItem class]]);
    EDAssert(_pwdItem);
    
    EDFilesystemItem *fsItem = item ? item : _projItem;

    EDFilesystemItem *child = [fsItem childAtIndex:idx];
    return child;
}


- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)col byItem:(id)item {
    NSParameterAssert([item isKindOfClass:[EDFilesystemItem class]]);
    EDAssert(_pwdItem);
    
    id result = nil;
    
    EDFilesystemItem *fsItem = item ? item : _projItem;
    
    //NSString *identifier = [col identifier];
    EDAssert([NAME_ID isEqualToString:[col identifier]]);
    if (fsItem == _sourceDirItem) {
        result = [[[_delegate projectFilePathForFilesystemViewController:self] lastPathComponent] stringByDeletingPathExtension];
    } else {
        result = fsItem.fullPath;
    }

    return result;
}


- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)filename forTableColumn:(NSTableColumn *)col byItem:(id)item {
    NSParameterAssert(!item || [item isKindOfClass:[EDFilesystemItem class]]);
    
    // JIC.
    if (![self isValidFilename:filename]) {
        return;
    }
    
    EDFilesystemItem *fsItem = item ? item : _projItem;
    EDAssert(fsItem);
    
    // necessary for when the name doesn't change.
    if ([filename isEqualToString:fsItem.fullPath]) {
        return;
    }
    
    BOOL expand = NO;
    if (!fsItem.isLeaf) {
        expand = [_outlineView isItemExpanded:item];
    }
        
    NSString *oldPath = fsItem.fullPath;

    NSString *newPath = [fsItem.fullPath stringByDeletingLastPathComponent];
    newPath = [newPath stringByAppendingPathComponent:filename];
    
    [self moveItem:fsItem fromPath:oldPath toPath:newPath];
    
    // rebuild filesystem tree. also reloads data
    EDFilesystemItem *parentItem = [_outlineView parentForItem:fsItem];
    if (!parentItem) {
        parentItem = [_pwdItem descendantAtFullPath:[fsItem.fullPath stringByDeletingLastPathComponent]];
    }
    EDAssert(parentItem);
    [parentItem reloadChildren];
    [_outlineView reloadData];
    
    if (expand) {
        fsItem = [parentItem descendantAtFullPath:newPath];
        EDAssert(fsItem);
        [_outlineView expandItem:fsItem];
    }
    
}


- (BOOL)copyItem:(EDFilesystemItem *)fsItem fromPath:(NSString *)oldPath toPath:(NSString *)newPath {
    return [self copyOrMove:YES item:fsItem fromPath:oldPath toPath:newPath];
}


- (BOOL)moveItem:(EDFilesystemItem *)fsItem fromPath:(NSString *)oldPath toPath:(NSString *)newPath {
    return [self copyOrMove:NO item:fsItem fromPath:oldPath toPath:newPath];
}


- (BOOL)copyOrMove:(BOOL)isCopy item:(EDFilesystemItem *)fsItem fromPath:(NSString *)oldPath toPath:(NSString *)newPath {
    EDAssert([oldPath length]);
    EDAssert([newPath length]);
    
    BOOL success = NO;

    NSString *rootPath = _pwdItem.fullPath;
    EDAssert([rootPath length]);

    EDAssert([oldPath hasPrefix:rootPath]);
    EDAssert([newPath hasPrefix:rootPath]);
    
    if (![oldPath hasPrefix:rootPath] || ![newPath hasPrefix:rootPath]) {
        goto done;
    }
    
    if ([oldPath isEqualToString:newPath]) {
        goto done;
    }
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    EDAssert([mgr fileExistsAtPath:oldPath]);

    BOOL isDir;
    if ([mgr fileExistsAtPath:newPath isDirectory:&isDir]) {
        TDPerformOnMainThreadAfterDelay(0.0, ^{
            NSString *title = nil;

            if (isDir) {
                title = NSLocalizedString(@"Folder already exists.", @"");
            } else {
                title = NSLocalizedString(@"File already exists.", @"");
            }

            NSString *oldFilename = [oldPath lastPathComponent];
            NSString *newParentDirName = [[newPath stringByDeletingLastPathComponent] lastPathComponent];
            NSString *msg = NSLocalizedString(@"“%@” couldn’t be moved to “%@” because an item with the same name already exists.", @"");
            
            NSString *cancel = NSLocalizedString(@"Cancel", @"");
            NSRunAlertPanel(title, msg, cancel, nil, nil, oldFilename, newParentDirName);
        });
        goto done;
    }
    
    NSError *err = nil;
    if (isCopy) {
        if (_delegate) {
            [_delegate filesystemViewController:self willCopyItemFromPath:oldPath toPath:newPath];
        }

        if (![mgr copyItemAtPath:oldPath toPath:newPath error:&err]) {
            if (err) NSLog(@"%@", err);
            goto done;
        }

        if (_delegate) {
            [_delegate filesystemViewController:self didCopyItemFromPath:oldPath toPath:newPath];
        }
    } else {
        if (_delegate) {
            [_delegate filesystemViewController:self willMoveItemFromPath:oldPath toPath:newPath];
        }
        
        if (![mgr moveItemAtPath:oldPath toPath:newPath error:&err]) {
            if (err) NSLog(@"%@", err);
            goto done;
        }

        if (_delegate) {
            [_delegate filesystemViewController:self didMoveItemFromPath:oldPath toPath:newPath];
        }

        EDAssert(![mgr fileExistsAtPath:oldPath]);
    }
    
    EDAssert([mgr fileExistsAtPath:newPath]);
    
    success = YES;
    
done:
    return success;
}


- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)data {
    EDFilesystemItem *fsItem = nil;
    if (_pwdItem) {
        EDAssert([data isKindOfClass:[NSData class]]);
        NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        EDAssert([dict isKindOfClass:[NSDictionary class]]);
        NSString *fullPath = [dict objectForKey:@"fullPath"];
        EDAssert([fullPath length]);
        
        EDAssert(_pwdItem);
        fsItem = [_pwdItem descendantAtFullPath:fullPath];
        //EDAssert(fsItem); // may be nil if deleted in Finder since last run
    }
    return fsItem;
}


- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)fsItem {
    EDAssert([fsItem isKindOfClass:[EDFilesystemItem class]]);
    NSString *fullPath = [fsItem fullPath];
    EDAssert([fullPath length]);
    
    NSDictionary *dict = @{@"fullPath": fullPath};
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    EDAssert([data length]);
    
    return data;
}


#pragma mark -
#pragma mark NSOutlineViewDelegate

- (CGFloat)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    if (item == _sourceDirItem) {
        return [EDFilesystemItemCell projectItemCellHeight];
    } else {
        return [ov rowHeight];
    }
}


- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item {
    EDAssertMainThread();
    EDAssert([item isKindOfClass:[EDFilesystemItem class]]);
    
    NSString *fullPath = nil;
    if ([item isLeaf]) {
        fullPath = [item fullPath];
    } else if (item == _sourceDirItem) {
        fullPath = EDProjectSettingsURL;
    }
    
    if (fullPath) {
        EDAssert([fullPath length]);
        [_delegate filesystemViewController:self didActivateItemAtPath:fullPath];
    }
    
    return YES;
}


//- (void)outlineView:(NSOutlineView *)ov willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)col item:(id)item {
//    EDAssert([cell isKindOfClass:[EDFilesystemItemCell class]]);
//    
//    EDFilesystemItem *fsItem = item ? item : _pwdItem;
//    
////    NSString *path = fsItem.fullPath;
////    EDAssert([path length]);
////    
////    if ([_outlineView editedRow] > -1) {
////        path = [path lastPathComponent];
////    }
////    [cell setTitle:path];
////
////    EDAssert(NSTextCellType == [(NSCell *)cell type]); // must be text type to edit.
//    
//    [cell setImage:fsItem.icon];
//}


- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)col item:(id)item {
    EDAssert(item);
    EDAssert([NAME_ID isEqualToString:[col identifier]]);

    if (!item || item == _projItem || item == _sourceDirItem) return NO;
    
    EDFilesystemItem *fsItem = item;

    NSString *ext = [fsItem.relativePath pathExtension];
    if ([ext isEqualToString:FILE_DOC_EXT]) {
        return NO;
    } else {
        
        NSEvent *evt = [[_outlineView window] currentEvent];
        
        if (NSLeftMouseUp == [evt type] && 2 == [evt clickCount]) {
            if (fsItem.isLeaf) {
                // open in new window like xcode ???
            } else {
                if ([_outlineView isItemExpanded:fsItem]) {
                    [_outlineView collapseItem:fsItem];
                } else {
                    [_outlineView expandItem:fsItem];
                }
            }
            return NO;
        } else {
            return YES;
        }
    }
}


- (BOOL)isValidFilename:(NSString *)filename {
    if (![filename length]) {
        return NO;
    }
    
    if ([filename rangeOfString:@"/"].length) {
        return NO;
    }
    
    return YES;
}


- (BOOL)control:(NSControl *)control isValidObject:(id)filename {
    return [self isValidFilename:filename];
}


- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    return YES;
}


- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    return YES;
}


#pragma mark -
#pragma mark NSMenuDelegate

- (void)actionPopUpButtonMenuNeedsUpdate:(NSMenu *)menu {
    EDFilesystemItem *fsItem = [self selectedFilesystemItem];
    
    BOOL hasSelection = fsItem != nil;
    BOOL isDir = hasSelection && !fsItem.isLeaf;
    BOOL isProj = fsItem == _projItem || fsItem == _sourceDirItem;
    
    EDAssert([menu itemWithTag:TAG_OPEN_SEP]);
    [[menu itemWithTag:TAG_OPEN_SEP] setHidden:!hasSelection];
    
    EDAssert([menu itemWithTag:TAG_OPEN]);
    [[menu itemWithTag:TAG_OPEN] setHidden:isProj || !hasSelection];
    
    EDAssert([menu itemWithTag:TAG_OPEN_WITH]);
    [[menu itemWithTag:TAG_OPEN_WITH] setHidden:isProj || !hasSelection || isDir];
    
    EDAssert([menu itemWithTag:TAG_RENAME]);
    [[menu itemWithTag:TAG_RENAME] setHidden:isProj || !hasSelection];

    EDAssert([menu itemWithTag:TAG_REVEAL]);
    [[menu itemWithTag:TAG_REVEAL] setHidden:!hasSelection];

    EDAssert([menu itemWithTag:TAG_DELETE_SEP]);
    [[menu itemWithTag:TAG_DELETE_SEP] setHidden:isProj || !hasSelection];
    
    EDAssert([menu itemWithTag:TAG_DELETE]);
    [[menu itemWithTag:TAG_DELETE] setHidden:isProj || !hasSelection];
}


- (NSImage *)smallIconForPath:(NSString *)path {
    EDAssert([path length]);
    NSImage *icon = EDIconForFile([path stringByExpandingTildeInPath]);
    [icon setSize:NSMakeSize(16.0, 16.0)];
    return icon;
}


- (void)navPopUpButtonMenuNeedsUpdate:(NSMenu *)menu {
    EDAssert(_pwdItem);

    NSMenuItem *pwdItem = [menu itemWithTag:TAG_PWD];

    NSImage *compIcon = [NSImage imageNamed:NSImageNameComputer];
    [compIcon setSize:NSMakeSize(16.0, 16.0)];
    
    NSImage *projRootIcon = [self smallIconForPath:_pwdItem.fullPath];

    NSString *title = nil;
    NSImage *pwdIcon = nil;
    if ([_pwdItem.fullPath isEqualToString:@"/Volumes"]) {
        title = NSLocalizedString(@"Computer", @"");
        pwdIcon = compIcon;
    } else {
        title = [_pwdItem.relativePath lastPathComponent];
        pwdIcon = projRootIcon;
    }
    [pwdItem setTitle:title];
    [pwdItem setImage:pwdIcon];
    [pwdItem setRepresentedObject:_pwdItem.fullPath];

    NSMenuItem *sourceDirItem = [menu itemWithTag:TAG_PROJ_ROOT];
    [sourceDirItem setTitle:_sourceDirItem.relativePath];
    [sourceDirItem setImage:projRootIcon];
    [sourceDirItem setRepresentedObject:_sourceDirItem.fullPath];
    
    NSMenuItem *compItem = [menu itemWithTag:TAG_COMPUTER];
    [compItem setImage:compIcon];
    [compItem setRepresentedObject:@"/Volumes"];
    
    NSMenuItem *homeItem = [menu itemWithTag:TAG_HOME];
    [homeItem setTitle:NSUserName()];
    [homeItem setImage:[self smallIconForPath:@"~"]];
    [homeItem setRepresentedObject:@"~"];
    
    NSMenuItem *dtopItem = [menu itemWithTag:TAG_DESKTOP];
    [dtopItem setImage:[self smallIconForPath:@"~/Desktop"]];
    [dtopItem setRepresentedObject:@"~/Desktop"];
    
    NSMenuItem *docsItem = [menu itemWithTag:TAG_DOCUMENTS];
    [docsItem setImage:[self smallIconForPath:@"~/Documents"]];
    [docsItem setRepresentedObject:@"~/Documents"];
}


- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _actionPopUpButtonMenu) {
        [self actionPopUpButtonMenuNeedsUpdate:menu];
    } else {
        [self navPopUpButtonMenuNeedsUpdate:menu];
    }
}

@end
