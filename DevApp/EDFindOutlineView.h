//
//  EDFindOutlineView.h
//  Editor
//
//  Created by Todd Ditchendorf on 12/7/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// this supports clicking on an already selected row to re-highlight
@protocol EDFindOutlineViewDelegate <NSOutlineViewDelegate>
- (void)findOutlineView:(NSOutlineView *)ov didReceiveClickOnRow:(NSInteger)row;
- (void)findOutlineViewDidDidEscape:(NSOutlineView *)ov;
@end

@interface EDFindOutlineView : NSOutlineView

@end
