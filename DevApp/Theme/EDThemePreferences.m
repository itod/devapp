
//  EDThemePreferences.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDThemePreferences.h"
#import "EDThemeManager.h"
#import "EDFontPickerTextField.h"
#import "EDTheme.h"
#import "EDThemeRulesTableView.h"
#import "EDThemeRulesNameTableCell.h"
#import "EDColorPickerButtonCell.h"
#import <TDAppKit/TDViewController.h>
#import <TDAppKit/TDUtils.h>
#import <OkudaKit/OKViewController.h>
#import <OkudaKit/OKUtils.h>

#define FONT_TEXT_FIED_FONT_SIZE 11.0
#define RULE_TABLE_FONT_SIZE 12.0

@interface EDThemePreferences ()
@end

@implementation EDThemePreferences {
    BOOL _hasLoaded;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _selectedFontTextField.delegate = nil;
    self.selectedFontTextField = nil;
    
    self.themeNamesTableView = nil;
    self.themeRulesTableView = nil;
    self.selectionColorCell = nil;
    self.caretColorCell = nil;
    self.ruleKeyOrder = nil;
    self.ruleDisplayNameTab = nil;
    self.selectedFont = nil;
    self.selectedDisplayFont = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSWindowController

- (void)awakeFromNib {
    EDAssert(_themeNamesTableView);
    EDAssert(_themeRulesTableView);
    EDAssert(_selectedFontTextField);
    EDAssert(_selectedFontTextField.delegate = self);
    EDAssert(_selectionColorCell);
    EDAssert(_caretColorCell);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(selectedThemeDidChange:) name:EDSelectedThemeDidChangeNotification object:nil];

    self.ruleDisplayNameTab = @{
                                @".default": @"Default",
                                @"identifier": @"Identifier",

                                @"braces": @"Braces",
                                @"dot": @"Dot",
                                @"separators": @"Separators",
                                @"operators": @"Operators",
                                
                                @"constant": @"Constant",
                                @"number": @"Number",
                                
                                @"className": @"Class Name",
                                @"functionName": @"Function Name",

                                @"keyword": @"Keyword",

                                @"classKeyword": @"class Keyword",
                                @"functionKeyword": @"def Keyword",

                                @"string": @"String",

                                @"comment": @"Comment",
                                
                                @"builtin": @"Builtin",

                                @"inheritedClass": @"Inherited Class",
                                @"functionParam": @"Function Parameter",

                                @"languageVariable": @"Language Variable",
                                @"languageFunction": @"Language Function",

//                                @"pdbPrompt": @"PDB Prompt",
//                                @"pdbError": @"PDB Error",
                                };
    
    self.ruleKeyOrder = @[
                          @".default",
                          @"identifier",
                          
                          @"braces",
                          @"dot",
                          @"separators",
                          @"operators",
                          
                          @"constant",
                          @"number",
                          
                          @"className",
                          @"functionName",
                          
                          @"keyword",
                          
                          @"classKeyword",
                          @"functionKeyword",
                          
                          @"string",
                          
                          @"comment",
                          
                          @"builtin",
                          
                          @"inheritedClass",
                          @"functionParam",
                          
                          @"languageVariable",
                          @"languageFunction",
//                         @"pdbPrompt",
//                         @"pdbError",
                         ];

    [_themeNamesTableView reloadData];
    
    NSString *selThemeName = [[[EDThemeManager instance] selectedTheme] name];
    EDTheme *theme = [[EDThemeManager instance] themeNamed:selThemeName];
    NSUInteger selIdx = [[[EDThemeManager instance] orderedThemes] indexOfObject:theme];

    _hasLoaded = YES;
    [_themeNamesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selIdx] byExtendingSelection:NO];
    [self changeThemeNameSelectionToRow:selIdx]; // jiggle the handle
    
    [self updateFontInSelectedFontTextField];
    [self updateFontInThemeRulesTableView];
}


#pragma mark -
#pragma mark Actions

- (IBAction)selectFont:(id)sender {
    NSFontPanel *panel = [NSFontPanel sharedFontPanel];
    [panel setPanelFont:self.selectedFont isMultiple:NO];
    
    [panel makeKeyAndOrderFront:nil];
}


#pragma mark -
#pragma mark Notifications

- (void)selectedThemeDidChange:(NSNotification *)n {
    self.selectedFont = nil;
    self.selectedDisplayFont = nil;
    
    IDEAssert(_selectedFontTextField);
    [_selectedFontTextField setFont:self.selectedDisplayFont];
    
    [self updateFontInSelectedFontTextField];
    [self updateFontInThemeRulesTableView];
}


#pragma mark -
#pragma mark Private

- (void)changeThemeNameSelectionToRow:(NSUInteger)row {
    EDAssertMainThread();
    
    EDTheme *theme = [[[EDThemeManager instance] orderedThemes] objectAtIndex:row];
    EDAssert([theme isKindOfClass:[EDTheme class]]);
    
    [[EDUserDefaults instance] setSelectedThemeName:theme.name];
    [[EDThemeManager instance] setSelectedTheme:theme];
    
    NSDictionary *defaultAttrs = theme.attributes[@".default"];
    NSDictionary *selAttrs = theme.attributes[@".selection"];
    
    NSColor *bgColor = defaultAttrs[NSBackgroundColorAttributeName];
    EDAssert(bgColor);
    
    EDAssert(_themeRulesTableView);
    [_themeRulesTableView setGridColor:OKOppositeColor(bgColor)];
    [_themeRulesTableView setBackgroundColor:bgColor];
    
    [_themeRulesTableView reloadData];
    [_themeNamesTableView setNeedsDisplay:YES];
    
    EDAssert(_selectionColorCell);
    [_selectionColorCell setFillColor:selAttrs[NSBackgroundColorAttributeName]];
    [_caretColorCell setFillColor:selAttrs[NSForegroundColorAttributeName]];

    [[_selectionColorCell controlView] setNeedsDisplay:YES];
    [[_caretColorCell controlView] setNeedsDisplay:YES];

    // notify
    [self postSelectedThemeDidChangeNotification];
}


- (void)postSelectedThemeDidChangeNotification {
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:EDSelectedThemeDidChangeNotification object:nil];
    });
}


- (void)updateFontInSelectedFontTextField {
    EDAssertMainThread();
    EDAssert(_selectedFontTextField);
    
    [_selectedFontTextField setFont:self.selectedDisplayFont];
    [_selectedFontTextField setStringValue:[NSString stringWithFormat:@"%@, %g", [[EDUserDefaults instance] selectedFontFamily], [[EDUserDefaults instance] selectedFontSize]]];
}


- (void)updateFontInThemeRulesTableView {
    EDAssertMainThread();
    EDAssert(_themeRulesTableView);
    [_themeRulesTableView reloadData];
}


- (NSFont *)selectedFont {
    if (!_selectedFont) {
        // font family
        NSString *fontFamily = [[EDUserDefaults instance] selectedFontFamily];
        
//        NSRange r = [fontFamily rangeOfString:@"-"];
//        if (r.length) fontFamily = [fontFamily substringToIndex:r.location];
//        
        // font size
        CGFloat fontSize = [[EDUserDefaults instance] selectedFontSize];
        
        // desc attrs
        id descAttrs = [NSMutableDictionary dictionaryWithObject:fontFamily forKey:NSFontFamilyAttribute];
        
        // desc
        NSFontDescriptor *desc = [[[NSFontDescriptor alloc] initWithFontAttributes:descAttrs] autorelease];
        
        // font
        NSFont *font = [NSFont fontWithDescriptor:desc size:fontSize];
        if (!font) {
            font = [NSFont fontWithName:fontFamily size:fontSize];
        }
        
        self.selectedFont = font;
    }
    return _selectedFont;
}


- (NSFont *)selectedDisplayFont {
    if (!_selectedDisplayFont) {
        CGFloat fontSize = FONT_TEXT_FIED_FONT_SIZE;
        NSFontDescriptor *desc = [self.selectedFont fontDescriptor];
        EDAssert(desc);
        self.selectedDisplayFont = [NSFont fontWithDescriptor:desc size:fontSize];
    }
    return _selectedDisplayFont;
}


#pragma mark -
#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv {
    if (tv == _themeNamesTableView) {
        return [self numberOfRowsInThemeNamesTableView:tv];
    } else {
        return [self numberOfRowsInThemeRulesTableView:tv];
    }
}


- (NSInteger)numberOfRowsInThemeNamesTableView:(NSTableView *)tv {
    NSUInteger c = [[[EDThemeManager instance] orderedThemes] count];
    return c;
}


- (NSInteger)numberOfRowsInThemeRulesTableView:(NSTableView *)tv {
    NSUInteger c = 0;
    if ([[EDThemeManager instance] selectedTheme]) {
        c = [_ruleDisplayNameTab count];
    }
    return c;
}


- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)row {
    if (tv == _themeNamesTableView) {
        return [self themeNamesTableView:tv objectValueForTableColumn:col row:row];
    } else {
        return [self themeRulesTableView:tv objectValueForTableColumn:col row:row];
    }
}


- (id)themeNamesTableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)row {
    EDAssert([[[EDThemeManager instance] orderedThemes] count] > row);
    
    EDTheme *theme = [[[EDThemeManager instance] orderedThemes] objectAtIndex:row];
    EDAssert([theme isKindOfClass:[EDTheme class]]);
    
    return theme.name;
}


- (id)themeRulesTableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)row {
    EDTheme *selTheme = [[EDThemeManager instance] selectedTheme];
    EDAssert(selTheme);
    
    EDAssert(row < [_ruleKeyOrder count]);
    NSString *ruleKey = _ruleKeyOrder[row];
    
    NSDictionary *attrs = selTheme.attributes[ruleKey];
    EDAssert([attrs count]);
    
    NSString *colId = [col identifier];
    EDAssert([colId length]);
    
    BOOL isBold = [attrs[OKBold] boolValue]; //[self selectedFontHasTraits:kCTFontBoldTrait];
    BOOL isItalic = [attrs[OKItalic] boolValue]; //self selectedFontHasTraits:kCTFontItalicTrait];
    //BOOL isUnderline = [attrs[OKUnderline] boolValue]; //self selectedFontHasTraits:kCTFontItalicTrait];

    id result = nil;
    if ([colId isEqualToString:@"name"]) {
        NSString *ruleDisplayName = _ruleDisplayNameTab[ruleKey];
        EDAssert([ruleDisplayName length]);
        
        // font family
        NSString *fontFamily = [[EDUserDefaults instance] selectedFontFamily];
        
//        NSRange r = [fontFamily rangeOfString:@"-"];
//        if (r.length) fontFamily = [fontFamily substringToIndex:r.location];
//        
        // font size
        CGFloat fontSize = RULE_TABLE_FONT_SIZE;

        // font face
        NSMutableString *fontFace = [NSMutableString string];
        if (isBold) [fontFace appendFormat:@"bold%@", isItalic ? @" " : @""];
        if (isItalic) [fontFace appendString:@"italic"];

        // desc attrs
        id descAttrs = [NSMutableDictionary dictionaryWithObject:fontFamily forKey:NSFontFamilyAttribute];
        if ([fontFace length]) {
            [descAttrs setObject:fontFace forKey:NSFontFaceAttribute];
        }
        
        // desc
        NSFontDescriptor *desc = [[[NSFontDescriptor alloc] initWithFontAttributes:descAttrs] autorelease];
        
        // font
        NSFont *font = [NSFont fontWithDescriptor:desc size:fontSize];
        if (!font) {
            font = [NSFont fontWithName:fontFamily size:fontSize];
        }

        // insert font into attrs
        EDAssert(font);
        EDAssert(attrs);
        id mattrs = [[attrs mutableCopy] autorelease];
        [mattrs removeObjectForKey:NSBackgroundColorAttributeName];
        mattrs[NSFontAttributeName] = font;

        result = [[[NSAttributedString alloc] initWithString:ruleDisplayName attributes:mattrs] autorelease];
    } else if ([colId isEqualToString:@"fg"]) {
        result = attrs[NSForegroundColorAttributeName];
    } else if ([colId isEqualToString:@"bg"]) {
        result = attrs[NSBackgroundColorAttributeName];
    } else if ([colId isEqualToString:@"bold"]) {
        result = @(isBold);
    } else if ([colId isEqualToString:@"italic"]) {
        result = @(isItalic);
    } else if ([colId isEqualToString:@"underline"]) {
        //result = @(isUnderline);
        result = attrs[NSUnderlineStyleAttributeName];
    } else {
        EDAssert(0);
    }
    
    //NSLog(@"%@ - %@", colId, [result class]);
    return result;
}


#pragma mark -
#pragma mark NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tv shouldSelectRow:(NSInteger)row {
    if (tv == _themeNamesTableView) {
        return [self themeNamesTableView:tv shouldSelectRow:row];
    } else {
        return [self themeRulesTableView:tv shouldSelectRow:row];
    }
}


- (BOOL)themeNamesTableView:(NSTableView *)tv shouldSelectRow:(NSInteger)row {
    EDAssertMainThread();
    
    if (!_hasLoaded) return NO;
    
    [self changeThemeNameSelectionToRow:row];
    return YES;
}


- (BOOL)themeRulesTableView:(NSTableView *)tv shouldSelectRow:(NSInteger)row {
    return YES;
}

@end
