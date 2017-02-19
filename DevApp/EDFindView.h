//
//  EDFindView.h
//  Editor
//
//  Created by Todd Ditchendorf on 9/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDAppKit.h>

@interface EDFindView : TDViewControllerView

@property (nonatomic, retain) IBOutlet NSComboBox *searchComboBox;
@property (nonatomic, retain) IBOutlet NSComboBox *replaceComboBox;

@property (nonatomic, retain) IBOutlet NSPopUpButton *scopePopUpButton;

@property (nonatomic, retain) IBOutlet NSScrollView *scrollView;

@property (nonatomic, retain) IBOutlet NSTextField *resultCountLabel;

@property (nonatomic, retain) IBOutlet NSProgressIndicator *busySpinner;
@property (nonatomic, retain) IBOutlet NSButton *searchButton;
@property (nonatomic, retain) IBOutlet NSButton *replaceButton;

- (CGRect)searchComboBoxRectForBounds:(CGRect)bounds;
- (CGRect)replaceComboBoxRectForBounds:(CGRect)bounds;
- (CGRect)scrollViewRectForBounds:(CGRect)bounds;

//- (CGRect)searchButtonRectForBounds:(CGRect)bounds;
//- (CGRect)replaceButtonRectForBounds:(CGRect)bounds;
@end
