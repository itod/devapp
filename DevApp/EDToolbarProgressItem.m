//
//  EDToolbarProgressItem.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDToolbarProgressItem.h"
#import "EDToolbarProgressView.h"
#import <TDAppKit/TDColorView.h>

@implementation EDToolbarProgressItem

- (void)dealloc {

    [super dealloc];
}


- (void)awakeFromNib {
    [self setAutovalidates:YES];
    
    EDToolbarProgressView *v = [[[EDToolbarProgressView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 100.0)] autorelease];
    
    [v setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [v setNeedsLayout];
    
    [self setView:v];
}

@end
