//
//  EDFindOutlineView.m
//  Editor
//
//  Created by Todd Ditchendorf on 12/7/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFindOutlineView.h"

@implementation EDFindOutlineView

- (void)mouseDown:(NSEvent *)evt {
    [super mouseDown:evt];
    CGPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
    
    NSInteger row = [self rowAtPoint:p];
    NSInteger lastRow = [self numberOfRows] - 1;
    if (row > -1 && row <= lastRow) {
        EDAssert(self.delegate && [self.delegate conformsToProtocol:@protocol(EDFindOutlineViewDelegate)]);
        id <EDFindOutlineViewDelegate>d = (id)self.delegate;
        [d findOutlineView:self didReceiveClickOnRow:row];
    }
}


- (void)cancelOperation:(id)sender {
    id <EDFindOutlineViewDelegate>d = (id)self.delegate;
    [d findOutlineViewDidDidEscape:self];
}

@end
