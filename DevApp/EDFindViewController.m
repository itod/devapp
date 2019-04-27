//
//  EDFindViewController.m
//  Editor
//
//  Created by Todd Ditchendorf on 9/9/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFindViewController.h"
#import "EDFindParameters.h"
#import "EDFileLocation.h"
#import "EDPattern.h"
#import "EDComboBox.h"
#import <TDAppKit/TDViewControllerView.h>
#import <TDAppKit/TDUtils.h>
#import <OkudaKit/OKUtils.h>
#import <OkudaKit/OKSource.h>
#import <TabKit/TKTabModel.h>

#define MIN_LINE_NUM_PADDING 3

static NSDictionary *sFilePathAttrs = nil;
static NSDictionary *sPreviewAttrs = nil;
static NSDictionary *sLineNumAttrs = nil;
static NSDictionary *sHiPreviewAttrs = nil;

@interface EDFindViewController ()
@property (nonatomic, assign) BOOL editingReplaceText;
@end

@implementation EDFindViewController

+ (void)initialize {
    if ([EDFindViewController class] == self) {
        sFilePathAttrs = [@{
                          NSFontAttributeName: [NSFont boldSystemFontOfSize:11.0],
                          NSForegroundColorAttributeName: [NSColor blackColor],
                          } retain];

        sPreviewAttrs = [@{
                         NSFontAttributeName: [NSFont systemFontOfSize:11.0],
                         NSForegroundColorAttributeName: [NSColor darkGrayColor],
                         } retain];
        
        sLineNumAttrs = [@{
                         NSFontAttributeName: [NSFont userFixedPitchFontOfSize:11.0],
                         NSForegroundColorAttributeName: [NSColor darkGrayColor],
                         } retain];
        
        sHiPreviewAttrs = [@{
                         NSFontAttributeName: [NSFont boldSystemFontOfSize:11.0],
                         NSForegroundColorAttributeName: [NSColor blackColor],
                         } retain];
    }
}


- (id)init {
    self = [self initWithNibName:@"EDFindViewController" bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    self = [super initWithNibName:name bundle:b];
    if (self) {
        self.title = NSLocalizedString(@"Find in Project", @"");
        
        self.searchTextHistory = [NSMutableArray array];
        self.replaceTextHistory = [NSMutableArray array];
        
    }
    return self;
}


- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.delegate = nil;
    
    self.closeButton = nil;
    _outlineView.dataSource = nil;
    _outlineView.delegate = nil;
    self.outlineView = nil;
    self.searchComboBox = nil;
    self.replaceComboBox = nil;
    self.resultCountLabel = nil;
    self.searchResults = nil;
    self.searchResultFilenames = nil;
    self.searchText = nil;
    self.replaceText = nil;
    self.searchTextHistory = nil;
    self.replaceTextHistory = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark TDViewController

- (void)viewDidLoad {
    EDAssert(_outlineView);
    EDAssert(_outlineView.delegate == self);
    EDAssert(_outlineView.dataSource == self);
    EDAssert(_searchComboBox);
    EDAssert(_replaceComboBox);

    TDViewControllerView *v = (TDViewControllerView *)[self view];
    v.color = [NSColor windowBackgroundColor];
    
    NSBundle *b = [NSBundle bundleForClass:[TKTabModel class]];
    NSImage *img = [b imageForResource:@"flat_tab_selected"];
    NSImage *altImg = [b imageForResource:@"flat_tab_selected"];
    EDAssert(img);
    EDAssert(altImg);
    
    EDAssert(_closeButton);
    [_closeButton setImage:img];
    [_closeButton setAlternateImage:altImg];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(edComboBoxDidBecomeFirstResponder:)
                                                 name:EDComboBoxDidBecomeFirstResponderNotification
                                               object:_replaceComboBox];
}


#pragma mark -
#pragma mark Actions

- (void)escape:(id)sender {
    [_delegate findViewControllerDidDismiss:self];
}


// <esc> was pressed in combo box
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)tv completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    [self escape:nil];
    return @[];
}


- (IBAction)search:(id)sender {
    EDAssertMainThread();
    if (![_searchText length] || self.busy) {
        NSBeep();
        return;
    }
    
    self.busy = YES;
    self.emptyResultSet = NO;
    self.canReplace = NO;
    
    EDAssert(_delegate);
    [_delegate findViewControllerWillSearch:self];
    
    EDAssert(_searchTextHistory);
    EDAssert(_searchText);
    
    if (![_searchTextHistory count] || ![[_searchTextHistory objectAtIndex:0] isEqualToString:_searchText]) {
        [_searchTextHistory insertObject:_searchText atIndex:0];
    }
    
    self.searchResultFilenames = [NSMutableArray array];
    self.searchResults = [NSMutableDictionary dictionary];
    [_outlineView reloadData];
    
    EDFindParameters *params = [self currentFindParameters];
    
    TDPerformOnBackgroundThread(^{
        [self performSearch:params];
    });
}


- (IBAction)replace:(id)sender {
    EDAssertMainThread();
    if (![_searchText length] || ![_replaceText length] || ![_searchResults count] || ![_searchResultFilenames count] || self.busy) {
        NSBeep();
        return;
    }

    self.busy = YES;
    self.canReplace = NO;
    
    EDAssert(_replaceTextHistory);
    EDAssert(_replaceText);
    
    if (![_replaceTextHistory count] || ![[_replaceTextHistory objectAtIndex:0] isEqualToString:_replaceText]) {
        [_replaceTextHistory insertObject:_replaceText atIndex:0];
    }

    EDFindParameters *params = [self currentFindParameters];
    
    EDAssert([_searchResultFilenames count]);
    [_delegate findViewController:self willStartReplacingInFiles:[[_searchResultFilenames copy] autorelease]];
    
    EDAssert([_searchResults count]);
    NSDictionary *searchResults = [[_searchResults copy] autorelease];
    
    TDPerformOnBackgroundThread(^{
        [self performReplace:params inSearchResults:searchResults];
    });
}


- (IBAction)prev:(id)sender {
    [self performNextPrev:NO];
}


- (IBAction)next:(id)sender {
    [self performNextPrev:YES];
}


- (void)performNextPrev:(BOOL)isNext {
    EDAssertMainThread();

    if (![_searchResults count]) return;
    
    NSUInteger first = 1;
    NSUInteger last = [_outlineView numberOfRows];
    if (0 == last) return; // should never happen. famous last words.
    --last;

    BOOL isFilePathRow = NO;
    BOOL wraps = [[EDUserDefaults instance] findInProjectWrapAround];

    NSUInteger i = 0;
    if ([_outlineView numberOfSelectedRows] > 0) {
        i = [_outlineView selectedRow];
    }
    
    EDAssert(NSNotFound != i);
    EDAssert(i <= last);
    
    do {
        if (!isNext && i <= first) {
            i = wraps ? last : first;
        } else if (isNext && last == i) {
            i = wraps ? first : last;
        } else {
            if (isNext) {
                ++i;
            } else {
                --i;
            }
        }
        isFilePathRow = [[_outlineView itemAtRow:i] isKindOfClass:[NSString class]];
    } while (isFilePathRow);
    
    [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
    [_outlineView scrollRowToVisible:i];
    [self activateFileLocation:[_outlineView itemAtRow:i]];
//    EDFileLocation *fileLoc = [_outlineView itemAtRow:i];
//    [self activateFileLocationLater:fileLoc];
}


#pragma mark -
#pragma mark Public

- (void)selectResultFileLocation:(EDFileLocation *)fileLoc {
    EDAssertMainThread();
    EDAssert(fileLoc);
    
    NSArray *results = [_searchResults objectForKey:fileLoc.URLString];
    EDAssert([results count]);
    
    NSUInteger row = [results indexOfObject:fileLoc] + 1; // 1 for the file name row
    EDAssert(NSNotFound != row);
    EDAssert(row <= [results count]);
    [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [_outlineView scrollRowToVisible:row];
}


#pragma mark -
#pragma mark NSControlTextEditingDelegate

- (void)edComboBoxDidBecomeFirstResponder:(NSNotification *)n {
    self.editingReplaceText = YES;
    TDAssert(_outlineView);
    [_outlineView reloadData];
}


- (void)controlTextDidBeginEditing:(NSNotification *)n {
    self.editingReplaceText = YES;
    TDAssert(_outlineView);
    [_outlineView reloadData];
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    self.editingReplaceText = NO;
    TDAssert(_outlineView);
    [_outlineView reloadData];
}


- (void)controlTextDidChange:(NSNotification *)n {
    NSControl *c = [n object];
    if (c == _replaceComboBox) {
        TDAssert(!_replaceText || [_replaceText isEqualToString:[c stringValue]])
        TDAssert(_outlineView);
        [_outlineView reloadData];
    }
}


#pragma mark -
#pragma mark NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)cb {
    NSArray *vec = cb == _searchComboBox ? _searchTextHistory : _replaceTextHistory;
    EDAssert(vec);

    NSInteger c = [vec count];
    return c;
}


- (id)comboBox:(NSComboBox *)cb objectValueForItemAtIndex:(NSInteger)idx {
    NSArray *vec = cb == _searchComboBox ? _searchTextHistory : _replaceTextHistory;
    EDAssert(vec);

    EDAssert(idx < [vec count]);
    NSString *str = [vec objectAtIndex:idx];
    return str;
}


#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    NSParameterAssert(!item || [item isKindOfClass:[NSString class]]);
    
    NSUInteger c = 0;
    
    if (!item) {
        c = [_searchResultFilenames count];
    } else if ([item isKindOfClass:[NSString class]]) {
        c = [[_searchResults objectForKey:item] count]; // ???
    } else {
        EDAssert(0);
    }
    
    return c;
}


- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    BOOL result = NO;
    
    if (!item) {
        result = YES;
    } else if ([item isKindOfClass:[NSString class]]) {
        result = YES;
    } else {
        EDAssert([item isKindOfClass:[EDFileLocation class]]);
        return NO;
    }
    
    return result;
}


- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item {
    NSParameterAssert(!item || [item isKindOfClass:[NSString class]]);
    
    id result = nil;
    
    if (!item) {
        result = [_searchResultFilenames objectAtIndex:idx];
    } else if ([item isKindOfClass:[NSString class]]) {
        result = [[_searchResults objectForKey:item] objectAtIndex:idx];
    } else {
        EDAssert(0);
    }
    
    return result;
}


- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)col byItem:(id)item {
    NSString *identifier = [col identifier];
    BOOL isTitle = [identifier isEqualToString:@"title"];
    
    id result = nil;
    
    if ([item isKindOfClass:[NSString class]]) {
        if (isTitle) {
            result = [[[NSAttributedString alloc] initWithString:[item stringByAbbreviatingWithTildeInPath] attributes:sFilePathAttrs] autorelease];
        } else {
            result = nil;
        }
    } else {
        EDAssert([item isKindOfClass:[EDFileLocation class]]);
        if (isTitle) {
            result = [item preview];
        } else {
            result = @([item selected]);
        }
    }
    
    return result;
}


- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)val forTableColumn:(NSTableColumn *)col byItem:(id)item {
    if ([[col identifier] isEqualToString:@"selected"] && [item isKindOfClass:[EDFileLocation class]]) {
        BOOL selected = [val boolValue];
        [item setSelected:selected];
    }
}


- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)data {
    id item = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    EDAssert([item conformsToProtocol:@protocol(NSCoding)]);
    EDAssert([item isKindOfClass:[NSString class]] || [item isKindOfClass:[EDFileLocation class]]);
    
    return item;
}


- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
    EDAssert([item conformsToProtocol:@protocol(NSCoding)]);
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:item];
    EDAssert([data length]);
    
    return data;
}


#pragma mark -
#pragma mark NSOutlineViewDelegate

- (void)outlineView:(NSOutlineView *)ov willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)col item:(id)item {
    NSString *identifier = [col identifier];

    // highlight attributed preview string to white
    if ([identifier isEqualToString:@"title"]) {
        id attrStr = nil;
        
//        if ([item isKindOfClass:[NSString class]]) {
//            NSString *filename = [[item copy] autorelease];
//            NSString *projPath = [NSString stringWithFormat:@"%@/", [[[[[[[self view] window] windowController] document] fileURL] relativePath] stringByDeletingLastPathComponent]];
//            filename = [filename stringByReplacingOccurrencesOfString:projPath withString:@""];
//            attrStr = [[[NSAttributedString alloc] initWithString:filename attributes:sFilePathAttrs] autorelease];
//        }
        
        if (_editingReplaceText && [item isKindOfClass:[EDFileLocation class]]) {
            EDFileLocation *fileLoc = (EDFileLocation *)item;
            attrStr = [[fileLoc.preview mutableCopy] autorelease];

            if ([_replaceText length]) {
                NSString *repTxt = _replaceText;
                BOOL useRegex = [[EDUserDefaults instance] findInProjectUseRegex];

                if (useRegex) {
                    NSUInteger opts = 0;
                    opts |= NSRegularExpressionSearch;

                    NSString *searchPat = _searchText;
                    NSString *subPat = _replaceText;
                    NSString *srcStr = [[attrStr string] substringWithRange:fileLoc.previewReplaceRange];
                    repTxt = [srcStr stringByReplacingOccurrencesOfString:searchPat withString:subPat options:opts range:NSMakeRange(0, [srcStr length])];
                }

                [attrStr replaceCharactersInRange:fileLoc.previewReplaceRange withString:repTxt];
                [attrStr setAttributes:sHiPreviewAttrs range:NSMakeRange(fileLoc.previewReplaceRange.location, [repTxt length])];
            }
            if (attrStr) {
                [cell setAttributedStringValue:attrStr];
            }
        }

        if ([cell isHighlighted] && [[[self view] window] firstResponder] == _outlineView) {
            if ([item isKindOfClass:[EDFileLocation class]]) {
                EDFileLocation *fileLoc = (EDFileLocation *)item;
                if (!attrStr) attrStr = [[fileLoc.preview mutableCopy] autorelease];

                NSRange range = NSMakeRange(0, [attrStr length]);
                [attrStr addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:range];
            } else {
                attrStr = [[[NSAttributedString alloc] initWithString:item attributes:sHiPreviewAttrs] autorelease];
            }
        }
        
        if (attrStr) {
            [cell setAttributedStringValue:attrStr];
        }
    } else {
        EDAssert([identifier isEqualToString:@"selected"]);
        if ([item isKindOfClass:[NSString class]]) {
            [cell setTransparent:YES];
        } else {
            [cell setTransparent:NO];
        }
    }
}


- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)col item:(id)item {
    BOOL editable = NO;
    
    NSString *identifier = [col identifier];
    if ([identifier isEqualToString:@"selected"] && [item isKindOfClass:[EDFileLocation class]]) {
        editable = YES;
    }
    
    return editable;
}


- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item {
    BOOL select = NO;
    
    if ([item isKindOfClass:[EDFileLocation class]]) {
        select = YES;
        [self activateFileLocationLater:item];
    }
    
    return select;
}


#pragma mark -
#pragma mark EDFindOutlineViewDelegate

// this supports clicking on an already selected row to re-highlight
- (void)findOutlineView:(NSOutlineView *)ov didReceiveClickOnRow:(NSInteger)row {
    EDAssertMainThread();
    EDAssert(ov == _outlineView);
    
    id item = [_outlineView itemAtRow:row];
    if ([item isKindOfClass:[EDFileLocation class]]) {
        [self activateFileLocationLater:item];
    }
}


- (void)findOutlineViewDidDidEscape:(NSOutlineView *)ov {
    [self escape:ov];
}


#pragma mark -
#pragma mark Private

- (void)activateFileLocationLater:(EDFileLocation *)fileLoc {
    EDAssertMainThread();
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(activateFileLocation:) withObject:fileLoc afterDelay:0.1];
}


- (void)activateFileLocation:(EDFileLocation *)fileLoc {
    EDAssertMainThread();
    [_delegate findViewController:self didActivateFileLocation:fileLoc];
}


- (EDFindParameters *)currentFindParameters {
    NSString *path = nil;
    
    if (_searchEntireProject) {
        path = [_delegate searchDirPathForFindViewController:self];
    } else {
        path = [_delegate searchFilePathForFindViewController:self];
    }
    EDAssert([path length]);

    BOOL matchCase = [[EDUserDefaults instance] findInProjectMatchCase];
    BOOL useRegex = [[EDUserDefaults instance] findInProjectUseRegex];
    
    EDFindParameters *params = [EDFindParameters findParametersWithRootPath:path searchText:_searchText replaceText:_replaceText matchCase:matchCase useRegex:useRegex];
    return params;
}


- (void)performSearch:(EDFindParameters *)params {
    EDAssertNotMainThread();
    
    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    BOOL isDir;
    if (![mgr fileExistsAtPath:params.rootPath isDirectory:&isDir]) {
        if (err) NSLog(@"%@", err);
        EDAssert(0);
        
        goto done;
    }
    
    if (isDir) {
        [self performSearch:params inDir:params.rootPath];
    } else {
        [self performSearch:params inFiles:@[params.rootPath]];
    }
    
done:
    TDPerformOnMainThreadAfterDelay(0.1, ^{
        [self didCompleteSearch];
    });
}


- (void)performSearch:(EDFindParameters *)params inDir:(NSString *)dirPath {
    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];

    NSArray *filenames = [mgr contentsOfDirectoryAtPath:dirPath error:&err];
    if (!filenames) {
        if (err) NSLog(@"%@", err);
        return;
    }
    
    NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[filenames count]];
    
    for (NSString *filename in filenames) {
        if ([filename hasPrefix:@"."] || [self shouldExclude:filename]) continue;
        
        NSString *filePath = [dirPath stringByAppendingPathComponent:filename];
        EDAssert([filePath length]);
        [filePaths addObject:filePath];
    }
    
    [self performSearch:params inFiles:filePaths];
}


- (BOOL)shouldExclude:(NSString *)filename {
    BOOL exclude = NO;
    
    NSArray *pats = [[EDUserDefaults instance] excludeFilePatterns];
    for (EDPattern *pat in pats) {
        if ([pat isMatch:filename]) {
            exclude = YES;
            break;
        }
    }

    return exclude;
}


- (void)performSearch:(EDFindParameters *)params inFiles:(NSArray *)filePaths {
    NSFileManager *mgr = [NSFileManager defaultManager];

    NSAttributedString *emptyAttrStr = [[[NSAttributedString alloc] initWithString:@""] autorelease];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    for (NSString *filePath in filePaths) {
        
        // check for directory
        BOOL isDir;
        BOOL exists = [mgr fileExistsAtPath:filePath isDirectory:&isDir];
        EDAssert(exists);
        
        if (exists && isDir) {
            [self performSearch:params inDir:filePath];
            continue;
        }

        // fetch source (from memory if resident, or disk)
        NSError *err = nil;
        OKSource *source = [_delegate findViewController:self sourceForFileAtPath:filePath error:&err];
        NSString *str = source.text;
        if (!str) {
            if (err) NSLog(@"%@", err);
            continue;
        }

        NSUInteger strLen = [str length];
        if (0 == strLen) continue;
        
        NSMutableArray *fileLocs = nil;
        
        NSUInteger startLoc = 0;
        NSString *lineNumFmtStr = nil;
        
        // build opts
        NSUInteger opts = 0;
        if (!params.matchCase) opts |= NSCaseInsensitiveSearch;
        if (params.useRegex) opts |= NSRegularExpressionSearch;
        
        while (startLoc < strLen) {
            // build range
            NSRange searchRange = NSMakeRange(startLoc, strLen - startLoc);
            
            // search
            NSRange foundRange = [str rangeOfString:params.searchText options:opts range:searchRange];
            
            // if found ...
            if (foundRange.length) {
                EDAssert(NSNotFound != foundRange.length);
                EDAssert(NSNotFound != foundRange.location);
                
                // build fileLoc obj
                NSUInteger lineNum = OKLineNumberForGlyphAtIndex(str, foundRange.location);
                EDFileLocation *fileLoc = [EDFileLocation fileLocationWithURLString:filePath selectedRange:foundRange];
                
                // build preview
                NSRange lineRange = [str lineRangeForRange:foundRange];
                NSString *previewStr = [str substringWithRange:lineRange];
                NSMutableAttributedString *as = [[[NSMutableAttributedString alloc] initWithString:previewStr attributes:sPreviewAttrs] autorelease];

                // highlight the search text
                NSRange hiRangeInPreview = NSMakeRange(foundRange.location - lineRange.location, foundRange.length);
                [as setAttributes:sHiPreviewAttrs range:hiRangeInPreview];

                // trim the whitespace
                previewStr = [as string];
                NSUInteger spaceLen = 0;
                for ( ; spaceLen < lineRange.length; ++spaceLen) {
                    unichar c = [previewStr characterAtIndex:spaceLen];
                    if (![whitespaceSet characterIsMember:c]) {
                        break;
                    }
                }
                [as replaceCharactersInRange:NSMakeRange(0, spaceLen) withAttributedString:emptyAttrStr];
                
                if (!lineNumFmtStr) {
                    NSUInteger numDigits = floor(log10(lineNum)) + 1;
                    numDigits = MAX(MIN_LINE_NUM_PADDING, numDigits);
                    lineNumFmtStr = [NSString stringWithFormat:@"%%%lulu: ", numDigits];
                }
                
                // insert the line num
                NSString *lineNumStr = [NSString stringWithFormat:lineNumFmtStr, lineNum];
                [as insertAttributedString:[[[NSAttributedString alloc] initWithString:lineNumStr attributes:sLineNumAttrs] autorelease] atIndex:0];
                
                // set preview
                fileLoc.preview = as;
                fileLoc.previewReplaceRange = NSMakeRange([lineNumStr length] + hiRangeInPreview.location, hiRangeInPreview.length);

                // insert into position 0 in the results (this is a backwards search)
                if (fileLocs) {
                    [fileLocs addObject:fileLoc];
                } else {
                    fileLocs = [NSMutableArray arrayWithObject:fileLoc];
                }
                
            }
            
            // increment
            startLoc = NSMaxRange(foundRange);
        }

        // notify incremental results for this file into the results tab
        if ([fileLocs count]) {
            TDPerformOnMainThread(^{
                [self incrementalSearchResults:fileLocs inFilePath:filePath];
            });
        }
    }
}


- (void)incrementalSearchResults:(NSArray *)fileLocs inFilePath:(NSString *)filePath {
    EDAssertMainThread();
    EDAssert(_searchResultFilenames);
    EDAssert(_searchResults);
    
    [_searchResultFilenames addObject:filePath];
    [_searchResultFilenames sortedArrayUsingSelector:@selector(compare:)];
    
    [_searchResults setObject:fileLocs forKey:filePath];

    [_outlineView reloadData];
    [_outlineView expandItem:nil expandChildren:YES];
}


- (void)didCompleteSearch {
    EDAssertMainThread();
    
    self.emptyResultSet = 0 == [_searchResultFilenames count];
    [self updateResultCountLabel];
    [self updateCanReplace];
    self.busy = NO;

    EDAssert(_delegate);
    [_delegate findViewControllerDidSearch:self];
}


- (void)updateCanReplace {
    self.canReplace = [_searchResults count]; // && [_replaceText length];
}


- (void)updateResultCountLabel {
    EDAssertMainThread();
    EDAssert(_resultCountLabel);
    
    NSUInteger c = 0;
    
    for (NSString *filename in _searchResults) {
        NSArray *fileLocs = _searchResults[filename];
        c += [fileLocs count];
    }

    NSString *txt = c > 0 ? [NSString stringWithFormat:NSLocalizedString(@"%d Results", @""), (int)c] : NSLocalizedString(@"No Results", @"");
    [_resultCountLabel setStringValue:txt];
}


- (void)performReplace:(EDFindParameters *)params inSearchResults:(NSDictionary *)searchResults {
    EDAssertNotMainThread();
    
    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    BOOL isDir;
    if (![mgr fileExistsAtPath:params.rootPath isDirectory:&isDir]) {
        if (err) NSLog(@"%@", err);
        EDAssert(0);
        
        goto done;
    }
    
//    NSArray *filenames = nil;
//
//    if (isDir) {
//        err = nil;
//        filenames = [mgr contentsOfDirectoryAtPath:params.rootPath error:&err];
//        if (!filenames) {
//            if (err) NSLog(@"%@", err);
//            
//            goto done;
//        }
//    } else {
//        filenames = @[params.rootPath];
//    }
    
//    if (params.useRegex) {
//        NSUInteger opts = NSRegularExpressionAnchorsMatchLines;
//        if (!params.matchCase) opts |= NSRegularExpressionCaseInsensitive;
//        
//        err = nil;
//        NSRegularExpression *searchRegex = [NSRegularExpression regularExpressionWithPattern:_searchText options:opts error:&err];
//        if (!searchRegex) {
//            if (err) NSLog(@"%@", err);
//            goto done;
//        }
//        params.searchRegex = searchRegex;
//
//        err = nil;
//        NSRegularExpression *replaceRegex = [NSRegularExpression regularExpressionWithPattern:_replaceText options:opts error:&err];
//        if (!replaceRegex) {
//            if (err) NSLog(@"%@", err);
//            goto done;
//        }
//        params.replaceRegex = replaceRegex;
//    }
    
    for (NSString *filePath in searchResults) {
        NSArray *fileLocs = [searchResults objectForKey:filePath];
        EDAssert([fileLocs count]);
        
        err = nil;
        NSMutableString *str = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
        if (!str) {
            if (err) NSLog(@"%@", err);
            continue;
        }
        
        NSUInteger strLen = [str length];
        if (0 == strLen) continue;
        
        if (params.useRegex) {
            [self performRegexReplace:params inFileLocations:fileLocs inString:str];
        } else {
            [self performReplace:params inFileLocations:fileLocs inString:str];
        }
        
        err = nil;
        if (![str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
            if (err) NSLog(@"%@", err);
        }
    }
    
done:
    TDPerformOnMainThreadAfterDelay(0.1, ^{
        [self didCompleteReplace];
    });
}


- (void)performReplace:(EDFindParameters *)params inFileLocations:(NSArray *)fileLocs inString:(NSMutableString *)str {
    EDAssert(!params.useRegex);

    // iterate in reverse
    for (EDFileLocation *fileLoc in [fileLocs reverseObjectEnumerator]) {
        if (!fileLoc.selected) continue;
        
        
        [str replaceCharactersInRange:fileLoc.selectedRange withString:params.replaceText];
    }
}


- (void)performRegexReplace:(EDFindParameters *)params inFileLocations:(NSArray *)fileLocs inString:(NSMutableString *)str {    
    EDAssert(params.useRegex);
    TDAssert(0); // TD shouldn't you be looping thru the file locs here???????

    NSUInteger opts = 0;
    if (!params.matchCase) opts |= NSCaseInsensitiveSearch;
    if (params.useRegex) opts |= NSRegularExpressionSearch;

    [str replaceOccurrencesOfString:params.searchText withString:params.replaceText options:opts range:NSMakeRange(0, [str length])];
}


- (void)didCompleteReplace {
    EDAssertMainThread();
    
    EDAssert([_searchResultFilenames count]);
    [_delegate findViewController:self didFinishReplacingInFiles:[[_searchResultFilenames copy] autorelease]];

    self.canReplace = NO;
    self.busy = NO;
}

@end
