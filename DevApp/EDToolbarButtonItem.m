//
//  EDToolbarButtonItem.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/30/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDToolbarButtonItem.h"
#import "EDToolbarButton.h"

#define TAG_BREAK 2040

@implementation EDToolbarButtonItem

- (void)dealloc {
    self.button = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [self setAutovalidates:YES];
    
    self.button = [[[EDToolbarButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 28.0, 23.0)] autorelease];

    if (TAG_BREAK == [self tag]) {
        [_button setButtonType:NSPushOnPushOffButton];
    } else {
        [_button setButtonType:NSMomentaryPushInButton];
    }
    
//    [[_button cell] setRepresentedObject:itemID];
    [_button setTarget:[self target]];
    [_button setAction:[self action]];
    if ([self image]) {
        [_button setImage:[self image]];
    }
    [self setView:_button];
}


- (NSSize)minSize {
    return NSMakeSize(33.0, 33.0);
}


- (NSSize)maxSize {
    return [self minSize];
}

@end
