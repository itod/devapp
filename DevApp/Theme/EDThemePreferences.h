//
//  EDThemePreferences.h
//  Editor
//
//  Created by Todd Ditchendorf on 11/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDPreferenceViewController.h"

@class EDTheme;
@class EDThemeRulesTableView;
@class EDColorPickerButtonCell;

@interface EDThemePreferences : TDPreferenceViewController <NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>
// <NSMenuDelegate, NSComboBoxDataSource>

- (IBAction)selectFont:(id)sender;

//@property (nonatomic, retain) IBOutlet NSTextField *selectedFontLabel;
@property (nonatomic, retain) IBOutlet NSTextField *selectedFontTextField;

@property (nonatomic, retain) IBOutlet NSTableView *themeNamesTableView;
@property (nonatomic, retain) IBOutlet EDThemeRulesTableView *themeRulesTableView;

@property (nonatomic, retain) IBOutlet EDColorPickerButtonCell *selectionColorCell;
@property (nonatomic, retain) IBOutlet EDColorPickerButtonCell *caretColorCell;

@property (nonatomic, retain) NSArray *ruleKeyOrder;
@property (nonatomic, retain) NSDictionary *ruleDisplayNameTab;

@property (nonatomic, retain) NSFont *selectedFont;
@property (nonatomic, retain) NSFont *selectedDisplayFont;
@end
