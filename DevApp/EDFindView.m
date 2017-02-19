//
//  EDFindView.m
//  Editor
//
//  Created by Todd Ditchendorf on 9/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFindView.h"

#define COMBOBOX_MARGIN_LEFT 66.0
#define FIND_COMBOBOX_MARGIN_RIGHT 100.0
#define REPLACE_COMBOBOX_MARGIN_RIGHT 13.0
#define COMBOBOX_HEIGHT 22.0

#define COMBOBOX_MIN_WIDTH 100.0

#define SCROLL_MARGIN_TOP 83.0
#define SCROLL_Y 39.0

#define SEARCH_Y 10.0
#define REPLACE_Y 35.0

//#define REPLACE_BUTTON_MIN_X 180.0
//#define SEARCH_BUTTON_MIN_X (REPLACE_BUTTON_MIN_X + 113.0)

@implementation EDFindView

- (void)dealloc {
    self.searchComboBox = nil;
    self.replaceComboBox = nil;
    self.scopePopUpButton = nil;
    self.scrollView = nil;
    self.resultCountLabel = nil;
    self.busySpinner = nil;
    self.searchButton = nil;
    self.replaceButton = nil;

    [super dealloc];
}


//- (void)drawRect:(NSRect)dirtyRect {
//    [NSBezierPath setDefaultLineWidth:10.0];
//    [NSBezierPath strokeRect:[self bounds]];
//}


- (void)layoutSubviews {
    EDAssert(_searchComboBox);
    EDAssert(_replaceComboBox);
    EDAssert(_scopePopUpButton);
    EDAssert(_scrollView);
    EDAssert(_resultCountLabel);
    EDAssert(_busySpinner);
    EDAssert(_searchButton);
    EDAssert(_replaceButton);
    
    NSRect bounds = [self bounds];
    
    _searchComboBox.frame = [self searchComboBoxRectForBounds:bounds];
    _replaceComboBox.frame = [self replaceComboBoxRectForBounds:bounds];
    _scrollView.frame = [self scrollViewRectForBounds:bounds];
    
    BOOL scopeHidden = bounds.size.width < 260.0;
    BOOL busyHidden = bounds.size.width < 325.0;
    BOOL replaceHidden = bounds.size.width < 295.0;
    BOOL searchHidden = bounds.size.width < 180.0;
    BOOL resultCountHidden = bounds.size.width < 340.0;

    [_scopePopUpButton setHidden:scopeHidden];
    [_busySpinner setHidden:busyHidden];
    [_replaceButton setHidden:replaceHidden];
    [_searchButton setHidden:searchHidden];
    [_resultCountLabel setHidden:resultCountHidden];

//    _searchButton.frame = [self searchButtonRectForBounds:bounds];
//    _replaceButton.frame = [self replaceButtonRectForBounds:bounds];
}


- (CGRect)searchComboBoxRectForBounds:(CGRect)bounds {
    CGFloat x = COMBOBOX_MARGIN_LEFT;
    CGFloat y = bounds.size.height - (SEARCH_Y + COMBOBOX_HEIGHT);
    CGFloat w = bounds.size.width - (x + FIND_COMBOBOX_MARGIN_RIGHT);
    CGFloat h = COMBOBOX_HEIGHT;
    
    w = MAX(COMBOBOX_MIN_WIDTH, w);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)replaceComboBoxRectForBounds:(CGRect)bounds {
    CGFloat x = COMBOBOX_MARGIN_LEFT;
    CGFloat y = bounds.size.height - (REPLACE_Y + COMBOBOX_HEIGHT);
    CGFloat w = bounds.size.width - (x + REPLACE_COMBOBOX_MARGIN_RIGHT);
    CGFloat h = COMBOBOX_HEIGHT;
    
    w = MAX(COMBOBOX_MIN_WIDTH, w);

    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (CGRect)scrollViewRectForBounds:(CGRect)bounds {
    CGFloat x = 0.0;
    CGFloat y = SCROLL_Y;
    CGFloat w = bounds.size.width;
    CGFloat h = bounds.size.height - (SCROLL_Y + SCROLL_MARGIN_TOP);
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


//- (CGRect)searchButtonRectForBounds:(CGRect)bounds {
//    CGRect r = [_searchButton frame];
//    
//    CGFloat x = r.origin.x;
//    x = MIN(SEARCH_BUTTON_MIN_X, x);
//    r.origin.x = x;
//    
//    return r;
//}
//
//
//- (CGRect)replaceButtonRectForBounds:(CGRect)bounds {
//    CGRect r = [_replaceButton frame];
//    
//    CGFloat x = r.origin.x;
//    x = MIN(REPLACE_BUTTON_MIN_X, x);
//    r.origin.x = x;
//    
//    return r;
//}

@end
