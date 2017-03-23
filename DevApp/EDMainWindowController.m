//
//  EDWindowController.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/13/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDMainWindowController.h"
#import "EDUtils.h"
#import "EDDocumentController.h"
#import "EDDocument.h"
#import "EDTabModel.h"
#import "EDHistory.h"
#import "EDFileLocation.h"
#import "EDWindowContainerView.h"
#import "EDMidContainerView.h"
#import "EDConsoleViewController.h"
#import "EDFindViewController.h"
#import "EDFileWindowController.h"
#import "EDMemoryCodeRunner.h"
#import "EDTarget.h"
#import "EDScheme.h"
#import "EDRunAction.h"
#import "EDEnvironmentVariable.h"
#import "EDToolbarButtonItem.h"
#import "EDFileLocation.h"
#import "EDWebViewController.h"
#import "EDThemeManager.h"
#import "EDTheme.h"
#import "EDFileEncodingDetector.h"
#import <OkudaKit/OKSyntaxHighlighter.h>
#import <OkudaKit/OKTextView.h>
#import <OkudaKit/OKTrigger.h>
#import <OkudaKit/OKSource.h>
#import <TDAppKit/TDUtils.h>
#import <IDEKit/IDEUberView.h>
#import <TabKit/TKTabsListViewController.h>
#import <TabKit/TKTabModel.h>
#import <TabKit/TKTabListItemStyle.h>
#import <TabKit/TKTabsListView.h>
#import <PEGKit/PKToken.h>
#import <TDAppKit/TDTabBarController.h>
#import <OkudaKit/OKBreakpoint.h>
#import "EDBreakpointCollection.h"
#import "EDMainWindowController+NewProject.h"

#import "NSString+EDAdditions.h"
#import "NSString+Score.h"

#define DEBUGGER_PROMPT @">"

#define MIN_SCORE 0.5
#define FUZZINESS 0.9
#define MIN_AUTOCOMPLETE_EXACT_MATCH_LEN 2

@interface EDMainWindowController ()
@property (nonatomic, assign) BOOL tabsListViewVisible;
@property (nonatomic, assign) BOOL statusBarVisible;
@property (nonatomic, assign) BOOL navigatorViewVisible;
@property (nonatomic, assign) BOOL consoleViewVisible;
@property (nonatomic, assign) BOOL canvasViewVisible;

@property (nonatomic, assign) NSUInteger stackFrameIndex;
@property (nonatomic, retain) NSArray *frameStack;

@property (nonatomic, retain) EDFileLocation *findNextFileLocation;

@property (nonatomic, retain) NSArray *filteredData;
@property (nonatomic, retain) NSMutableDictionary *dirtySet;
@property (nonatomic, retain) NSMutableDictionary *lastFileLocByAbsPath;

@property (nonatomic, assign) NSStringEncoding userSelectedStringEncoding;
@end

@implementation EDMainWindowController

+ (NSString *)defaultType {
    return EDTabModelTypeSourceCodeFile;
}


+ (Class)tabModelClass {
    return [EDTabModel class];
}


- (id)init {
    self = [self initWithWindowNibName:@"EDWindow"];
    return self;
}


- (id)initWithWindowNibName:(NSString *)name {
    self = [super initWithWindowNibName:name];
    if (self) {
        self.dirtySet = [NSMutableDictionary dictionary];
        self.lastFileLocByAbsPath = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    EDAssert(_navigatorTabBarController.delegate = self);
    self.navigatorTabBarController.delegate = nil;

    EDAssert(!MULTI_FILE_ENABLED || _filesystemViewController.delegate == self);
    _filesystemViewController.delegate = nil;
    
    EDAssert(_stackTraceViewController.delegate == self);
    _stackTraceViewController.delegate = nil;

    EDAssert(_breakpointListViewController.delegate == self);
    _breakpointListViewController.delegate = nil;

    EDAssert(_consoleViewController.delegate == self);
    _consoleViewController.delegate = nil;
    [_consoleViewController unbind:@"isRunning"];

    for (TKTabModel *tm in self.tabModels) {
        if ([EDTabModelTypeSourceCodeFile isEqualToString:tm.type]) {
            OKViewController *okvc = tm.representedObject;
            EDAssert(okvc);
            OKGutterView *gv = okvc.gutterView;
            EDAssert(!gv || gv.delegate == self);
            gv.delegate = nil;
        }
    }

    self.windowContainerView = nil;
    self.midContainerView = nil;
    self.breakpointsEnabledToolbarItem = nil;
    self.outerUberView = nil;
    self.innerUberView = nil;
    self.navigatorTabBarController = nil;
    self.filesystemViewController = nil;
    self.stackTraceViewController = nil;
    self.breakpointListViewController = nil;
    self.canvasViewController = nil;
    self.consoleViewController = nil;
    self.findViewController = nil;
    self.projectWindowController = nil;
    self.fileEncodingDialogController.delegate = nil;
    self.fileEncodingDialogController = nil;
    
    self.fileWindowController = nil;
    self.statusText = nil;

    self.findNextFileLocation = nil;
    
    self.frameStack = nil;
    
    [self killCodeRunner];

    self.filteredData = nil;
    
    self.dirtySet = nil;
    self.lastFileLocByAbsPath = nil;
    
    [super dealloc];
}


- (void)killCodeRunner {
    EDAssertMainThread();
    if (_codeRunner) {
        [_codeRunner killResources];
        self.codeRunner = nil;
    }
}


#pragma mark -
#pragma mark NSWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    EDAssertMainThread();

    [self updateBreakpointsEnabledToolbarItem];
    
    [self setUpTabsListView];
    [self setUpOuterUberView];
    
    _windowContainerView.uberView = _outerUberView;
    [_windowContainerView addSubview:_outerUberView];

    [self setUpInnerUberView];
    [self setUpFilesystemView];
    [self setUpStackTraceView];
    [self setUpBreakpointListView];
    [self setUpCanvasView];
    [self setUpConsoleView];
    [self setUpFindView];

    [_windowContainerView setNeedsLayout];
    [_windowContainerView layoutSubviews]; // yes, force a layout now, before window appears on screen.

    self.canRun = YES;
    self.canStop = NO;
    self.paused = NO;

    [[self document] windowControllerDidLoadNib:self];
    [self setUpNavigatorTabBarController];

    [self afterWindowDidLoad];
}


- (void)afterWindowDidLoad {
    if (![self.tabModels count]) {
        TDPerformOnMainThreadAfterDelay(0.4, ^{
            [self editProject:nil];
        });
    }
}


- (void)windowWillClose:(NSNotification *)n {
    if ([self document]) {
        // don't need to call -saveDocument: as that has triggered this method call.
        [self saveAllDirtyFiles];
    }
    
    [super windowWillClose:n];
}


- (void)setUpTabsListView {
    TKTabsListViewController *tlvc = self.tabsListViewController;
    
    EDAssert(_windowContainerView);
    EDAssert(tlvc);
    
    EDAssert(![tlvc isViewLoaded]);
    [tlvc useStyleNamed:@"Flat"];
    EDAssert([tlvc isViewLoaded]);
    EDAssert([tlvc view]);
    
    _windowContainerView.tabsListViewHeight = [[tlvc.listItemStyle class] preferredTabItemFixedExtent];
    tlvc.allowsTabTitleEditing = NO;

    EDAssert(tlvc.listView);
    tlvc.listView.orientation = TDListViewOrientationLandscape;
    ((TKTabsListView *)tlvc.listView).wantsTopBorder = YES;
    tlvc.listView.backgroundGradient = [[[NSGradient alloc] initWithStartingColor:TDHexColor(0x9f9f9f) endingColor:TDHexColor(0xafafaf)] autorelease];
    tlvc.listView.nonMainBackgroundGradient = [[[NSGradient alloc] initWithStartingColor:TDHexColor(0xcccccc) endingColor:TDHexColor(0xcfcfcf)] autorelease];
    [tlvc.listView setNeedsDisplay:YES];
    [tlvc.listView reloadData];
    
    [_windowContainerView addSubview:[tlvc view]];
    _windowContainerView.tabsListView = [tlvc view];
}


- (void)setUpOuterUberView {
    self.outerUberView = [[[IDEUberView alloc] initWithFrame:[_windowContainerView bounds] dividerStyle:NSSplitViewDividerStyleThin] autorelease];
    [_outerUberView setAutosaveName:@"outer"];
    [_outerUberView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
}


- (void)setUpInnerUberView {
    EDAssert(_midContainerView);

    CGRect r = [_midContainerView bounds];
    self.innerUberView = [[[IDEUberView alloc] initWithFrame:r dividerStyle:NSSplitViewDividerStyleThin] autorelease];
    [_innerUberView setAutosaveName:@"inner"];
    [_innerUberView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    
    _midContainerView.uberView = _innerUberView;
    [_midContainerView addSubview:_innerUberView];
    
    _outerUberView.midView = _midContainerView;
}


- (void)setUpFilesystemView {
#if MULTI_FILE_ENABLED
    self.filesystemViewController = [[[EDFilesystemViewController alloc] init] autorelease];
    _filesystemViewController.delegate = self;
    [self navigateToSourceDir];
#endif
}


- (void)setUpStackTraceView {
    self.stackTraceViewController = [[[EDStackTraceViewController alloc] init] autorelease];
    _stackTraceViewController.delegate = self;
}


- (void)setUpBreakpointListView {
    self.breakpointListViewController = [[[EDBreakpointListViewController alloc] init] autorelease];
    _breakpointListViewController.delegate = self;
    _breakpointListViewController.collection = [[self document] breakpoints];
}


- (void)setUpNavigatorTabBarController {
    EDAssert(_outerUberView);
    EDAssert(!MULTI_FILE_ENABLED || _filesystemViewController);
    EDAssert(_stackTraceViewController);
    EDAssert(_breakpointListViewController);
    
    self.navigatorTabBarController = [[[TDTabBarController alloc] init] autorelease];
    _navigatorTabBarController.delegate = self;
    
    _outerUberView.leftTopView = [_navigatorTabBarController view];
    _outerUberView.maxLeftSplitWidth = 600.0;
    _outerUberView.preferredLeftSplitWidth = 220.0;

#if MULTI_FILE_ENABLED
    _navigatorTabBarController.viewControllers = @[_filesystemViewController, _stackTraceViewController, _breakpointListViewController];
#else
    _navigatorTabBarController.viewControllers = @[_stackTraceViewController, _breakpointListViewController];
#endif

    NSString *type = self.selectedTabModel.type;
    BOOL isSourceOrProjSettings = !type || [type isEqualToString:EDTabModelTypeProjectSettings] || [type isEqualToString:EDTabModelTypeSourceCodeFile];
    if ([[EDUserDefaults instance] navigatorViewVisible] && isSourceOrProjSettings) {
        [self showFilesystemNavigator:nil];
        [_outerUberView openLeftTopView:nil];
    }
}


- (void)navigateToSourceDir {
#if MULTI_FILE_ENABLED
    EDAssertMainThread();
    NSString *srcDirPath = [self sourceDirPath];
    if (srcDirPath) {
        EDAssert([srcDirPath length]);
        [_filesystemViewController changeDir:srcDirPath];
        [self syncFilesystemViewWithSelectedTab];
    }
#endif
}


- (void)syncFilesystemViewWithSelectedTab {
#if MULTI_FILE_ENABLED
    EDAssertMainThread();
    EDAssert(!MULTI_FILE_ENABLED || _filesystemViewController);
    
    if ([_filesystemViewController isViewLoaded]) {
        NSString *fullPath = [self absolutePathForTabModel:self.selectedTabModel];
        [_filesystemViewController selectItemAtPath:fullPath];
    }
#endif
}


- (void)setUpCanvasView {
    EDAssertMainThread();
}


- (void)updateCanvasPreferredSplitWidth {
    EDAssertMainThread();
}


- (void)setUpConsoleView {
    self.consoleViewController = [[[EDConsoleViewController alloc] init] autorelease];
    _consoleViewController.delegate = self;
    [_consoleViewController bind:@"isRunning" toObject:self withKeyPath:@"canStop" options:nil];
    
    [self showConsoleView];
}


- (void)showConsoleView {
    EDAssert(_innerUberView);
    EDAssert(_consoleViewController);
    
    NSView *v = [_consoleViewController view];
    if (_innerUberView.bottomView != v) {
        // must open first to get correct view sizing.
        if ([[EDUserDefaults instance] consoleViewVisible]) {
            [_innerUberView openBottomView:nil];
        }

        _innerUberView.bottomView = v;
        _innerUberView.maxBottomSplitHeight = MAXFLOAT;
        _innerUberView.preferredBottomSplitHeight = 200.0;
    }
}


- (void)setUpFindView {
    self.findViewController = [[[EDFindViewController alloc] init] autorelease];
    _findViewController.delegate = self;
    
}


- (void)showFindView {
    EDAssert(_innerUberView);
    EDAssert(_findViewController);
    
    NSView *v = [_findViewController view];
    
    if (_innerUberView.bottomView != v) {
        _innerUberView.bottomView = v;
        _innerUberView.maxBottomSplitHeight = MAXFLOAT;
        _innerUberView.preferredBottomSplitHeight = 200.0;
        
        if ([[EDUserDefaults instance] consoleViewVisible]) {
            [_innerUberView openBottomView:nil];
        }
    }
    
    [[self window] makeFirstResponder:_findViewController.searchComboBox];
}


#pragma mark -
#pragma mark TKWindowController

- (void)selectedTabIndexWillChange {
    TKTabModel *tm = self.selectedTabModel;
    if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        OKViewController *okvc = self.selectedSourceViewController;
        [okvc.textView removeListWindow];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextDidChangeNotification object:okvc.textView];
    }
}


- (void)selectedTabIndexDidChange {
    //NSLog(@"%s %lu", __PRETTY_FUNCTION__, self.selectedTabIndex);
    if (NSNotFound == self.selectedTabIndex) return;

    EDAssertMainThread();
    EDAssert(_outerUberView);
    EDAssert(_innerUberView);
    EDAssert(_windowContainerView);

    EDTabModel *seltm = self.selectedEDTabModel;
    EDAssert(seltm);
    
    TDViewController *vc = seltm.representedObject; // ??
    EDAssert(vc);
    
    NSView *v = [vc view];
    EDAssert(v);

    NSString *type = seltm.type;
    BOOL filesystemVisible = NO;
    BOOL canvasVisible = NO;
    BOOL consoleVisible = NO;
    
    NSView *newInnerMidView = nil;
    NSView *newOuterMidView = nil;
    
    if ([type isEqualToString:EDTabModelTypeProjectSettings]) {
        [v setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        newInnerMidView = v;
        newOuterMidView = _midContainerView;
        
        filesystemVisible = [[EDUserDefaults instance] navigatorViewVisible];
        [self syncFilesystemViewWithSelectedTab];

    } else if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        OKTextView *tv = self.selectedSourceViewController.textView;
        EDAssert(tv);

        [tv removeListWindow];
        
        //NSRange r = [tv visibleRange];

        NSScrollView *sv = [tv enclosingScrollView];
        EDAssert(sv);
        [sv setHasVerticalScroller:NO];

        TDPerformOnMainThreadAfterDelay(0.0, ^{
            EDAssert(sv);
            [sv setHasVerticalScroller:YES];

            if (!self.canStop) {
                id resp = [[self window] firstResponder];
                if (resp != self.filesystemViewController.outlineView) {
                    [[self window] makeFirstResponder:tv];
                }
            }
        });
        
        filesystemVisible = [[EDUserDefaults instance] navigatorViewVisible];
        canvasVisible = [[EDUserDefaults instance] canvasViewVisible];
        consoleVisible = [[EDUserDefaults instance] consoleViewVisible];
        
        newInnerMidView = v;
        newOuterMidView = _midContainerView;

        NSString *absPath = [self absolutePathForTabModel:seltm];
        if ([self isFileDirtyAtPath:absPath]) {
            OKSource *source = [self loadSourceForFileAtPath:absPath error:nil];
            [seltm.representedObject setSourceString:source.text encoding:source.encoding clearUndo:YES];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:tv];
        
    } else {
        newOuterMidView = v;
    }

    [self updateWindowTitle];
    
    EDHistory *history = self.currentHistory;
    self.canGoBack = history.canGoBack;
    self.canGoForward = history.canGoForward;

    // must open first to get correct view sizing.
    if (filesystemVisible) {
        [_outerUberView openLeftTopView:nil];
        [self navigateToSourceDir];
        [self syncFilesystemViewWithSelectedTab];
    } else {
        [_outerUberView closeLeftTopView:nil];
    }
    if (canvasVisible) {
        [_outerUberView openRightTopView:nil];
    } else {
        [_outerUberView closeRightTopView:nil];
    }
    
    // must add/remove console view before/after closing to prevent borking scrolling
    if (consoleVisible) {
        [_innerUberView openBottomView:nil];
        _innerUberView.bottomView = _consoleViewController.view;
    } else {
        _innerUberView.bottomView = nil;
        [_innerUberView closeBottomView:nil];
    }
    
    if (newInnerMidView) _innerUberView.midView = newInnerMidView;
    if (newOuterMidView) _outerUberView.midView = newOuterMidView;

    EDAssert([_outerUberView superview]);
    [_outerUberView setNeedsLayout:YES];
    
    // layout
    [_windowContainerView setNeedsLayout];

//    TDPerformOnMainThreadAfterDelay(0.25, ^{
//        if ([[self document] fileURL]) { // dont save if in process of creating proj.
//            [[self document] saveDocument:nil];
//        }
//    });
}


- (void)didAddTabModelAtIndex:(NSUInteger)i {
    EDAssertMainThread();
    EDAssert(_windowContainerView);
    [_windowContainerView setNeedsLayout];
    
    EDTabModel *tm = (EDTabModel *)[self tabModelAtIndex:i];
    
    if ([tm.type isEqualToString:EDTabModelTypeWebLocation]) {
        [tm bind:@"title" toObject:tm.representedObject withKeyPath:@"title" options:nil];
        [tm bind:@"URLString" toObject:tm.representedObject withKeyPath:@"URLString" options:nil];
    } else if ([tm.type isEqualToString:EDTabModelTypeREPL]) {
        [tm bind:@"title" toObject:tm.representedObject withKeyPath:@"title" options:nil];
    } else if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        EDFileLocation *fileLoc = [tm.history current];
        if (fileLoc && fileLoc.hasVisibleRange) {
            [self navigateToFileLocationInCurrentTab:fileLoc];
        }
    }

    if ([[self document] fileURL]) {
        [[self document] saveDocument:nil];
    }
    [self invalidateRestorableState];
}


- (void)willRemoveTabModelAtIndex:(NSUInteger)i {
    EDTabModel *tm = (id)[self tabModelAtIndex:i];
    [tm unbind:@"title"];
    [tm unbind:@"URLString"];
    if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        OKViewController *okvc = tm.representedObject;
        
        NSString *absPath = [self absolutePathForTabModel:tm];
        if ([self isFileDirtyAtPath:absPath] && [self lastModifiedTabModelForAbsolutePath:absPath] == tm) {
            NSString *text = [[okvc.sourceString copy] autorelease];
            NSStringEncoding enc = okvc.sourceStringEncoding;
            OKSource *source = [OKSource sourceWithText:text encoding:enc];
            [self putDirtySource:source forFilePath:absPath];
        }

        okvc.textView.listDataSource = nil;
        okvc.textView.listDelegate = nil;
    }
}


- (void)didRemoveTabModel {
    EDAssertMainThread();
    [_windowContainerView setNeedsLayout];
    [[self document] saveDocument:nil];
    [self invalidateRestorableState];
}


- (void)didSwapTabModelsAtIndex:(NSUInteger)i andIndex:(NSUInteger)j {
    [[self document] saveDocument:nil];
    [self invalidateRestorableState];
}


- (TKTabModel *)newTabModelWithContentsOfURLString:(NSString *)inURLString type:(NSString *)type error:(NSError **)outErr {
    Class cls = [[self class] tabModelClass];
    EDAssert([cls isSubclassOfClass:[EDTabModel class]]);
    
    NSString *srcDirPath = [self sourceDirPath];
    
    NSString *tmPath = inURLString;
    
    if ([tmPath hasPrefix:srcDirPath]) {
        EDAssert([type isEqualToString:EDTabModelTypeSourceCodeFile]);
        tmPath = [self relativeSourceFilePathForAbsoluteSourceFilePath:inURLString];
    }
    
    TKTabModel *tm = [[cls alloc] initWithURLString:tmPath type:type];
    
    id obj = [[self newRepresentedObjectWithContentsOfURLString:inURLString type:type error:outErr] autorelease];
    EDAssert(obj);
    tm.representedObject = obj;
    
    return tm;
}


- (id)newRepresentedObjectWithContentsOfURLString:(NSString *)URLString type:(NSString *)type error:(NSError **)outErr {
    if ([type isEqualToString:EDTabModelTypeWebLocation]) {
        if (!URLString) {
            URLString = [self documentationHomeURLString];
        }
        EDAssert([URLString length]);

        EDWebViewController *wvc = [[EDWebViewController alloc] init]; // +1
        wvc.initialURLString = URLString;
        
        // listen for title changes
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(webViewControllerTitleDidChange:) name:EDWebViewControllerTitleDidChangeNotification object:wvc];
        
        return wvc;

    } else if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        OKViewController *okvc = [[OKViewController alloc] initWithDefaultNib]; // +1
        [okvc loadView];
        okvc.enableDefinitionLinking = YES;
        okvc.gutterView.minimumNumberOfColumns = 3;
        okvc.textView.listDataSource = self;
        okvc.textView.listDelegate = self;

        [self updateThemeInViewController:okvc];
        
        OKSource *source = [self loadSourceForFileAtPath:URLString error:outErr];
        
        if (source) {
            [okvc setSourceString:source.text encoding:source.encoding];
        } else {
            EDAssert(*outErr);
            if (*outErr) {
                [self presentFileEncodingDialog:*outErr forFileAtPath:URLString];
            }
        }
        
        EDAssert(okvc.gutterView);
        okvc.gutterView.delegate = self;
        
        return okvc;
    } else {
        EDAssert(0);
        return nil;
    }
}


#pragma mark -
#pragma mark State restoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    //NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, self, [[self document] displayName]);
    [super encodeRestorableStateWithCoder:coder];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    
    EDAssert(_navigatorTabBarController);
    dict[@"navigatorTabBarController.selectedIndex"] = @(_navigatorTabBarController.selectedIndex);

    //NSLog(@"%@", dict);
    [coder encodeObject:dict forKey:NSStringFromClass([self class])];
}


- (void)restoreStateWithCoder:(NSCoder *)coder {
    //NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, self, [[self document] displayName]);
    [super restoreStateWithCoder:coder];

    NSDictionary *dict = [coder decodeObjectForKey:NSStringFromClass([self class])];
    if (![dict count]) return;
 
    EDAssert(_navigatorTabBarController);
    NSUInteger i = [dict[@"navigatorTabBarController.selectedIndex"] unsignedIntegerValue];
    if (_navigatorTabBarController && NSNotFound != i && i < [_navigatorTabBarController.viewControllers count]) {
        _navigatorTabBarController.selectedIndex = i;
    }
}


#pragma mark -
#pragma mark TDTabBarControllerDelegate

- (void)tabBarController:(TDTabBarController *)tabBarController didSelectViewController:(TDViewController *)viewController {
    [self invalidateRestorableState];
}


#pragma mark -
#pragma mark FullScreen

- (void)updateUIForEnteringViewingMode {
    [super updateUIForEnteringViewingMode];
    
    self.tabsListViewVisible = [[EDUserDefaults instance] tabsListViewVisible];
    if (_tabsListViewVisible) {
        [[EDDocumentController instance] toggleTabsListViewVisible:nil];
    }
    
    self.statusBarVisible = [[EDUserDefaults instance] statusBarVisible];
    if (_statusBarVisible) {
        [[EDDocumentController instance] toggleStatusBarVisible:nil];
    }
    
    self.navigatorViewVisible = [[EDUserDefaults instance] navigatorViewVisible];
    if (_navigatorViewVisible) {
        [[EDDocumentController instance] toggleNavigatorVisible:nil];
    }
    
    self.consoleViewVisible = [[EDUserDefaults instance] consoleViewVisible];
    if (_consoleViewVisible) {
        [[EDDocumentController instance] toggleConsoleViewVisible:nil];
    }
    
    self.canvasViewVisible = [[EDUserDefaults instance] canvasViewVisible];
    if (_canvasViewVisible) {
        [[EDDocumentController instance] toggleCanvasViewVisible:nil];
    }
}


- (void)updateUIForExitingViewingMode {
    [super updateUIForExitingViewingMode];
    
    if (_tabsListViewVisible) {
        [[EDDocumentController instance] toggleTabsListViewVisible:nil];
    }
    
    if (_statusBarVisible) {
        [[EDDocumentController instance] toggleStatusBarVisible:nil];
    }
    
    if (_navigatorViewVisible) {
        [[EDDocumentController instance] toggleNavigatorVisible:nil];
    }
    
    if (_consoleViewVisible) {
        [[EDDocumentController instance] toggleConsoleViewVisible:nil];
    }

    if (_canvasViewVisible) {
        [[EDDocumentController instance] toggleCanvasViewVisible:nil];
    }
}

#pragma mark -
#pragma mark Private

- (void)windowDidVirginLoad {
    [super windowDidVirginLoad];
    NSScreen *screen = [NSScreen mainScreen];
    EDAssert(screen);
    CGRect screenFrame = [screen visibleFrame];
    CGRect winFrame = CGRectInset(screenFrame, screenFrame.size.width * 0.025, screenFrame.size.height * 0.025);
    EDAssert([self window]);
    [[self window] setFrame:winFrame display:YES animate:YES];
}


- (void)updateWindowTitle {
    EDAssertMainThread();
    EDDocument *doc = [self document];
    [[self window] setTitle:[doc displayName]];
}


- (NSDictionary *)envVarsDictFromArray:(NSArray *)envVars  {
    NSMutableDictionary *tab = [NSMutableDictionary dictionaryWithCapacity:[envVars count]];
    for (EDEnvironmentVariable *envVar in envVars) {
        NSString *name = envVar.name;
        NSString *value = envVar.value;
        EDAssert([name length]);
        EDAssert([value length]);
        tab[name] = value;
    }
    return tab;
}


- (void)updateThemeInViewController:(OKViewController *)okvc {
    EDAssertMainThread();
    EDAssert(okvc);
    
    [okvc setGrammarName:@"js" attributeProvider:[EDThemeManager instance]];
}


- (void)updateBreakpointsEnabledToolbarItem {
    EDDocument *doc = [self document];
    EDAssert(doc);

    EDAssert(_breakpointsEnabledToolbarItem);
    NSButton *b = _breakpointsEnabledToolbarItem.button;
    
    EDAssert(b);
    [b setState:doc.breakpointsEnabled ? NSOnState : NSOffState];
}


- (OKViewController *)selectedSourceViewController {
    TKTabModel *tm = self.selectedTabModel;
    EDAssert(tm);

    OKViewController *okvc = nil;
    
    if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        okvc = tm.representedObject;
        EDAssert(okvc);
    }
    
    return okvc;
}


- (NSDictionary *)allEnabledBreakpointsPlist {
    NSDictionary *result = nil;
    NSArray *bps = [[[self document] breakpoints] allBreakpoints];
    NSString *srcDirPath = [self sourceDirPath];

    NSUInteger c = [bps count];
    
    if (c) {
        NSMutableArray *all = [NSMutableArray arrayWithCapacity:c];
        
        for (OKBreakpoint *bp in bps) {
            if (bp.enabled) {
                NSMutableDictionary *plist = [[[bp asPlist] mutableCopy] autorelease];
                plist[@"file"] = [NSString stringWithFormat:@"%@%@", srcDirPath, bp.file];
                [all addObject:plist];
            }
        }
        
        result = @{@"all": all};
    }
    
    return result;
}


- (void)selectTabWithPath:(NSString *)path {
    NSUInteger idx = 0;
    for (TKTabModel *tm in self.tabModels) {
        
        if ([EDTabModelTypeSourceCodeFile isEqualToString:tm.type] && [[self absolutePathForTabModel:tm] isEqualToString:path]) {
            self.selectedTabIndex = idx;
            return;
        }
        
        ++idx;
    }
    
    NSError *err = nil;
    if (![self addTabWithContentsOfURLString:path type:EDTabModelTypeSourceCodeFile error:&err]) {
        NSLog(@"%@", err);
    }
}


- (void)navigateToProjectSettings {
    NSUInteger found = NSNotFound;
    
    NSUInteger i = 0;
    for (EDTabModel *tm in self.tabModels) {
        if ([tm.type isEqualToString:EDTabModelTypeProjectSettings]) {
            found = i;
            break;
        }
        ++i;
    }
    
    if (NSNotFound != found) {
        self.selectedTabIndex = found;
    } else {
        NSError *err = nil;
        if (![self addTabWithContentsOfURLString:EDProjectSettingsURL type:EDTabModelTypeProjectSettings error:&err]) {
            NSLog(@"%@", err);
        }
    }
}


- (void)navigateToFileLocationInCurrentTab:(EDFileLocation *)fileLoc {
    [self navigateToFileLocationInCurrentTab:fileLoc andSelect:YES storeInHistory:YES];
}


- (void)navigateToFileLocationInCurrentTab:(EDFileLocation *)fileLoc andSelect:(BOOL)select {
    [self navigateToFileLocationInCurrentTab:fileLoc andSelect:select storeInHistory:YES];
}


- (void)navigateToFileLocationInCurrentTab:(EDFileLocation *)fileLoc andSelect:(BOOL)select storeInHistory:(BOOL)store {
    
    BOOL comingFromProjSettings = [self.selectedEDTabModel.type isEqualToString:EDTabModelTypeProjectSettings];
    
    NSString *srcDirPath = [self sourceDirPath];
    EDTabModel *tm = self.selectedEDTabModel;
    OKViewController *okvc = self.selectedSourceViewController;
    OKTextView *tv = okvc.textView;
    
    // if current file is dirty, store it in _dirtySet
    NSString *oldAbsPath = [self absolutePathForTabModel:tm];
    if ([self isFileDirtyAtPath:oldAbsPath]) {
        EDAssert([self dirtySourceForFilePath:oldAbsPath]);
        
        NSString *text = [[[tv string] copy] autorelease]; // MUST COPY here. this is a mutable string
        NSStringEncoding enc = okvc.sourceStringEncoding;
        
        OKSource *source = [OKSource sourceWithText:text encoding:enc];
        [self putDirtySource:source forFilePath:oldAbsPath];
    }
    
    // determine new abs path
    NSString *newAbsPath = fileLoc.URLString;
    if (![newAbsPath isAbsolutePath] && ![newAbsPath hasPrefix:srcDirPath]) {
        newAbsPath = [self absoluteSourceFilePathForRelativeSourceFilePath:newAbsPath];
    }
    EDAssert([newAbsPath length]);
    EDAssert([newAbsPath isAbsolutePath]);
    
    // determine new tabModel path
    NSString *newModelPath = newAbsPath;
    if ([newAbsPath hasPrefix:srcDirPath]) {
        newModelPath = [self relativeSourceFilePathForAbsoluteSourceFilePath:newAbsPath];
    }
    EDAssert([newModelPath length]);
    
    BOOL didChange = ![tm.URLString isEqualToString:newModelPath];

    if (didChange && store && !comingFromProjSettings) {
        [self updateCurrentFileLocationInHistory];
    }
    
    // handle syntax highlighting concerns
    NSString *ext = [newAbsPath pathExtension];
    BOOL isScript = [ext isEqualToString:@"js"];
    
    if (!isScript) {
        okvc.useDefaultAttributes = YES;
    } else {
        okvc.useDefaultAttributes = NO;
    }
    
    // find new source string and display in text view
    if (didChange) {
        tv.highlightedLineNumber = 0;
        
        NSError *err = nil;
        OKSource *source = [self loadSourceForFileAtPath:newAbsPath error:&err];
        if (!source) {
            EDAssert(err);
            if (err) {
                [self presentFileEncodingDialog:err forFileAtPath:newAbsPath];
            }
        }

        NSScrollView *sv = [tv enclosingScrollView];
        EDAssert(sv);
        [sv setHasVerticalScroller:NO];
        
        TDPerformOnMainThreadAfterDelay(0.0, ^{
            EDAssert(sv);
            [sv setHasVerticalScroller:YES];
        });

        // update tab URL
        [tm setURLString:newModelPath storeInHistory:store];

        [okvc setSourceString:source.text encoding:source.encoding];
        self.selectedTabIndex = self.selectedTabIndex;

        // update history capabilities
        EDHistory *history = self.currentHistory;
        EDAssert(history);
        self.canGoBack = [history canGoBack];
        self.canGoForward = [history canGoForward];

        [self updateWindowTitle];
    }

    // select specified text range (and scroll to visible)
    NSRange selRange;
    
    if (fileLoc.hasSelectedRange) {
        EDAssert(fileLoc.hasSelectedRange);
    
        selRange = fileLoc.selectedRange;

        EDAssert(NSNotFound != selRange.location);
        EDAssert(NSNotFound != selRange.length);

        // just make sure that the sel range is in actual text range (might have changed in another app)
        NSRange txtRange = NSMakeRange(0, [tv.string length]);
        if (NSLocationInRange(NSMaxRange(selRange), txtRange)) {
            if (select) {
                [tv setSelectedRange:selRange];
            }
            
            NSRange scrollRange = selRange;
            if (fileLoc.hasVisibleRange) {
                scrollRange = fileLoc.visibleRange;
            }
            
            EDAssert(NSNotFound != scrollRange.location);
            EDAssert(NSNotFound != scrollRange.length);
            //EDAssert(NSMaxRange(scrollRange) <= [tv.string length]);
            [tv scrollRangeToVisibleIfHidden:scrollRange];
        }
        
    } else {
        NSUInteger lineNum = fileLoc.lineNumber;
        EDAssert(NSNotFound != lineNum);
        EDAssert(lineNum > 0);
        NSRange lineRange = [tv rangeOfNonWhitespaceInLine:lineNum];
        if (NSNotFound == lineRange.location) {
            lineRange = [tv rangeOfLine:lineNum];
        }

        EDAssert(NSNotFound != lineRange.location);
        EDAssert(NSNotFound != lineRange.length);
        EDAssert(NSMaxRange(lineRange) <= [tv.string length]);
        
        selRange = NSMakeRange(NSMaxRange(lineRange), 0);

        EDAssert(NSNotFound != selRange.location);
        EDAssert(NSNotFound != selRange.length);
        EDAssert(NSMaxRange(selRange) <= [tv.string length]);

        if (select) {
            [tv setSelectedRange:selRange];
            [tv scrollRangeToVisibleIfHidden:selRange]; // why is this necessary?
        }
    }
}


- (void)clearDebugInfo {
    EDAssertMainThread();
    EDAssert(_stackTraceViewController);

    self.stackFrameIndex = 0;
    self.frameStack = nil;
    OKViewController *okvc = self.selectedSourceViewController;
    if (okvc) [okvc highlightLineNumber:0 scrollToVisible:NO];
    [_stackTraceViewController clearDebugInfo];
    [self clearLocalVarsDebugInfo];
}


- (void)clearLocalVarsDebugInfo {
    EDAssertMainThread();
    EDAssert(_consoleViewController);
    [_consoleViewController clearDebugInfo];
}


- (void)showFindIndicatorForLineNumber:(NSUInteger)lineNum {
    EDAssertMainThread();
    OKViewController *okvc = self.selectedSourceViewController;
    OKTextView *tv = okvc.textView;

    NSRange flashRange = [tv rangeOfNonWhitespaceInLine:lineNum];
    [tv scrollRangeToVisibleIfHidden:flashRange];
    [tv showFindIndicatorForRange:flashRange];
}


- (OKSource *)tryLoadingFileAtPath:(NSString *)absPath withStringEncoding:(NSStringEncoding)enc error:(NSError **)outErr {
    OKSource *source = nil;
    
    NSString *txt = [NSString stringWithContentsOfFile:absPath encoding:_userSelectedStringEncoding error:outErr];
    if (txt) {
        source = [OKSource sourceWithText:txt encoding:_userSelectedStringEncoding];
    } else {
        
    }
    
    return source;
}


- (void)presentFileEncodingDialog:(NSError *)err forFileAtPath:(NSString *)absPath {
    EDAssert(err);
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        self.fileEncodingDialogController = [[[EDFileEncodingDialogController alloc] init] autorelease];
        _fileEncodingDialogController.delegate = self;
        _fileEncodingDialogController.filePath = absPath;

        [[self window] beginSheet:[_fileEncodingDialogController window] completionHandler:^(NSModalResponse returnCode) {
            if (NSOKButton == returnCode) {
                EDAssert(0 != _userSelectedStringEncoding);
                EDAssert(NSNotFound != _userSelectedStringEncoding);

                NSError *newErr = nil;
                OKSource *source = [self tryLoadingFileAtPath:absPath withStringEncoding:_userSelectedStringEncoding error:&newErr];
                if (source) {
                    [self.selectedSourceViewController setSourceString:source.text encoding:source.encoding];
                } else {
                    [self presentFileEncodingDialog:newErr forFileAtPath:absPath];
                }
            }
        }];
    });
}


- (void)dismissFileEncodingDialog:(NSInteger)returnCode {
    [[self window] endSheet:[_fileEncodingDialogController window] returnCode:returnCode];
}


#pragma mark -
#pragma mark EDFileEncodingDialogControllerDelegate

- (void)fileEncodingDialogControllerDidCancel:(EDFileEncodingDialogController *)fedc {
    EDAssertMainThread();
    EDAssert(fedc == _fileEncodingDialogController);
    EDAssert([_fileEncodingDialogController window]);
    
    self.userSelectedStringEncoding = 0;
    [self dismissFileEncodingDialog:NSCancelButton];
}


- (void)fileEncodingDialogController:(EDFileEncodingDialogController *)fedc didSelectStringEncoding:(NSStringEncoding)enc {
    EDAssertMainThread();
    EDAssert(fedc == _fileEncodingDialogController);
    EDAssert([_fileEncodingDialogController window]);

    self.userSelectedStringEncoding = enc;
    [self dismissFileEncodingDialog:NSOKButton];
}


#pragma mark -
#pragma mark EDCodeRunnerDelegate

- (void)codeRunnerDidStartup:(NSString *)identifier {
    EDAssert([identifier isEqualToString:self.identifier]);
    EDAssertMainThread();
}


- (void)codeRunner:(NSString *)identifier messageFromStdOut:(NSString *)msg {
    EDAssert([identifier isEqualToString:self.identifier]);
    EDAssertMainThread();
    EDAssert(msg);
    
    [_consoleViewController clearPrompt];
    [_consoleViewController append:msg];
    [_consoleViewController appendPrompt];
}


- (void)codeRunner:(NSString *)identifier messageFromStdErr:(NSString *)msg {
    EDAssert([identifier isEqualToString:self.identifier]);
    EDAssertMainThread();
    EDAssert(msg);
    
    [_consoleViewController clearPrompt];
    [_consoleViewController append:msg];
    [_consoleViewController appendPrompt];
}


- (void)codeRunner:(NSString *)identifier didPause:(NSDictionary *)info {
    EDAssert([identifier isEqualToString:self.identifier]);
    EDAssertMainThread();
    
    self.paused = YES;
    self.statusText = NSLocalizedString(@"Paused…", @"");
    self.frameStack = info[XPDebugInfoFrameStackKey];
    
    // highlight in text editor
    {
        NSUInteger lineNum = [info[XPDebugInfoLineNumberKey] unsignedIntegerValue];
        TDAssert(NSNotFound != lineNum);
        
        [self.selectedSourceViewController highlightLineNumber:lineNum scrollToVisible:YES];
    }

    // update console
    {
        TDAssert([_frameStack count]);
        XPStackFrame *frame = _frameStack[0];
        TDAssert(_consoleViewController);
        [_consoleViewController displayStackFrame:frame];
        
        [_consoleViewController appendPrompt];
    }
    
    // update stack trace view
    {
        [_stackTraceViewController displayFrameStack:_frameStack];
    }
}


- (void)codeRunner:(NSString *)identifier didSucceed:(NSDictionary *)info {
    EDAssert([identifier isEqualToString:self.identifier]);
    EDAssertMainThread();
    
    [self clearDebugInfo];
    
    self.statusText = NSLocalizedString(@"Finished Running.", @"");
    
    self.canRun = YES;
    self.canStop = NO;
    self.busy = NO;
    self.paused = NO;
    
    [[self window] makeFirstResponder:self.selectedSourceViewController.textView];
}


- (void)codeRunner:(NSString *)identifier didFail:(NSDictionary *)info {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    EDAssert([identifier isEqualToString:self.identifier]);
    EDAssertMainThread();
    
    NSError *err = info[kEDCodeRunnerErrorKey];
    NSParameterAssert(err);
    NSLog(@"%@", err);
    
    [self clearDebugInfo];
    
    NSUInteger lineNum = [err.userInfo[kEDCodeRunnerLineNumberKey] unsignedIntegerValue];

    OKViewController *okvc = self.selectedSourceViewController;
    [okvc highlightLineNumber:lineNum scrollToVisible:NO];
    
    EDAssert(_consoleViewController);
    if (kEDCodeRunnerCompileTimeError == [err code]) {
        [_consoleViewController append:[err localizedDescription]];
        [_consoleViewController append:[NSString stringWithFormat:@"\nLine: %@", @(lineNum)]];
        
        NSRange lineRange = [okvc.textView rangeOfLine:lineNum];
        NSString *line = [[okvc.textView string] substringWithRange:lineRange];
        [_consoleViewController append:[NSString stringWithFormat:@"\n%@", line]];
        
        NSRange errRange = [err.userInfo[kEDCodeRunnerRangeKey] rangeValue];
        TDAssert(errRange.location > lineRange.location);
        TDAssert(NSMaxRange(errRange) <= NSMaxRange(lineRange)); // ??
        
        NSMutableString *buf = [NSMutableString stringWithString:@"\n"];
        for (NSUInteger i = lineRange.location; i < errRange.location; ++i) {
            [buf appendString:@" "];
        }
        [buf appendString:@"^"];
        
        [_consoleViewController append:buf];
    }
    
    [_codeRunner stop:self.identifier]; // ??
    
    self.statusText = NSLocalizedString(@"Failed.", @"");
    [_consoleViewController removePrompt];
    
    self.canRun = YES;
    self.canStop = NO;
    self.busy = NO;
    self.paused = NO;
    
    [[self window] makeFirstResponder:self.selectedSourceViewController.textView];
}


- (void)codeRunner:(NSString *)identifier didUpdate:(NSDictionary *)info {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    EDAssert([identifier isEqualToString:self.identifier]);
    EDAssertMainThread();

    EDAssert(self.canvasViewController);
    [self.canvasViewController update];
}


#pragma mark -
#pragma mark OKTextViewListDataSource

//+ (NSArray *)triggers {
//    return [NSMutableArray array];
//}


+ (NSArray *)triggers {
    EDAssertMainThread();
    static NSArray *sTriggers = nil;
    if (!sTriggers) {
        sTriggers = [[NSArray alloc] initWithObjects:
                     [OKTrigger triggerWithTemplate:@"var ${name} = ${value}" specifier:@"var"],
                     [OKTrigger triggerWithTemplate:@"sub ${function}(${arg})" specifier:@"sub"],
                     [OKTrigger triggerWithTemplate:@"sub ${function}(${arg})" specifier:@"function"],
                     [OKTrigger triggerWithTemplate:@"sub ${method}(${arg})" specifier:@"method"],
                     [OKTrigger triggerWithTemplate:@"class ${MyClass} : ${object}" specifier:@"class"],
                     [OKTrigger triggerWithTemplate:@"for ${i} in range(${n})" specifier:@"range"],
                     [OKTrigger triggerWithTemplate:@"for ${i} in range(${n})" specifier:@"forin"],
                     [OKTrigger triggerWithTemplate:@"for ${obj} in ${iterable}" specifier:@"forin"],
                     [OKTrigger triggerWithTemplate:@"for ${key},${val} in ${iterable}" specifier:@"forin"],
                     [OKTrigger triggerWithTemplate:@"if ${test}" specifier:@"if"],
                     [OKTrigger triggerWithTemplate:@"else" specifier:@"else"],
                     [OKTrigger triggerWithTemplate:@"else if ${test}" specifier:@"elseif"],
                     [OKTrigger triggerWithTemplate:@"while ${test}" specifier:@"while"],
                     [OKTrigger triggerWithTemplate:@"return ${val}" specifier:@"return"],
                     [OKTrigger triggerWithTemplate:@"import ${module} as ${foo}" specifier:@"importas"],
                     [OKTrigger triggerWithTemplate:@"print(${value})" specifier:@"log"],
                     nil];
    }
    return sTriggers;
}


+ (NSString *)grammarName {
    return @"js";
}


- (NSArray *)filteredTriggersForPrefix:(NSString *)prefix {
    NSAssert([[NSThread currentThread] isMainThread], @"");

    NSAssert(prefix, @"");
    NSUInteger prefixLen = [prefix length];
    if (!prefixLen) return nil;

    NSMutableArray *sortedMatches = [NSMutableArray arrayWithArray:[self unsortedBuiltinTriggersForPrefix:prefix]];
    //[sortedMatches addObjectsFromArray:[self unsortedDynamicTriggersForPrefix:prefix]];
    
    [sortedMatches sortUsingComparator:^NSComparisonResult(OKTrigger *trig1, OKTrigger *trig2) {
        CGFloat score1 = trig1.score;
        CGFloat score2 = trig2.score;
        
        if (score1 > score1) {
            return NSOrderedAscending;
        } else if (score2 > score1) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    return sortedMatches;
}


//- (NSArray *)unsortedDynamicTriggersForPrefix:(NSString *)prefix {
//    TDAssert(_codeRunner);
//    NSRange selRange = [self.selectedSourceViewController.textView selectedRange];
//    NSArray *pats = nil; //[nil completionTriggerPatternsForRange:selRange];
//    NSUInteger c = [pats count];
//    NSMutableArray *triggers = nil;
//    
//    if (c) {
//        triggers = [NSMutableArray arrayWithCapacity:c];
//        
//        for (NSString *pat in pats) {
//            OKTrigger *trig = [OKTrigger triggerWithTemplate:pat];
//            TDAssert(trig);
//            [triggers addObject:trig];
//        }
//    }
//    
//    return triggers;
//}
//
//
//- (NSArray *)completionTriggerPatternsForPrefix:(NSString *)prefix atRange:(NSRange)range {
//    self.interp = [[[XPInterpreter alloc] init] autorelease];
//    NSArray *result = [_interp completionsForPrefix:prefix inRange:range];
//    
//    
//    
//    
//    //    NSMutableSet *found = [NSMutableSet set];
//    //
//    //    XPMemorySpace *space = _interp.currentMemorySpace;
//    //
//    //    while (space) {
//    //        for (NSString *name in [space.members allKeys]) {
//    //            if (![found containsObject:name] && [name hasPrefix:prefix]) {
//    //                [found addObject:name];
//    //
//    //                XPObject *obj = [space.members objectForKey:name];
//    //
//    //                if (obj.isFunctionObject) {
//    //                    NSString *pat = [NSString stringWithFormat:@"%@()", name];
//    //                    [result addObject:pat];
//    //                } else {
//    //                    [result addObject:name];
//    //                }
//    //            }
//    //        }
//    //
//    //        space = space.enclosingSpace;
//    //    }
//    
//    return result;
//}

    
- (NSArray *)unsortedBuiltinTriggersForPrefix:(NSString *)prefix {
    NSUInteger prefixLen = [prefix length];

    //prefix = [prefix lowercaseString];
    NSMutableArray *results = [NSMutableArray array];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:OKAutocompletionFuzzyMatchKey]) {
        for (OKTrigger *trig in [[self class] triggers]) {
            NSString *str = trig.specifier;
            if (prefixLen > [str length]) continue;
            
            if (trig.wantsExactMatch) {
                if (prefixLen >= MIN_AUTOCOMPLETE_EXACT_MATCH_LEN && [str hasPrefix:prefix] && prefixLen <= [str length]) {
                    trig.score = 1.0;
                    [results addObject:trig];
                }
            } else {
                CGFloat score = [str scoreAgainst:prefix fuzziness:@(FUZZINESS) options:NSStringScoreOptionNone];
                if (score >= MIN_SCORE) {
                    trig.score = score;
                    [results addObject:trig];
                }
            }
        }
    } else {
        for (OKTrigger *trig in [[self class] triggers]) {
            NSString *str = trig.specifier;
            if ([str hasPrefix:prefix] && prefixLen <= [str length]) {
                [results addObject:trig];
            }
        }
    }
    
    return results;
}


- (NSUInteger)numberOfItemsInTextView:(OKTextView *)tv {
    NSAssert([[NSThread currentThread] isMainThread], @"");
    NSAssert(tv == self.selectedSourceViewController.textView, @"");
    return [_filteredData count];
}


- (id)textView:(OKTextView *)tv objectAtIndex:(NSUInteger)i {
    NSAssert([[NSThread currentThread] isMainThread], @"");
    NSAssert(tv == self.selectedSourceViewController.textView, @"");
    
    NSUInteger c = [_filteredData count];
    NSAssert(i < c, @"");
    id obj = @"";
    
    // JIC. I've seen this fail. no idea why.
    if (i < c) {
        obj = [_filteredData objectAtIndex:i];
    }
    
    return obj;
}


- (NSString *)textView:(OKTextView *)tv completedString:(NSString *)prefix {
    //NSLog(@"%@", prefix);
    //prefix = [prefix lowercaseString];
    
    NSAssert([[NSThread currentThread] isMainThread], @"");
    NSString *result = nil;
    
    if (tv == self.selectedSourceViewController.textView) {
        self.filteredData = [self filteredTriggersForPrefix:prefix];
        //NSLog(@"filtered Data : %@", _filteredData);
        
        OKTrigger *best = nil;
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:OKAutocompletionFuzzyMatchKey]) {
            if ([_filteredData count]) {
                best = [_filteredData objectAtIndex:0];
            }
            //NSLog(@"%@", best);
        } else {
            for (OKTrigger *trig in _filteredData) {
                NSString *str = trig.specifier;
                if ([str hasPrefix:prefix]) {
                    best = trig;
                    break;
                }
            }
        }
        
        result = best.string;
    }

    return result;
}


#pragma mark -
#pragma mark OKTextViewListDelegate <NSObject>

- (BOOL)textView:(OKTextView *)tv writeDataToPasteboard:(NSPasteboard *)pboard {
    NSURL *URL = [NSURL URLWithString:@"http://apple.com"];
    [URL writeToPasteboard:pboard];
    return YES;
}


- (void)textView:(OKTextView *)tv wantsDocumentationForString:(NSString *)tokStr inRange:(NSRange)tokRange {
    if (tv != self.selectedSourceViewController.textView) return;
    
    EDAssertMainThread();
    EDAssert([tokStr length]);

    //[[self document] saveDocument:nil];

    //NSString *URLString = [NSString stringWithFormat:@"http://google.com/search?btnI=1&pws=0&q=site%%3Adeveloper.apple.com+%@", tokStr];
    NSString *URLString = nil;
    if ([tokStr hasPrefix:@"CG"]) {
        URLString = [NSString stringWithFormat:@"http://google.com/search?pws=0&q=site%%3Adeveloper.apple.com+%@", tokStr];
    } else {
        NSString *root = [[EDUserDefaults instance] documentationHomeURLString];
        URLString = [NSString stringWithFormat:@"%@/search.html?q=%@&check_keywords=yes&area=default", root, tokStr];
    }

    NSError *err = nil;
    if ([self addTabWithContentsOfURLString:URLString type:EDTabModelTypeWebLocation error:&err]) {
        EDWebViewController *wvc = self.selectedTabModel.representedObject;
        EDAssert([wvc isKindOfClass:[EDWebViewController class]]);
        wvc.initialFindPanelTerm = tokStr;
    } else {
        if (err) NSLog(@"%@", err);
    }
}


- (NSString *)documentationHomeURLString {
    NSString *URLString = [[EDUserDefaults instance] documentationHomeURLString];
    return URLString;
}


#pragma mark -
#pragma mark EDConsoleViewControllerDelegate

- (void)console:(EDConsoleViewController *)cvc userIssuedCommand:(NSString *)cmd {
    EDAssertMainThread();
    TDAssert([cmd length]);

    TDAssert(self.paused);
    self.paused = NO;
    
    TDAssert(_codeRunner);
    TDAssert(self.identifier);
    [_codeRunner performCommand:cmd identifier:self.identifier];
}


- (NSString *)promptForConsole:(EDConsoleViewController *)cvc {
    return DEBUGGER_PROMPT;
}


- (BOOL)isConsolePaused:(EDConsoleViewController *)cvc {
    EDAssertMainThread();
    return self.paused;
}


- (NSAttributedString *)console:(EDConsoleViewController *)cvc highlightedStringForString:(NSString *)str {
    EDAssertMainThread();
    OKViewController *okvc = self.selectedSourceViewController;
    NSAttributedString *attrStr = [okvc.highlighter highlightedStringForString:str ofGrammar:@"js"];
    return attrStr;
}


#pragma mark -
#pragma mark EDFilesystemViewControllerDelegate

- (NSString *)projectFilePathForFilesystemViewController:(EDFilesystemViewController *)fsc {
    return [[[self document] fileURL] relativePath];
}


- (void)filesystemViewController:(EDFilesystemViewController *)fsc wantsNewFileInDirPath:(NSString *)dirPath {
    //[[self document] saveDocument:nil];

//    [self.selectedSourceViewController.textView removeListWindow];
    
    [self runNewFileSheetWithDirPath:dirPath];
}


- (void)filesystemViewController:(EDFilesystemViewController *)fsc didActivateItemAtPath:(NSString *)absPath {
    EDAssertMainThread();
    //[[self document] saveDocument:nil];
    
//    [self.selectedSourceViewController.textView removeListWindow];

    if ([absPath isEqualToString:EDProjectSettingsURL]) {
        [self navigateToProjectSettings];
    } else {
        EDAssert([absPath isAbsolutePath]);
        EDAssert([absPath hasPrefix:[self sourceDirPath]]);
        
        if ([self.selectedEDTabModel.type isEqualToString:EDTabModelTypeProjectSettings]) {
            TKTabModel *seltm = nil;
            for (TKTabModel *tm in self.tabModels) {
                if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
                    seltm = tm;
                    break;
                }
            }
            
            if (seltm) {
                self.selectedTabIndex = [self indexOfTabModel:seltm];
            } else {
                NSError *err = nil;
                if (![self addTabWithContentsOfURLString:absPath type:EDTabModelTypeSourceCodeFile error:&err]) {
                    if (err) NSLog(@"%@", err);
                }
            }
        }
        
        EDAssert(_lastFileLocByAbsPath);
        EDFileLocation *fileLoc = _lastFileLocByAbsPath[absPath];
        if (!fileLoc) {
            fileLoc = [EDFileLocation fileLocationWithURLString:absPath selectedRange:NSMakeRange(0, 0) visibleRange:NSMakeRange(0, 0)];
        }
        BOOL store = YES;
        if ([absPath isEqualToString:[self absolutePathForTabModel:self.selectedTabModel]]) {
            store = NO;
        }
        [self navigateToFileLocationInCurrentTab:fileLoc andSelect:YES storeInHistory:store];
    }
}


- (void)filesystemViewController:(EDFilesystemViewController *)fsc didDeleteItemAtPath:(NSString *)oldPath andActivateItemAtPath:(NSString *)newPath {
    EDBreakpointCollection *bpcoll = [[self document] breakpoints];
    
    [bpcoll removeBreakpointsForFile:oldPath];
    
    TKTabModel *seltm = self.selectedTabModel;
    for (TKTabModel *tm in self.tabModels) {
        if (tm == seltm) continue;
        
        if ([[self absolutePathForTabModel:tm] isEqualToString:oldPath]) {
            [self closeTab:tm];
        }
    }

    newPath = newPath ? newPath : [self mainSourceFilePath];
    EDFileLocation *fileLoc = [EDFileLocation fileLocationWithURLString:newPath];
    [self navigateToFileLocationInCurrentTab:fileLoc];
}


- (void)filesystemViewController:(EDFilesystemViewController *)fsc willCopyItemFromPath:(NSString *)oldPath toPath:(NSString *)newPath {
}


- (void)filesystemViewController:(EDFilesystemViewController *)fsc didCopyItemFromPath:(NSString *)oldPath toPath:(NSString *)newPath {
}


- (void)filesystemViewController:(EDFilesystemViewController *)fsc willMoveItemFromPath:(NSString *)oldAbsPath toPath:(NSString *)newAbsPath {
    EDAssertMainThread();

    BOOL isDir;
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr fileExistsAtPath:oldAbsPath isDirectory:&isDir];
    if (isDir) {
        [[self document] saveDocument:nil];
        [self saveAllDirtyFiles];
    } else {
        if ([self isFileDirtyAtPath:oldAbsPath]) {
            OKSource *source = [self loadSourceForFileAtPath:oldAbsPath error:nil];
            [self storeInMemorySource:source forFileAtPath:newAbsPath];
        }
    }
}


- (void)filesystemViewController:(EDFilesystemViewController *)fsc didMoveItemFromPath:(NSString *)oldAbsPath toPath:(NSString *)newAbsPath {
    EDAssertMainThread();
    
    BOOL isDir;
    NSFileManager *mgr = [NSFileManager defaultManager];
    if ([mgr fileExistsAtPath:newAbsPath isDirectory:&isDir]) {
        if (isDir) return;
    } else {
        EDAssert(0); // should not reach
    }
    
    NSString *oldRelPath = [self relativeSourceFilePathForAbsoluteSourceFilePath:oldAbsPath];
    NSString *newRelPath = [self relativeSourceFilePathForAbsoluteSourceFilePath:newAbsPath];
    
    // update breakpoints for changed file path
    EDBreakpointCollection *bpcoll = [[self document] breakpoints];
    
    NSSet *bps = [[[bpcoll breakpointsForFile:oldRelPath] retain] autorelease];
    [bpcoll removeBreakpointsForFile:oldRelPath];
    
    for (OKBreakpoint *bp in bps) {
        EDAssert([bp.file isEqualToString:oldRelPath]);
        bp.file = newRelPath;
        [bpcoll addBreakpoint:bp];
    }
    
    OKSource *source = [self loadSourceForFileAtPath:newAbsPath error:nil];
    
    // find tab model for changed file path and update it
    EDTabModel *oldtm = [self lastModifiedTabModelForAbsolutePath:oldAbsPath];
    NSUInteger idx = [self.tabModels indexOfObject:oldtm];
    EDAssert(NSNotFound != idx);

    NSError *err = nil;
    TKTabModel *newtm = [[self newTabModelWithContentsOfURLString:newAbsPath type:EDTabModelTypeSourceCodeFile error:&err] autorelease];
    
    if (newtm) {
        [self removeTabModel:oldtm];
        [self addTabModel:newtm atIndex:idx];
        [newtm.representedObject setSourceString:source.text encoding:source.encoding clearUndo:YES];
    } else {
        if (err) NSLog(@"%@", err);
    }

    //[[self document] saveDocument:nil];
}


- (BOOL)filesystemViewController:(EDFilesystemViewController *)fsc isItemDirtyAtPath:(NSString *)absPath {
    EDAssertMainThread();
    BOOL dirty = [self isFileDirtyAtPath:absPath];
    return dirty;
}


#pragma mark -
#pragma mark EDStackTraceViewControllerDelegate

- (void)stackTraceViewController:(EDStackTraceViewController *)stvc didActivateFileLocation:(EDFileLocation *)fileLoc stackFrameIndex:(NSUInteger)idx {
    EDAssertMainThread();
    EDAssert(_stackTraceViewController == stvc);
    EDAssert(fileLoc);
    EDAssert(NSNotFound != idx);
    
    self.stackFrameIndex = idx;
    [self navigateToFileLocationInCurrentTab:fileLoc];
    [self showFindIndicatorForLineNumber:fileLoc.lineNumber];
    
    TDAssert(_frameStack);
    XPStackFrame *frame = _frameStack[idx];

    TDAssert(_consoleViewController);
    [_consoleViewController displayStackFrame:frame];
}


- (NSString *)sourceDirPathForStackTraceViewController:(EDStackTraceViewController *)stvc {
    EDAssertMainThread();
    return [self sourceDirPath];
}

#pragma mark -
#pragma mark EDBreakpointListViewControllerDelegate

- (void)breakpointListViewController:(EDBreakpointListViewController *)bplc didActivateFileAtPath:(NSString *)path lineNumber:(NSUInteger)lineNum {
    EDAssert([path length]);
    EDAssert(![path hasPrefix:[self sourceDirPath]]);
    path = [[self sourceDirPath] stringByAppendingPathComponent:path];
    
    EDFileLocation *fileLoc = [EDFileLocation fileLocationWithURLString:path lineNumber:lineNum];
    [self navigateToFileLocationInCurrentTab:fileLoc];
    [self showFindIndicatorForLineNumber:lineNum];
}


#pragma mark -
#pragma mark EDFindViewControllerDelegate

- (NSString *)searchDirPathForFindViewController:(EDFindViewController *)fvc {
    return [self sourceDirPath];
}


- (NSString *)searchFilePathForFindViewController:(EDFindViewController *)fvc {
    return [self absolutePathForTabModel:self.selectedTabModel];
}


- (void)findViewControllerWillSearch:(EDFindViewController *)fvc {
    EDAssertMainThread();
//    [self.selectedSourceViewController.textView removeListWindow];
    [[self document] saveDocument:nil];
    [self saveAllDirtyFiles];
}


- (void)findViewControllerDidSearch:(EDFindViewController *)fvc {
    EDAssertMainThread();
    
    if (!fvc.searchEntireProject) {
        // display search results
        NSString *absPath = [self absolutePathForTabModel:self.selectedTabModel];
        NSArray *results = [[fvc searchResults] objectForKey:absPath];
        
//        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSFindPboard];
//        [pboard declareTypes:@[NSPasteboardTypeString, NSPasteboardTypeTextFinderOptions] owner:nil];
//        
//        NSString *newSearchStr = [fvc.searchComboBox stringValue];
//        [pboard setString:newSearchStr forType:NSStringPboardType];
        
        // first, update the command-E search string in text view so it's synced to the last find string (whether there were results found or not)
        OKTextView *tv = self.selectedSourceViewController.textView;
        EDAssert([fvc.searchComboBox tag] == NSTextFinderActionSetSearchString);
        [tv performFindPanelAction:fvc.searchComboBox];

        if ([results count]) {
            // then, navigate to location
            EDFileLocation *fileLoc = nil;
            if (_findNextFileLocation) {
                fileLoc = [[_findNextFileLocation retain] autorelease];
                self.findNextFileLocation = nil;
            } else {
                fileLoc = results[0];
            }
            
            EDAssert(fileLoc);
            [_findViewController selectResultFileLocation:fileLoc];
            [self findViewController:fvc didActivateFileLocation:fileLoc];
            
            // finally, focus tv
            [[self window] makeFirstResponder:tv];
        }
    }
}


- (OKSource *)findViewController:(EDFindViewController *)fvc sourceForFileAtPath:(NSString *)absPath error:(NSError **)outErr {
    OKSource *source = [self loadSourceFromDiskForFileAtPath:absPath error:outErr];
    return source;
}


- (void)findViewController:(EDFindViewController *)fvc didUpdateSource:(OKSource *)source forFileAtPath:(NSString *)absPath {
    [self storeInMemorySource:source forFileAtPath:absPath];
}


- (void)findViewController:(EDFindViewController *)fvc didActivateFileLocation:(id)fileLoc {
    EDAssertMainThread();

    [self navigateToFileLocationInCurrentTab:fileLoc andSelect:YES storeInHistory:NO];
    OKViewController *okvc = self.selectedSourceViewController;
    OKTextView *tv = okvc.textView;
    NSRange r = [tv selectedRange];
    [tv showFindIndicatorForRange:r];
}


- (void)findViewControllerDidDismiss:(EDFindViewController *)fvc {
    EDAssertMainThread();
    [self hideFindView:nil];
}


- (void)findViewController:(EDFindViewController *)fvc willStartReplacingInFiles:(NSArray *)filePaths {
    EDAssertMainThread();

    // files should have been saved before search
#if !defined(NDEBUG)
    for (NSString *absPath in filePaths) {
        EDAssert(![self dirtySourceForFilePath:absPath]);
    }
#endif
}


- (void)findViewController:(EDFindViewController *)fvc didFinishReplacingInFiles:(NSArray *)filePaths {
    EDAssertMainThread();
    
    for (NSString *absPath in filePaths) {
        // files should have been saved before search
        EDAssert(![self dirtySourceForFilePath:absPath]);

        // if any of these files is resident in tabs,
        // reload the source text from disk and re-insert in the text views
        EDTabModel *tm = [self lastModifiedTabModelForAbsolutePath:absPath];
        if (!tm) continue;
        
        NSError *err = nil;
        OKSource *source = [self loadSourceForFileAtPath:absPath error:&err];
        if (!source) {
            if (err) NSLog(@"%@", err);
        } else {
            OKViewController *okvc = tm.representedObject;
            [okvc setSourceString:source.text encoding:source.encoding clearUndo:YES];
        }
    }
}


#pragma mark -
#pragma mark Actions

//- (BOOL)canGoBack {
//    EDHistory *history = self.currentHistory;
//    return history && [history canGoBack];
//}
//
//
//- (BOOL)canGoForward {
//    EDHistory *history = self.currentHistory;
//    return history && [history canGoForward];
//}


- (void)updateCurrentFileLocationInHistory {
    //[[self document] saveDocument:nil];
    
    EDTabModel *tm = self.selectedEDTabModel;
    
    if ([EDTabModelTypeSourceCodeFile isEqualToString:tm.type]) {
        EDFileLocation *currFileLoc = [tm.history current];
        if (currFileLoc) {
            OKViewController *okvc = tm.representedObject;
            EDAssert(okvc);
            OKTextView *tv = okvc.textView;
            EDAssert(tv);
            
            NSRange selRange = [tv selectedRange];
            currFileLoc.selectedRange = selRange;
            EDAssert(NSNotFound != selRange.location);
            EDAssert(NSNotFound != selRange.length);
            
            NSRange visRange = [tv visibleRange];
            currFileLoc.visibleRange = visRange;
            EDAssert(NSNotFound != visRange.location);
            EDAssert(NSNotFound != visRange.length);

            EDAssert(_lastFileLocByAbsPath);
            NSString *absPath = [self absolutePathForTabModel:tm];
            _lastFileLocByAbsPath[absPath] = currFileLoc;
        }
    } else {
        EDAssert(0);
    }
}


- (IBAction)goBack:(id)sender {
    NSInteger tag = [sender tag];
    EDAssert(tag > 0);
    
    EDHistory *history = self.currentHistory;
    EDAssert(history);
    EDAssert([history canGoBack]);
    if ([history canGoBack]) {
        [self updateCurrentFileLocationInHistory];
        EDFileLocation *fileLoc = [history goBackBy:tag];
        [self navigateToFileLocationInCurrentTab:fileLoc andSelect:YES storeInHistory:NO];
    }
}


- (IBAction)goForward:(id)sender {
    NSInteger tag = [sender tag];
    EDAssert(tag > 0);

    EDHistory *history = self.currentHistory;
    EDAssert(history);
    EDAssert([history canGoForward]);
    if ([history canGoForward]) {
        [self updateCurrentFileLocationInHistory];
        EDFileLocation *fileLoc = [history goForwardBy:tag];
        [self navigateToFileLocationInCurrentTab:fileLoc andSelect:YES storeInHistory:NO];
    }
}


- (IBAction)editProjectSettings:(id)sender {
    EDAssertMainThread();
    [self navigateToProjectSettings];
    [self syncFilesystemViewWithSelectedTab];
}


- (IBAction)newREPLTab:(id)sender {
    NSError *err = nil;
    if (![self addTabWithContentsOfURLString:@"REPL" type:EDTabModelTypeREPL error:&err]) {
        NSLog(@"%@", err);
    }
}


- (IBAction)newTab:(id)sender {
    NSString *URLString = nil;
    NSString *type = self.selectedTabModel.type;

    NSRange selRange = NSMakeRange(0, 0);
    if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        selRange = [self.selectedSourceViewController.textView selectedRange];
        EDAssert(NSNotFound != selRange.location);
        URLString = [self absolutePathForTabModel:self.selectedTabModel];
    } else {
        URLString = [self mainSourceFilePath];
    }
    
    NSError *err = nil;
    if ([self addTabWithContentsOfURLString:URLString type:EDTabModelTypeSourceCodeFile error:&err]) {
        OKTextView *tv = self.selectedSourceViewController.textView;
        EDAssert(NSMaxRange(selRange) <= [[tv string] length]);
        [tv setSelectedRange:selRange];
        [tv scrollRangeToVisibleIfHidden:selRange];
    } else {
        NSLog(@"%@", err);
    }
}


- (IBAction)newFile:(id)sender {
    NSString *dirPath = [self sourceDirPath];
    EDAssert([dirPath length]);
    [self runNewFileSheetWithDirPath:dirPath];
}


- (IBAction)contine:(id)sender {
    EDAssertMainThread();
    [self clearDebugInfo];
    
    TDAssert(self.paused);
    self.paused = NO;
    
    [self.codeRunner performCommand:@"c" identifier:self.identifier];
}


- (IBAction)next:(id)sender {
    EDAssertMainThread();
    [self clearDebugInfo];

    TDAssert(self.paused);
    self.paused = NO;

    [self.codeRunner performCommand:@"n" identifier:self.identifier];
}


- (IBAction)step:(id)sender {
    EDAssertMainThread();
    [self clearDebugInfo];

    TDAssert(self.paused);
    self.paused = NO;

    [self.codeRunner performCommand:@"s" identifier:self.identifier];
}


- (IBAction)finish:(id)sender {
    EDAssertMainThread();
    [self clearDebugInfo];

    TDAssert(self.paused);
    self.paused = NO;

    [self.codeRunner performCommand:@"r" identifier:self.identifier];
}


- (IBAction)activateConsole:(id)sender {
    EDAssertMainThread();
    EDAssert(_consoleViewController.textView);
    
    if (![[EDUserDefaults instance] consoleViewVisible]) {
        [[EDDocumentController instance] toggleConsoleViewVisible:nil];
    }
    
    [self showConsoleView];
    
    NSTextView *tv = _consoleViewController.textView;
    [[self window] makeFirstResponder:tv];
    [tv setSelectedRange:NSMakeRange([[tv string] length], 0)];
}


- (IBAction)hideFindView:(id)sender {
    EDAssertMainThread();
    [self showConsoleView];
    OKViewController *okvc = self.selectedSourceViewController;
    OKTextView *tv = okvc.textView;
    [[self window] makeFirstResponder:tv];
}


- (IBAction)run:(id)sender {
    EDAssertMainThread();
    
    if (!self.canRun) {
        NSBeep();
        return;
    }
    
    [self stop:nil];
    [self clearDebugInfo];

    self.canRun = NO;
    self.canStop = YES;
    self.busy = YES;
    self.paused = NO;
    
    [self showConsoleView];

    [self clear:nil];
    
    EDDocument *doc = [self document];
    [doc saveDocument:nil]; // write source to disk
    [self saveAllDirtyFiles];
    
    [self.selectedSourceViewController refresh:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        EDAssertMainThread();

        BOOL bpEnabled = doc.breakpointsEnabled;

        id bpPlist = nil;
        if (bpEnabled) bpPlist = [self allEnabledBreakpointsPlist];
        EDAssert(bpEnabled || !bpPlist);

        EDRunAction *runAction = doc.selectedTarget.scheme.runAction;
        
        NSString *cmd = [self evaluatedCommandString:runAction.commandString];
        
        NSArray *envVars = runAction.environmentVariables;
        NSDictionary *envVarsTab = [self envVarsDictFromArray:envVars];
        
        NSString *srcDirPath = [self sourceDirPath];
        NSString *identifier = self.identifier;
        
        [self killCodeRunner];
        
        self.codeRunner = [[[EDMemoryCodeRunner alloc] initWithDelegate:self] autorelease];
        [_codeRunner run:cmd inWorkingDirectory:srcDirPath exePath:nil env:envVarsTab breakpointsEnabled:bpEnabled breakpoints:bpPlist identifier:identifier];
    });
}


- (NSString *)evaluatedCommandString:(NSString *)inStr {
    NSString *srcDirPath = self.sourceDirPath;
    NSString *rootDirPath = [srcDirPath stringByDeletingLastPathComponent];
    
    NSMutableString *mStr = [NSMutableString stringWithString:inStr];
    [mStr replaceOccurrencesOfString:@"$(PROJECT_SOURCE_DIR)" withString:srcDirPath options:0 range:NSMakeRange(0, [mStr length])];
    [mStr replaceOccurrencesOfString:@"$(PROJECT_ROOT_DIR)" withString:rootDirPath options:0 range:NSMakeRange(0, [mStr length])];

    NSString *outStr = [mStr stringByStandardizingPath]; // cleans up dupe slashes
    return outStr;
}


- (IBAction)stop:(id)sender {
    EDAssertMainThread();
    
    if (!self.canStop) {
        return;
    }

    [_codeRunner stop:self.identifier];
    [self clearDebugInfo];
    
    self.statusText = NSLocalizedString(@"Stopped.", @"");
    [_consoleViewController removePrompt];

    self.canRun = YES;
    self.canStop = NO;
    self.busy = NO;
    self.paused = NO;
}


- (IBAction)clear:(id)sender {
    EDAssert(_consoleViewController);

    [_consoleViewController clear:nil];
    self.statusText = @"";
    
    id repObj = self.selectedTabModel.representedObject;
    if ([repObj respondsToSelector:@selector(clear:)]) {
        [repObj clear:sender];
    }
}


- (IBAction)toggleBreakpointsEnabled:(id)sender {
    EDAssertMainThread();
    EDDocument *doc = [self document];
    EDAssert(doc);
    
    BOOL newVal = !doc.breakpointsEnabled;
    doc.breakpointsEnabled = newVal;
    
    NSButton *b = nil;
    if ([sender isKindOfClass:[NSButton class]]) {
        b = sender;
    } else {
        b = _breakpointsEnabledToolbarItem.button;
    }
    [b setState:newVal ? NSOnState : NSOffState];
    
    [self fireBreakpointsDidChange];
}


- (IBAction)findInFile:(id)sender {
    EDAssertMainThread();
    
    NSString *type = self.selectedTabModel.type;
    if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        [self showFindView];
        _findViewController.searchEntireProject = NO;
    } else {
        EDAssert(0);
        NSBeep();
    }
}


- (IBAction)findInProject:(id)sender {
    EDAssertMainThread();
    
    NSString *type = self.selectedTabModel.type;
    if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        [self showFindView];
        _findViewController.searchEntireProject = YES;
    } else {
        EDAssert(0);
        NSBeep();
    }
}


- (IBAction)findAndReplaceInFile:(id)sender {
    EDAssertMainThread();
    
    NSString *type = self.selectedTabModel.type;
    if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        [self showFindView];
        _findViewController.searchEntireProject = NO;
    } else {
        EDAssert(0);
        NSBeep();
    }
}


- (IBAction)findAndReplaceInProject:(id)sender {
    EDAssertMainThread();
    
    NSString *type = self.selectedTabModel.type;
    if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        [self showFindView];
        _findViewController.searchEntireProject = YES;
    } else {
        EDAssert(0);
        NSBeep();
    }
}


- (IBAction)myFindPanelAction:(id)sender {
    NSInteger tag = [sender tag];
    
    switch (tag) {
        case NSTextFinderActionShowFindInterface:
            [self performFindPanelAction:sender];
            break;
        case NSTextFinderActionShowReplaceInterface:
            [self findAndReplaceInFile:sender];
            break;

        case NSTextFinderActionSetSearchString:
        case NSTextFinderActionPreviousMatch:
        case NSTextFinderActionNextMatch: {
            NSString *type = self.selectedTabModel.type;
            
            if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
                [self hideFindView:nil];
                
                // defer to text view
                OKTextView *tv = self.selectedSourceViewController.textView;
                [tv performFindPanelAction:sender];
            } else if ([type isEqualToString:EDTabModelTypeWebLocation]) {
                EDWebViewController *wvc = self.selectedTabModel.representedObject;
                [wvc performFindPanelAction:sender];
            }
            
        } break;
            
        default:
            [self performFindPanelAction:sender];
            break;
    }
}


- (BOOL)isView:(id)v descendantOfView:(id)target {
    BOOL result = NO;

    do {
        if (v == target) {
            result = YES;
            break;
        }
    } while (nil != (v = [v superview]));

    return result;
}


- (IBAction)performFindPanelAction:(id)sender {
    TKTabModel *tm = self.selectedTabModel;
    NSString *type = tm.type;
    
    if ([type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        id resp = [[self window] firstResponder];
        if (resp == _consoleViewController.textView || [self isView:resp descendantOfView:_consoleViewController.view]) {
            [_consoleViewController.textView performFindPanelAction:sender];
        } else {
            [self findInFile:sender];
        }
    
    } else if ([type isEqualToString:EDTabModelTypeWebLocation]) {
        EDWebViewController *wvc = tm.representedObject;
        [wvc performFindPanelAction:sender];

    } else {
        EDAssert(0);
    }
}


- (IBAction)showReference:(id)sender {
    NSString *path = [self documentationHomeURLString];
    
    EDTabModel *seltm = nil;
    
    for (EDTabModel *tm in self.tabModels) {
        if ([EDTabModelTypeWebLocation isEqualToString:tm.type] && [tm.URLString hasSuffix:path]) {
            self.selectedTabIndex = tm.index;
            seltm = tm;
            break;
        }
    }

    if (!seltm) {
        NSError *err = nil;
        if (![self addTabWithContentsOfURLString:path type:EDTabModelTypeWebLocation error:&err]) {
            NSLog(@"%@", err);
        }
        seltm = self.selectedEDTabModel;
    }
    
    if (seltm) {
        EDWebViewController *wvc = seltm.representedObject;
        EDAssert([wvc isKindOfClass:[EDWebViewController class]]);
        [wvc openLocation:nil];
    }
}


- (IBAction)showFilesystemNavigator:(id)sender {
    if (![[EDUserDefaults instance] navigatorViewVisible]) {
        [[EDDocumentController instance] toggleNavigatorVisible:nil];
    }
    
    [self.navigatorTabBarController setSelectedIndex:0];
    [self navigateToSourceDir];
}


- (IBAction)showStackTraceNavigator:(id)sender {
    if (![[EDUserDefaults instance] navigatorViewVisible]) {
        [[EDDocumentController instance] toggleNavigatorVisible:nil];
    }
    
    [self.navigatorTabBarController setSelectedIndex:1];
}


- (IBAction)showBreakpointListNavigator:(id)sender {
    if (![[EDUserDefaults instance] navigatorViewVisible]) {
        [[EDDocumentController instance] toggleNavigatorVisible:nil];
    }
    
    [self.navigatorTabBarController setSelectedIndex:2];
}


- (BOOL)validateMenuItem:(NSMenuItem *)item {
    BOOL enabled = YES;
    
    SEL action = [item action];
    
    if (@selector(run:) == action) {
        enabled = self.canRun;
    } else if (@selector(stop:) == action) {
        enabled = self.canStop;
    } else if (@selector(toggleBreakpointsEnabled:) == action) {
        BOOL bpEnabled = [[self document] breakpointsEnabled];
        [item setTitle:bpEnabled ? NSLocalizedString(@"Deactivate Breakpoints", @"") : NSLocalizedString(@"Activate Breakpoints", @"")];
    } else if (@selector(contine:) == action) {
        enabled = self.canStop;
    } else if (@selector(next:) == action) {
        enabled = self.canStop;
    } else if (@selector(step:) == action) {
        enabled = self.canStop;
    } else if (@selector(finish:) == action) {
        enabled = self.canStop;
    } else if (@selector(goBack:) == action) {
        enabled = [self canGoBack];
    } else if (@selector(goForward:) == action) {
        enabled = [self canGoForward];
    } else if (@selector(findInProject:) == action || @selector(findAndReplaceInProject:) == action) {
        enabled = [self.selectedTabModel.type isEqualToString:EDTabModelTypeSourceCodeFile];
    }
    
    return enabled;
}


- (IBAction)editProject:(id)sender {
    [self runNewProjectSheet];
}


#pragma mark -
#pragma mark New File Sheet

- (void)runNewFileSheetWithDirPath:(NSString *)dirPath {
    EDAssertMainThread();
    EDAssert([dirPath length]);
    
    if (!_fileWindowController) {
        self.fileWindowController = [[[EDFileWindowController alloc] init] autorelease];
    }
    
    [NSApp beginSheet:[_fileWindowController window]
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(fileSheetDidEnd:returnCode:contextInfo:)
          contextInfo:[dirPath retain]]; // +1
}



- (void)fileSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSString *)dirPath {
    EDAssertMainThread();
    EDAssert(_fileWindowController);
    EDAssert([_fileWindowController window] == sheet);
    
    [dirPath autorelease]; // -1
    
    BOOL ok = NSOKButton == returnCode;
    if (ok) {
        NSString *filename = _fileWindowController.filename;
        EDAssert([filename length]);
        EDAssert([[filename pathExtension] isEqualToString:@"js"]);
        
        NSFileManager *mgr = [NSFileManager defaultManager];
        
        NSString *fullPath = [dirPath stringByAppendingPathComponent:filename];
        
        // if already exists
        if ([mgr fileExistsAtPath:fullPath]) {
            [self runOverwriteFileSheet:fullPath];
        }
        
        // save success
        else if ([self createFileAtPath:fullPath]) {
            [self orderOutFileSheet];
        }
    } else {
        [self orderOutFileSheet];
    }
}


- (void)orderOutFileSheet {
    EDAssertMainThread();
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        EDAssert(_fileWindowController);
        [[_fileWindowController window] orderOut:self];
        self.fileWindowController = nil;
    });
}


- (void)runOverwriteFileSheet:(NSString *)fullPath {
    EDAssertMainThread();
    EDAssert([fullPath length]);
    
    NSString *filename = [fullPath lastPathComponent];
    EDAssert([filename length]);
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"“%@” already exists. Do you want to replace it?", @""), filename];
    NSString *defaultBtn = NSLocalizedString(@"Cancel", @"");
    NSString *altBtn = NSLocalizedString(@"Replace", @"");
    NSString *msgFmt = NSLocalizedString(@"A file or folder with the same name already exists in the folder %@. Replacing it will overwrite its current contents.", @"");
    
    EDAssert([[_fileWindowController window] isVisible]);
    NSBeginCriticalAlertSheet(title, defaultBtn, altBtn, nil, [_fileWindowController window],
                              self,
                              @selector(overwriteFileSheetDidEnd:returnCode:contextInfo:), nil,
                              [fullPath retain], // +1
                              msgFmt, filename);
}


- (void)overwriteFileSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSString *)fullPath {
    EDAssertMainThread();
    EDAssert([fullPath length]);

    [fullPath autorelease]; // -1
    
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        
        // Cancel is default
        if (NSAlertDefaultReturn == returnCode) {
            [self runNewFileSheetWithDirPath:[fullPath stringByDeletingLastPathComponent]];
        }
        
        // else save
        else if ([self createFileAtPath:fullPath]) {
            [self orderOutFileSheet];
        }
    });
}


- (BOOL)createFileAtPath:(NSString *)fullPath {
#if MULTI_FILE_ENABLED
    EDAssertMainThread();
    EDAssert([fullPath length]);
    
    NSString *filename = [fullPath lastPathComponent];
    EDAssert([filename length]);
    
    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    if ([mgr fileExistsAtPath:fullPath]) {
        
        NSURL *furl = [NSURL fileURLWithPath:fullPath];
        if (![mgr trashItemAtURL:furl resultingItemURL:nil error:&err]) {
            if (err) NSLog(@"%@", err);
            
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Could not overwrite “%@”", @""), filename];
            NSString *defaultBtn = NSLocalizedString(@"OK", @"");
            NSString *altBtn = nil; //NSLocalizedString(@"Cancel", @"");
            NSString *otherBtn = nil;
            NSString *msg = [err localizedDescription];
            
            NSRunAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
            return NO;
        }
    }
    
    err = nil;
    if (![mgr createFileAtPath:fullPath contents:nil attributes:nil]) {
        if (err) NSLog(@"%@", err);
        
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Could not create file “%@”", @""), filename];
        NSString *defaultBtn = NSLocalizedString(@"OK", @"");
        NSString *altBtn = nil; //NSLocalizedString(@"Cancel", @"");
        NSString *otherBtn = nil;
        NSString *msg = err ? [err localizedDescription] : @"";
        
        NSRunAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
        return NO;
    }
    
    EDFileLocation *fileLoc = [EDFileLocation fileLocationWithURLString:fullPath lineNumber:1];
    [self navigateToFileLocationInCurrentTab:fileLoc];
    
    [_filesystemViewController reloadData];
    [self syncFilesystemViewWithSelectedTab];
#endif

    return YES;
}


#pragma mark -
#pragma mark OKGutterViewDelegate

- (void)captureBreakpointsForUndoInGutterView:(OKGutterView *)gv {
    EDDocument *doc = [self document];
    id oldbps = [[[doc breakpoints] copy] autorelease];
    doc.breakpoints = oldbps;
    
    //[[[doc undoManager] prepareWithInvocationTarget:doc] setBreakpoints:oldbps];
}


- (void)gutterView:(OKGutterView *)gv didAddBreakpoint:(OKBreakpoint *)bp {
    EDAssertMainThread();
    EDAssert(bp);
    
    TKTabModel *tm = self.selectedTabModel;
    NSString *filePath = tm.URLString;

    if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile] && [[filePath pathExtension] isEqualToString:@"js"]) {
        EDAssert([filePath hasSuffix:[bp.file lastPathComponent]]);
        
        EDDocument *doc = [self document];
        EDBreakpointCollection *bpcoll = [doc breakpoints];

#ifndef APPSTORE
        if (![[EDDocumentController instance] isLicensed]) {
            NSUInteger c = [[bpcoll allBreakpoints] count];
            
            if (c >= MAX_NUM_BREAKPOINTS) {
                [[EDDocumentController instance] runNagDialog];
                return;
            }
        }
#endif

        [bpcoll addBreakpoint:bp];
        [doc setBreakpointsEnabled:YES];
        [self updateBreakpointsEnabledToolbarItem];
        [self fireBreakpointsDidChange];
    }
}


- (void)gutterView:(OKGutterView *)gv didRemoveBreakpoint:(OKBreakpoint *)bp {
    EDAssertMainThread();
    EDAssert(bp);
    
    EDAssert([self.selectedTabModel.URLString hasSuffix:bp.file]);
    
    EDBreakpointCollection *bpColl = [[self document] breakpoints];
    EDAssert(bpColl);
    [bpColl removeBreakpoint:bp];
    
    [self fireBreakpointsDidChange];
}


- (void)gutterView:(OKGutterView *)gv didToggleBreakpoint:(OKBreakpoint *)bp {
    EDAssertMainThread();
    EDAssert(bp);
    
    bp.enabled = !bp.enabled;

    [self fireBreakpointsDidChange];
}


- (NSDictionary *)defaultAttributesForGutterView:(OKGutterView *)gv {
    return [[[[EDThemeManager instance] selectedTheme] attributes] objectForKey:@".default"];
}


- (NSString *)filePathForGutterView:(OKGutterView *)gv {
    NSString *path = self.selectedTabModel.URLString;
    return path;
}


- (NSDictionary *)breakpointsForGutterView:(OKGutterView *)gv {
    EDAssert([[self document] breakpoints]);
    
    NSDictionary *result = nil;

    NSString *filePath = [self filePathForGutterView:gv];
    if (filePath) {
        result = [[[self document] breakpoints] breakpointsDictionaryForFile:filePath];
    }
    return result;
}


- (BOOL)breakpointsEnabledForGutterView:(OKGutterView *)gv {
    return [[self document] breakpointsEnabled];
}


- (void)fireBreakpointsDidChange {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:EDBreakpointsDidChangeNotification object:[self document]];
}


- (void)breakpointsDidChange:(NSNotification *)n {
    if (_codeRunner) {
        NSArray *bpPlist = nil;
        
        if ([[self document] breakpointsEnabled]) {
            bpPlist = [self allEnabledBreakpointsPlist];
        }
        
        [_codeRunner setAllBreakpoints:bpPlist identifier:self.identifier];
    }

    TKTabModel *tm = self.selectedTabModel;
    if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        [self.selectedSourceViewController.gutterView setNeedsDisplay:YES];
    }
}


- (void)didSetBreakpoints {
    EDAssertMainThread();
    EDAssert(_breakpointListViewController);
    EDDocument *doc = [self document];
    _breakpointListViewController.collection = doc.breakpoints;
    [_breakpointListViewController reloadData];
}


- (NSString *)absolutePathForTabModel:(TKTabModel *)tm {
    EDAssert(tm);
    EDAssert([tm.URLString length]);
    
    NSString *absPath = tm.URLString;
    
    BOOL isAbsolute = [absPath isAbsolutePath] || [absPath hasSupportedSchemePrefix];
    if (!isAbsolute) {
        absPath = [self absoluteSourceFilePathForRelativeSourceFilePath:tm.URLString];
    }
    return absPath;
}


- (NSString *)absoluteSourceFilePathForRelativeSourceFilePath:(NSString *)relPath {
    EDAssert(![relPath isAbsolutePath]);
    
    NSString *absPath = nil;
    
    if ([EDProjectSettingsURL isEqualToString:relPath]) {
        absPath = relPath;
    } else {
        absPath = [[self sourceDirPath] stringByAppendingPathComponent:relPath];
        EDAssert([absPath isAbsolutePath]);
    }

    return absPath;
}


- (NSString *)relativeSourceFilePathForAbsoluteSourceFilePath:(NSString *)absPath {
    EDAssert([absPath isAbsolutePath]);
    
    NSString *srcDirPath = [self sourceDirPath];
    NSUInteger c = [srcDirPath length];
    EDAssert(NSNotFound != c && c > 0);
    
    EDAssert([absPath hasPrefix:srcDirPath]);
    
    NSString *relPath = [absPath substringFromIndex:c];
    EDAssert(![relPath isAbsolutePath]);
    return relPath;
}


- (void)putDirtySource:(id)source forFilePath:(NSString *)absPath {
    EDAssertMainThread();
    EDAssert(_dirtySet);
    [_dirtySet setObject:source forKey:absPath];
}


- (void)removeDirtySourceForFilePath:(NSString *)absPath {
    EDAssertMainThread();
    EDAssert(_dirtySet);
    [_dirtySet removeObjectForKey:absPath];
}


- (OKSource *)dirtySourceForFilePath:(NSString *)absPath {
    EDAssertMainThread();
    EDAssert(_dirtySet);
    OKSource *source = [_dirtySet objectForKey:absPath];
    return source;
}


- (BOOL)isFileDirtyAtPath:(NSString *)absPath {
    EDAssertMainThread();

    if ([absPath isEqualToString:EDProjectSettingsURL]) {
        return NO;
    }
    
    // Project Item (which shows the proj icon)
    if (![absPath isAbsolutePath] && ![absPath hasSupportedSchemePrefix]) {
        EDAssert([absPath isEqualToString:[[[[[self document] fileURL] relativePath] lastPathComponent] stringByDeletingPathExtension]]);
        return NO;
    }
    
    EDAssert([absPath isAbsolutePath] || [absPath hasSupportedSchemePrefix]);
    
    BOOL dirty = nil != [self dirtySourceForFilePath:absPath];
    return dirty;
}


- (EDTabModel *)lastModifiedTabModelForAbsolutePath:(NSString *)absPath {
    EDAssert([absPath length]);
    EDAssert([absPath isAbsolutePath]);
    
    NSString *relPath = [self relativeSourceFilePathForAbsoluteSourceFilePath:absPath];
    EDAssert([relPath length]);
    EDAssert(![relPath isAbsolutePath]);

    EDTabModel *result = nil;
    
    for (EDTabModel *tm in self.tabModels) {
        if ([tm.URLString isEqualToString:relPath]&& [tm isMoreRecentlyModifiedThan:result]) {
            result = tm;
        }
    }
    
    return result;
}


- (OKSource *)loadSourceForFileAtPath:(NSString *)absPath error:(NSError **)outErr {
    EDAssertMainThread();
    EDAssert([absPath length]);
    EDAssert([absPath isAbsolutePath]);
    
    OKSource *source = nil;
    NSString *srcDirPath = [self sourceDirPath];
    
    if ([absPath hasPrefix:srcDirPath]) {
        // first, look in dirtySet
        id obj = [self dirtySourceForFilePath:absPath];

        if ([obj isKindOfClass:[OKSource class]]) {
            source = obj;
            EDAssert([source isKindOfClass:[OKSource class]]);
            goto done;
        }
        
        // then look in tabs
        EDTabModel *tm = [self lastModifiedTabModelForAbsolutePath:absPath];
        if (tm) {
            OKViewController *okvc = tm.representedObject;
            NSString *text = [[okvc.sourceString copy] autorelease];
            NSStringEncoding enc = okvc.sourceStringEncoding;
            source = [OKSource sourceWithText:text encoding:enc];
            goto done;
        }
    }

    // then look on disk...
    EDAssert(outErr); // call should pass pointer
    EDAssert(!(*outErr)); // but it should be nil
    source = [self loadSourceFromDiskForFileAtPath:absPath error:outErr];
    //EDAssert(source);
    
done:
    return source;
}


- (OKSource *)loadSourceFromDiskForFileAtPath:(NSString *)absPath error:(NSError **)outErr {
    // This method is thread safe. Called from Main and NON-Main threads.
    
    OKSource *source = nil;
    
    NSData *data = [NSData dataWithContentsOfFile:absPath options:NSDataReadingMappedIfSafe error:outErr];
    if (!data) {
        if (outErr) {
            NSLog(@"Could not open script file `%@`", absPath);
            NSLog(@"%@", *outErr);
        }
        goto done;
    }
    
    // detect encoding
    NSStringEncoding enc = [[EDFileEncodingDetector instance] stringEncodingForData:data fromPath:absPath];
    if (0 == enc) {
        NSString *path = [absPath stringByAbbreviatingWithTildeInPath];
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"Could not detect text encoding for script file:\n\n «%@»", @""), path];
        NSLog(@"%@", reason);
        if (outErr) {
            id userInfo = @{NSLocalizedFailureReasonErrorKey: reason, NSLocalizedRecoverySuggestionErrorKey: path};
            *outErr = [NSError errorWithDomain:[[NSProcessInfo processInfo] processName] code:0 userInfo:userInfo];
        }
        //EDAssert(0);
        goto done;
    }
    
    // load string
    NSString *text = [[[NSString alloc] initWithData:data encoding:enc] autorelease];
    if (!text) {
        if (outErr) {
            NSLog(@"Could not open script file `%@`", absPath);
            NSLog(@"%@", *outErr);
        }
        goto done;
    }
    
    source = [OKSource sourceWithText:text encoding:enc];
    EDAssert(source);

done:
    return source;
}



- (void)storeInMemorySource:(OKSource *)source forFileAtPath:(NSString *)absPath {
    EDAssertMainThread();
    EDAssert(source);
    EDAssert([absPath length]);
    EDAssert([absPath isAbsolutePath]);
    
    // first in any existing tab
    EDTabModel *tm = [self lastModifiedTabModelForAbsolutePath:absPath];
    if (tm) {
        OKViewController *okvc = tm.representedObject;
        [okvc setSourceString:source.text encoding:source.encoding clearUndo:YES]; // clear undo???
        [self putDirtySource:@"" forFilePath:absPath];
    }
    
    // then, store in dirtySet
    else {
        [self putDirtySource:source forFilePath:absPath];
    }
}


- (void)saveTabModel:(EDTabModel *)tm {
    NSString *srcDirPath = [self sourceDirPath];

    NSString *absPath = [self absolutePathForTabModel:tm];
    EDAssert([absPath length]);
    
    // only save files in the source dir to be safe
    if ([absPath hasPrefix:srcDirPath]) {
        [self removeDirtySourceForFilePath:absPath];
        
        NSURL *fileURL = [NSURL fileURLWithPath:absPath];
        EDAssert(fileURL);
        OKViewController *okvc = tm.representedObject;
        
        NSString *source = [[okvc.sourceString copy] autorelease];
        EDAssert(source);
        NSStringEncoding enc = okvc.sourceStringEncoding;
        EDAssert(enc > 0);
        
        [source writeToURL:fileURL atomically:YES encoding:enc error:nil];
    }
}


- (void)saveFileAtPath:(NSString *)absPath {
    NSString *srcDirPath = [self sourceDirPath];
    
    EDAssert([absPath hasPrefix:srcDirPath]);
    
    // only save files in the source dir to be safe
    if ([absPath hasPrefix:srcDirPath]) {
        OKSource *source = [[[self dirtySourceForFilePath:absPath] retain] autorelease];

        EDAssert([source isKindOfClass:[OKSource class]]);
        EDAssert([source.text length]);
        
        NSURL *fileURL = [NSURL fileURLWithPath:absPath];
        EDAssert(fileURL);

        [self removeDirtySourceForFilePath:absPath];
        
        EDAssert(source);
        [source.text writeToURL:fileURL atomically:YES encoding:source.encoding error:nil];
    }
}


- (void)saveSelectedTabModel {
    EDAssert(self.tabModels);
    
    if ([self.tabModels count]) {
        [self.selectedSourceViewController.textView removeListWindow];
    }

    EDTabModel *tm = self.selectedEDTabModel;
    if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
        [self saveTabModel:tm];
        
        if (_filesystemViewController) {
            NSString *absPath = [self absolutePathForTabModel:tm];
            [_filesystemViewController reloadItemAtPath:absPath];
        }
    }
}


- (void)saveAllDirtyFiles {
    EDAssert(self.tabModels);
    
    if ([self.tabModels count]) {
        [self.selectedSourceViewController.textView removeListWindow];
    }
    
    for (EDTabModel *tm in self.tabModels) {
        if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
            [self saveTabModel:tm];
        }
    }
    
    EDAssert(_dirtySet);
    for (NSString *absPath in _dirtySet) {
        [self saveFileAtPath:absPath];
    }
    
    NSString *absPath = [self sourceDirPath];
    EDAssert(!MULTI_FILE_ENABLED || _filesystemViewController);
    [_filesystemViewController reloadItemAtPath:absPath];
}


#pragma mark -
#pragma mark Notifications

- (void)registerForNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(navigatorViewVisibleDidChange:) name:EDNavigatorViewVisibleDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(canvasViewVisibleDidChange:) name:EDCanvasViewVisibleDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(consoleViewVisibleDidChange:) name:EDConsoleViewVisibleDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(statusBarVisibleDidChange:) name:EDStatusBarVisibleDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(selectedThemeDidChange:) name:EDSelectedThemeDidChangeNotification object:nil];
    
    EDAssert([self document]);
    [nc addObserver:self selector:@selector(breakpointsDidChange:) name:EDBreakpointsDidChangeNotification object:[self document]];
}


- (void)navigatorViewVisibleDidChange:(NSNotification *)n {
    EDAssert(_outerUberView);
    [_outerUberView toggleLeftTopView:nil];
}


- (void)canvasViewVisibleDidChange:(NSNotification *)n {
    EDAssert(_outerUberView);
    [_outerUberView toggleRightTopView:nil];
}


- (void)consoleViewVisibleDidChange:(NSNotification *)n {
    EDAssert(_innerUberView);
    
    NSView *v = [_consoleViewController view];
    if ([v superview]) {
        [_innerUberView toggleBottomView:nil];
    } else {
        _innerUberView.bottomView = v;
        [_innerUberView openBottomView:nil];
    }
}


- (void)statusBarVisibleDidChange:(NSNotification *)n {
    EDAssert(_midContainerView);
    [_midContainerView setNeedsLayout];
}


- (void)webViewControllerTitleDidChange:(NSNotification *)n {
    [self.tabsListViewController updateAllTabModels];
    [self updateWindowTitle];
}


- (void)replViewControllerTitleDidChange:(NSNotification *)n {
    [self.tabsListViewController updateAllTabModels];
    [self updateWindowTitle];
}


- (void)textDidChange:(NSNotification *)n {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    EDAssertMainThread();
    EDAssert([n object] == self.selectedSourceViewController.textView);

    EDTabModel *tm = self.selectedEDTabModel;
    EDAssert(tm);
    
    NSString *absPath = [self absolutePathForTabModel:tm];
    EDAssert([absPath length]);

    [self putDirtySource:@"" forFilePath:absPath];

    // update last mod
    [tm modified];
    
    if (_filesystemViewController) {
        [_filesystemViewController reloadItemAtPath:absPath];
    }
    
    _findViewController.canReplace = NO;
}


- (void)selectedThemeDidChange:(NSNotification *)n {
    EDAssertMainThread();
    
    for (EDTabModel *tm in self.tabModels) {
        if ([tm.type isEqualToString:EDTabModelTypeSourceCodeFile]) {
            OKViewController *okvc = tm.representedObject;
            [self updateThemeInViewController:okvc];
        }
    }
}


#pragma mark -
#pragma mark Properties

- (NSString *)sourceDirPath {
    EDAssert([self document]);
    
    NSString *result = nil;
    
    NSURL *furl = [[self document] fileURL];
    if (furl) {
        result = [[furl relativePath] stringByAppendingPathComponent:SRC_DIR_NAME];
        EDAssert([result length]);
    }
    
    if (result && ![result hasSuffix:@"/"]) {
        result = [NSString stringWithFormat:@"%@/", result];
    }

    return result;
}


- (NSString *)mainSourceFilePath {
    NSString *srcDirPath = [self sourceDirPath];
    NSString *result = [[srcDirPath stringByAppendingPathComponent:MAIN_FILE_BASE] stringByAppendingPathExtension:MAIN_FILE_EXT];
    return result;
}


- (BOOL)isTypingInFindPanel {
    BOOL result = NO;
    TKTabModel *tm = self.selectedTabModel;
    if ([tm.type isEqualToString:EDTabModelTypeWebLocation]) {
        EDWebViewController *wvc = tm.representedObject;
        result = wvc.isTypingInFindPanel;
    }
    return result;
}


- (BOOL)multiFileEnabled {
    return MULTI_FILE_ENABLED;
}


- (EDHistory *)currentHistory {
    EDHistory *history = nil;

    EDTabModel *tm = self.selectedEDTabModel;
    if ([EDTabModelTypeSourceCodeFile isEqualToString:tm.type]) {
        history = tm.history;
    }
    
    return history;
}


- (EDTabModel *)selectedEDTabModel {
    return (EDTabModel *)[super selectedTabModel];
}

@end
