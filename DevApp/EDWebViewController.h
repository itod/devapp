//
//  EDWebViewController.h
//  Editor
//
//  Created by Todd Ditchendorf on 7/5/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewController.h>
#import <TDAppKit/TDComboField.h>
#import <WebKit/WebKit.h>

extern NSString *const EDWebViewControllerTitleDidChangeNotification;

@interface NSObject (EDNotifications)
- (void)webViewControllerTitleDidChange:(NSNotification *)n;
@end

@interface EDWebViewController : TDViewController <TDComboFieldDataSource, TDComboFieldDelegate, WebFrameLoadDelegate, WebPolicyDelegate, WebUIDelegate>

- (void)loadURLString:(NSString *)URLString;

- (IBAction)openLocation:(id)sender;
- (IBAction)goToLocation:(id)sender;

- (IBAction)performFindPanelAction:(id)sender;
- (IBAction)showFindPanel:(id)sender;
- (IBAction)hideFindPanel:(id)sender;
- (IBAction)find:(id)sender;
- (IBAction)useSelectionForFind:(id)sender;
- (IBAction)jumpToSelection:(id)sender;

@property (nonatomic, retain) IBOutlet WebView *webView;
@property (nonatomic, retain) IBOutlet TDComboField *locationTextField;
@property (nonatomic, retain) IBOutlet NSButton *reloadStopButton;
@property (nonatomic, retain) IBOutlet NSSearchField *findPanelSearchField;
@property (nonatomic, retain) NSString *initialURLString;
@property (nonatomic, retain) NSString *initialFindPanelTerm;
@property (nonatomic, retain) NSString *URLString;
@property (nonatomic, retain) NSImage *favicon;
@property (nonatomic, retain) NSString *statusText;
@property (nonatomic, assign) BOOL busy;

@property (nonatomic, copy) NSString *findPanelTerm;
@property (nonatomic, getter=isFindPanelVisible) BOOL findPanelVisible;
@property (nonatomic, getter=isTypingInFindPanel) BOOL typingInFindPanel;
@end
