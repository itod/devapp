//
//  EDWebViewController.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/5/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDWebViewController.h"
#import "EDWebContainerView.h"
#import "EDFaviconController.h"
#import "EDRecentURLController.h"
#import "EDUtils.h"
#import "NSString+EDAdditions.h"
#import "WebViewPrivate.h"
#import <WebKit/WebKit.h>
#import <TDAppKit/TDViewControllerView.h>
#import <TDAppKit/DOMNode+TDAdditions.h>
#import <TDAppKit/TDComboField.h>
#import <TDAppKit/TDUtils.h>

NSString *const EDWebViewControllerTitleDidChangeNotification = @"EDWebViewControllerTitleDidChangeNotification";

@interface EDWebViewController ()

@end

@implementation EDWebViewController {
    BOOL _didReceiveTitle;
    BOOL _typingInFindPanel;
    BOOL _displayingMatchingRecentURLs;
    BOOL _locationJustSent;
}

- (id)init {
    self = [self initWithNibName:@"EDWebViewController" bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    EDAssert([name length]);
    
    self = [super initWithNibName:name bundle:b];
    if (self) {
        self.favicon = [self defaultFavicon];
    }
    
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    EDAssert(_webView);
    [self stopObservingWebView];
    
    [_webView setFrameLoadDelegate:nil];
    [_webView setPolicyDelegate:nil];
    [_webView setUIDelegate:nil];
    
    self.webView = nil;
    self.locationTextField = nil;
    self.reloadStopButton = nil;
    self.findPanelSearchField = nil;
    self.initialURLString = nil;
    self.initialFindPanelTerm = nil;
    self.URLString = nil;
    self.favicon = nil;
    self.statusText = nil;
    self.findPanelTerm = nil;
    [super dealloc];
}


- (void)viewDidLoad {
    EDAssert([self view]);
    EDAssert(_webView);
    EDAssert([_webView frameLoadDelegate] == self);
    EDAssert([_webView policyDelegate] == self);
    EDAssert([_webView UIDelegate] == self);
    
    TDColorView *v = (TDColorView *)[self view];
    EDAssert([v isKindOfClass:[TDColorView class]]);
    v.color = [NSColor windowBackgroundColor];
    
    EDAssert(_locationTextField);
    _locationTextField.dataSource = self;
    
    [self setUpWebView];
    [self registerForNotifications];
    
    if (_initialURLString) {
        [self loadURLString:_initialURLString];
        self.initialURLString = nil;
    }
}


- (void)setUpWebView {
    [_webView setHostWindow:[[self view] window]];
    [_webView setShouldCloseWithWindow:YES];
    [_webView setMaintainsBackForwardList:YES];
    [_webView setDrawsBackground:YES];
    
    WebPreferences *prefs = [WebPreferences standardPreferences];
    [prefs setUsesPageCache:NO];
    [prefs setCacheModel:WebCacheModelDocumentBrowser];
    [prefs setJavaEnabled:NO];
    [prefs setPlugInsEnabled:NO];
    [prefs setTabsToLinks:YES];
    
    [_webView setPreferences:prefs];
    
    [self startObservingWebView];
}


- (void)registerForNotifications {
    EDAssert(_locationTextField);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(controlTextDidChange:)
               name:NSControlTextDidChangeNotification
             object:_locationTextField];
    
    [nc addObserver:self
           selector:@selector(controlTextDidBeginEditing:)
               name:NSControlTextDidBeginEditingNotification
             object:_locationTextField];
}


#pragma mark -
#pragma mark Public

- (void)loadURLString:(NSString *)URLString {
    EDAssertMainThread();
    EDAssert(_webView);
    
    self.title = NSLocalizedString(@"Loading…", @"");

    NSURL *url = [NSURL URLWithString:URLString];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [[_webView mainFrame] loadRequest:req];
}


#pragma mark -
#pragma mark Actions

- (IBAction)openLocation:(id)sender {
    EDAssertMainThread();
    EDAssert(_locationTextField);
    [[[self view] window] makeFirstResponder:_locationTextField];
}


- (IBAction)goToLocation:(id)sender {
    EDAssertMainThread();
    EDAssert(_locationTextField);
    if (![_URLString length]) {
        NSBeep();
        return;
    }

    self.URLString = [_URLString stringByEnsuringURLSchemePrefix];
    self.URLString = [_URLString stringByEnsuringTLDSuffix];
    
    if (_URLString) {
        [self loadURLString:_URLString];
    } else {
        NSBeep();
    }
}


- (IBAction)performFindPanelAction:(id)sender {
    EDAssertMainThread();

    if (![self isFindPanelVisible]) {
        [self showFindPanel:sender];
    }
    
    NSInteger action = [sender tag];
    switch (action) {
        case NSFindPanelActionShowFindPanel:
            [[[self view] window] makeFirstResponder:_findPanelSearchField];
            break;
        case NSFindPanelActionNext:
        case NSFindPanelActionPrevious:
            [self find:sender];
            break;
        case NSFindPanelActionSetFindString:
            [self useSelectionForFind:sender];
            break;
        default:
            break;
    }
}


- (IBAction)showFindPanel:(id)sender {
    EDAssertMainThread();
    EDAssert(_findPanelSearchField);
    
    if (![self isFindPanelVisible]) {
        [_findPanelSearchField setStringValue:@""];
        [self toggleFindPanel];
    }
    
    [[[self view] window] makeFirstResponder:_findPanelSearchField];
}


- (IBAction)hideFindPanel:(id)sender {
    if (self.isFindPanelVisible) {
        [self toggleFindPanel];
    }
    
    self.typingInFindPanel = NO;

    [[[self view] window] makeFirstResponder:_webView];
}


- (IBAction)find:(id)sender {
    EDAssertMainThread();
    EDAssert(_webView);
    
    if ([_webView canMarkAllTextMatches]) {
        [_webView unmarkAllTextMatches];
        [_webView markAllMatchesForText:_findPanelTerm caseSensitive:NO highlight:YES limit:0];
    }
    BOOL forward = !sender || (NSFindPanelActionNext == [sender tag]);
    BOOL found = [_webView searchFor:_findPanelTerm direction:forward caseSensitive:NO wrap:YES];
    
    if (!found && [_findPanelTerm length]) {
        NSBeep();
    }
}


- (IBAction)useSelectionForFind:(id)sender {
    self.findPanelTerm = [[_webView selectedDOMRange] toString];
    [self find:sender];
}


- (IBAction)jumpToSelection:(id)sender {
    DOMElement *el = (DOMElement *)[[_webView selectedDOMRange] commonAncestorContainer];
    [el scrollIntoView:YES];
}


- (void)toggleFindPanel {
    _findPanelVisible = !_findPanelVisible;
    [_webView unmarkAllTextMatches];
    
    EDWebContainerView *wcv = (EDWebContainerView *)[self view];
    wcv.findPanelVisible = _findPanelVisible;
    [wcv setNeedsLayout];
}


#pragma mark -
#pragma mark WebUIDelegate

- (void)webView:(WebView *)sender setStatusText:(NSString *)text {
    self.statusText = text;
}


- (NSString *)webViewStatusText:(WebView *)sender {
    return self.statusText;
}


- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)info modifierFlags:(NSUInteger)flags {
    NSURL *URL = [info valueForKey:WebElementLinkURLKey];
    
    if (URL) {
        WebFrame *sourceFrame = [info valueForKey:WebElementFrameKey];
        WebFrame *targetFrame = [info valueForKey:WebElementLinkTargetFrameKey];
        DOMNode  *targetNode  = [info valueForKey:WebElementDOMNodeKey];
        DOMElement *anchorEl  = [targetNode firstAncestorOrSelfByTagName:@"a"];
        NSString *targetStr   = [anchorEl getAttribute:@"target"];
        NSString *format = nil;
        
        if (sourceFrame != targetFrame) {
            if ([targetStr length] && ([targetStr isEqualToString:@"_new"] || [targetStr isEqualToString:@"_blank"])) {
                format = NSLocalizedString(@"Open “%@” in a new tab", @"");
            } else {
                format = NSLocalizedString(@"Open “%@” in a new tab", @"");
            }
        } else if ([[URL scheme] hasPrefix:@"javascript"]) {
            format = NSLocalizedString(@"Run script “%@”", @"");
        } else {
            format = NSLocalizedString(@"Go to “%@”", @"");
        }
        
        self.statusText = [NSString stringWithFormat:format, [URL absoluteString]];
    } else {
        self.statusText = @"";
    }
}


#pragma mark -
#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame != [sender mainFrame]) return;
    
    // hide find panel
    //[self hideFindPanel:self];

    self.URLString = [[[[frame provisionalDataSource] request] URL] absoluteString];
    self.title = NSLocalizedString(@"Loading…", @"");
    self.busy = YES;
}


- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame != [sender mainFrame]) return;
    
    if (![_initialURLString length]) {
        NSString *s = [[[[frame provisionalDataSource] request] URL] absoluteString];
        self.initialURLString = s;
    }
}


- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    if (frame != [sender mainFrame]) return;

    self.busy = NO;
    self.initialFindPanelTerm = nil;
}


- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame {
    if (frame != [sender mainFrame]) return;

    self.favicon = [self defaultFavicon];
    
    _didReceiveTitle = NO;
    self.URLString = [sender mainFrameURL];
    
    [self addRecentURL:_URLString];
    [self addRecentURL:_initialURLString]; // if they are the same, this will not be added

    self.initialURLString = nil;
}


- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
    if (frame != [sender mainFrame]) return;

    _didReceiveTitle = YES;
    self.title = title;
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (frame != [sender mainFrame]) return;
    
    if (!_didReceiveTitle) {
        self.title = _URLString;
    }

    self.busy = NO;
    
    if (_initialFindPanelTerm) {
        self.findPanelTerm = _initialFindPanelTerm;
        self.initialFindPanelTerm = nil;

        [self showFindPanel:nil];
        [_findPanelSearchField setStringValue:_findPanelTerm];
        [self find:nil];
    }
}


- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    if (frame != [sender mainFrame]) return;

    self.title = NSLocalizedString(@"Load Failed", @"");
    self.busy = NO;
    self.initialFindPanelTerm = nil;
}


- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
    if (frame != [sender mainFrame]) return;
    
    self.favicon = image;
}


#pragma mark -
#pragma mark NSControl Text

- (void)controlTextDidBeginEditing:(NSNotification *)n {
    NSControl *control = [n object];
    
    if (control == _locationTextField) {
        // TODO ? use binding instead?
        //[_locationTextField showDefaultIcon];
    } else if (control == _findPanelSearchField) {
        _typingInFindPanel = YES;
    }
}


- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    if (control == _locationTextField) {
        [[EDRecentURLController instance] resetMatchingRecentURLs];
        _displayingMatchingRecentURLs = YES;
        return YES;
    } else {
        return YES;
    }
}


- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    if (control == _locationTextField) {
        //[_locationTextField hidePopUp];
        _displayingMatchingRecentURLs = NO;
        return YES;
    } else if (control == _findPanelSearchField) {
        return [self _findPanelSearchField:control textShouldEndEditing:fieldEditor];
    } else {
        return YES;
    }
}


- (BOOL)_findPanelSearchField:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    return YES;
}


// necessary to handle cmd-Return in search field
- (BOOL)control:(NSControl *)control textView:(NSTextView *)tv doCommandBySelector:(SEL)sel {
    if (control == _locationTextField && @selector(insertNewline:) == sel) {
        _locationJustSent = YES;
    } else if (control == _findPanelSearchField && @selector(cancelOperation:) == sel) {
        TDPerformOnMainThreadAfterDelay(0.0, ^{
            [self hideFindPanel:nil];
        });
    }
    
    return NO;
}


- (void)controlTextDidChange:(NSNotification *)n {
    NSControl *control = [n object];
    
    if (control == _findPanelSearchField) {
        DOMRange *r = [_webView selectedDOMRange];
        [r collapse:YES];
        [_webView setSelectedDOMRange:r affinity:NSSelectionAffinityUpstream];
        [self find:_findPanelSearchField];
    } else if (control == _locationTextField) {
        [[EDRecentURLController instance] resetMatchingRecentURLs];
        
        NSUInteger i = 0;
        for (NSString *URLString in [self recentURLs]) {
            URLString = [URLString stringByTrimmingURLSchemePrefix];
            if ([URLString hasPrefix:[_locationTextField stringValue]]) {
                [self addMatchingRecentURL:URLString];
                if (i++ > 20) { // TODO
                    break;
                }
            }
        }
    }
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    NSControl *control = [n object];
    
    if (control == _findPanelSearchField) {
        _typingInFindPanel = NO;
    } else if (control == _locationTextField) {
        if (_locationJustSent) {
            _locationJustSent = NO;
        } else {
            NSString *str = _URLString;
            [_locationTextField setStringValue:str ? str : @""];
        }
    }
}


#pragma mark -
#pragma mark NSComboBoxDataSource

- (void)comboFieldDidEscape:(TDComboField *)cf {
    EDAssert(cf == _locationTextField);

    NSString *str = _webView.mainFrameURL;
    if ([str length]) {
        self.URLString = str;
    }
    [[[self view] window] makeFirstResponder:_webView];
}


- (void)comboFieldWillDismissPopUp:(TDComboField *)cf {
    EDAssert(cf == _locationTextField);
//        NSInteger i = [_locationTextField indexOfSelectedItem];
//        NSInteger c = [_locationTextField numberOfItems];
//        // last item (clear url menu) was clicked. clear recentURLs
//        if (c && i == c - 1) {
//            if (![[NSApp currentEvent] isEscKeyPressed]) {
//                NSString *s = [_locationTextField stringValue];
//                [_locationTextField deselectItemAtIndex:i];
//
//                [[EDRecentURLController instance] resetRecentURLs];
//                [[EDRecentURLController instance] resetMatchingRecentURLs];
//
//                [_locationTextField reloadData];
//                [_locationTextField setStringValue:s];
//            }
//        }
}


- (id)comboField:(TDComboField *)cf objectAtIndex:(NSUInteger)i {
    EDAssert(cf == _locationTextField);
    NSArray *URLs = _displayingMatchingRecentURLs ? [self matchingRecentURLs] : [self recentURLs];
    
    NSInteger c = [URLs count];
//        if (c && i == c) {
//            NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
//            return [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Clear Recent URL Menu", @"") attributes:attrs] autorelease];
//        } else {
    if (i < c) {
        return [URLs objectAtIndex:i];
    } else {
        return nil;
    }
//        }
}


- (NSUInteger)numberOfItemsInComboField:(TDComboField *)cf {
    EDAssert(cf == _locationTextField);

    NSArray *URLs = _displayingMatchingRecentURLs ? [self matchingRecentURLs] : [self recentURLs];
    NSInteger c = [URLs count];
    return c; // + 1;
}


- (NSUInteger)comboField:(TDComboField *)cf indexOfItemWithStringValue:(NSString *)s {
    EDAssert(cf == _locationTextField);

    if (_displayingMatchingRecentURLs) {
        return [[self matchingRecentURLs] indexOfObject:s];
    }
    return [[self recentURLs] indexOfObject:s];
}


- (NSString *)comboField:(TDComboField *)cf completedString:(NSString *)uncompletedString {
    EDAssert(cf == _locationTextField);

    if ([[[self view] window] isKeyWindow]) {
        if ([[self matchingRecentURLs] count]) {
            //[[locationComboField cell] scrollItemAtIndexToVisible:0];
            //[locationComboField showPopUpWithItemCount:[[self matchingRecentURLs] count]];
            return [[self matchingRecentURLs] objectAtIndex:0];
        }
        return nil;
    } else {
        return nil;
    }
}


#pragma mark -
#pragma mark HMImageComboBoxDelegate

- (BOOL)comboField:(TDComboField *)cf writeDataToPasteboard:(NSPasteboard *)pboard {
    EDAssert(cf == _locationTextField);

    NSString *title = [_webView mainFrameTitle];
    if (![title length]) {
        title = [_URLString stringByTrimmingURLSchemePrefix];
    }
    
    EDWriteAllToPasteboard(_URLString, title, pboard);
    
    return YES;
}


#pragma mark -
#pragma mark WebProgressNotification

- (void)tabControllerProgressDidStart:(NSNotification *)n {
    [self clearProgress];
}


- (void)tabControllerProgressDidChange:(NSNotification *)n {
    WebView *wv = [n object];
    if (wv == _webView) {
        [self displayEstimatedProgress];
    }
}


- (void)tabControllerProgressDidFinish:(NSNotification *)n {
    WebView *wv = [n object];
    if (wv == _webView) {
        [self clearProgressInFuture];
    }
}


- (void)startObservingWebView {
    EDAssert(_webView);
    EDAssert(_locationTextField);

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(tabControllerProgressDidStart:) name:WebViewProgressStartedNotification object:_webView];
    [nc addObserver:self selector:@selector(tabControllerProgressDidChange:) name:WebViewProgressEstimateChangedNotification object:_webView];
    [nc addObserver:self selector:@selector(tabControllerProgressDidFinish:) name:WebViewProgressFinishedNotification object:_webView];

//    // bind title
//    [[self window] bind:@"title" toObject:tc withKeyPath:@"title" options:nil];
    
    // bind icon
    [_locationTextField bind:@"image" toObject:self withKeyPath:@"favicon" options:nil];
}


- (void)stopObservingWebView {
    EDAssert(_webView);
    EDAssert(_locationTextField);

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:WebViewProgressStartedNotification object:_webView];
    [nc removeObserver:self name:WebViewProgressEstimateChangedNotification object:_webView];
    [nc removeObserver:self name:WebViewProgressFinishedNotification object:_webView];
    
//    // unbind title
//    [[self window] unbind:@"title"];
    
    // unbind icon
    [_locationTextField unbind:@"image"];
}


- (void)displayEstimatedProgress {
    EDAssert(_webView);
    EDAssert(_locationTextField);
    CGFloat progress = [_webView estimatedProgress];
    _locationTextField.progress = progress;
}


- (void)clearProgressInFuture {
    [self performSelector:@selector(clearProgress) withObject:nil afterDelay:.2];
}


- (void)clearProgress {
    EDAssert(_locationTextField);
    _locationTextField.progress = 0;
}


#pragma mark -
#pragma mark Properties

- (void)setBusy:(BOOL)busy {
    if (busy != _busy) {
        [self willChangeValueForKey:@"busy"];
        
        _busy = busy;
        
        EDAssert(_reloadStopButton);
        
        NSString *imgName = nil;
        BOOL enabled = NO;
        SEL action = nil;

        if (_busy) {
            imgName = NSImageNameStopProgressTemplate;
            enabled = YES;
            action = @selector(stopLoading:);
        } else {
            imgName = NSImageNameRefreshTemplate;
            BOOL canReload = [_webView canGoBack] || [_URLString length];
            enabled = canReload;
            action = @selector(reload:);
        }

        [_reloadStopButton setImage:[NSImage imageNamed:imgName]];
        [_reloadStopButton setAction:action];
        [_reloadStopButton setEnabled:enabled];
        
        [self didChangeValueForKey:@"busy"];
    }
}


- (void)setTitle:(NSString *)title {
    EDAssertMainThread();
    [super setTitle:title];

    TDPerformOnMainThreadAfterDelay(0.0, ^{
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:EDWebViewControllerTitleDidChangeNotification object:self];
    });
}


- (NSImage *)defaultFavicon {
    return [[EDFaviconController instance] defaultFavicon];
}


- (NSArray *)recentURLs {
    return [[EDRecentURLController instance] recentURLs];
}


- (NSArray *)matchingRecentURLs {
    return [[EDRecentURLController instance] matchingRecentURLs];
}


- (void)addRecentURL:(NSString *)s {
    [[EDRecentURLController instance] addRecentURL:s];
}


- (void)addMatchingRecentURL:(NSString *)s {
    [[EDRecentURLController instance] addMatchingRecentURL:s];
}

@end
