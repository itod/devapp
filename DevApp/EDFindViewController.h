//
//  EDFindViewController.h
//  Editor
//
//  Created by Todd Ditchendorf on 9/9/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewController.h>
#import "EDFindOutlineView.h"

@class EDFindViewController;
@class EDFileLocation;

@class OKSource;

@protocol EDFindViewControllerDelegate <NSObject>
- (NSString *)searchDirPathForFindViewController:(EDFindViewController *)fvc;
- (NSString *)searchFilePathForFindViewController:(EDFindViewController *)fvc;

- (void)findViewControllerWillSearch:(EDFindViewController *)fvc;
- (void)findViewControllerDidSearch:(EDFindViewController *)fvc;

- (void)findViewController:(EDFindViewController *)fvc willStartReplacingInFiles:(NSArray *)filePaths;
- (void)findViewController:(EDFindViewController *)fvc didFinishReplacingInFiles:(NSArray *)filePaths;

- (OKSource *)findViewController:(EDFindViewController *)fvc sourceForFileAtPath:(NSString *)filePath error:(NSError **)outErr;
- (void)findViewController:(EDFindViewController *)fvc didUpdateSource:(OKSource *)source forFileAtPath:(NSString *)filePath;

- (void)findViewController:(EDFindViewController *)fvc didActivateFileLocation:(EDFileLocation *)fileLoc;
- (void)findViewControllerDidDismiss:(EDFindViewController *)fvc;
@end

@interface EDFindViewController : TDViewController <NSOutlineViewDataSource, EDFindOutlineViewDelegate, NSComboBoxDataSource, NSTextDelegate>

- (IBAction)search:(id)sender;
- (IBAction)replace:(id)sender;

- (IBAction)prev:(id)sender;
- (IBAction)next:(id)sender;

- (void)selectResultFileLocation:(EDFileLocation *)fileLoc;

@property (nonatomic, assign) id <EDFindViewControllerDelegate>delegate;

@property (nonatomic, retain) IBOutlet NSButton *closeButton;

@property (nonatomic, retain) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, retain) IBOutlet NSComboBox *searchComboBox;
@property (nonatomic, retain) IBOutlet NSComboBox *replaceComboBox;

@property (nonatomic, retain) IBOutlet NSTextField *resultCountLabel;

@property (nonatomic, retain) NSMutableDictionary *searchResults;
@property (nonatomic, retain) NSMutableArray *searchResultFilenames;

@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, copy) NSString *replaceText;

@property (nonatomic, retain) NSMutableArray *searchTextHistory;
@property (nonatomic, retain) NSMutableArray *replaceTextHistory;

@property (nonatomic, assign) BOOL searchEntireProject;
@property (nonatomic, assign) BOOL busy;
@property (nonatomic, assign) BOOL emptyResultSet;
@property (nonatomic, assign) BOOL canReplace;
@end
