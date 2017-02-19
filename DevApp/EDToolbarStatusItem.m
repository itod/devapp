//
//  EDToolbarStatusItem.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDToolbarStatusItem.h"
#import "EDToolbarStatusView.h"
#import <TDAppKit/TDColorView.h>

@implementation EDToolbarStatusItem

- (void)dealloc {

    [super dealloc];
}


- (NSSize)minSize {
    return NSMakeSize(500.0, 30.0);
}


- (NSSize)maxSize {
    return [self minSize];
}


- (void)awakeFromNib {
    [self setAutovalidates:YES];
    
    NSSize size = [self minSize];
    EDToolbarStatusView *v = [[[EDToolbarStatusView alloc] initWithFrame:NSMakeRect(0.0, 0.0, size.width, size.height)] autorelease];
    
    [v setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [v setNeedsLayout];
    
    [self setView:v];
}

@end
