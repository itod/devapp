//
//  EDToolbarButton.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/30/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDToolbarButton.h"
#import "EDToolbarButtonCell.h"

@implementation EDToolbarButton

+ (Class)cellClass {
    return [EDToolbarButtonCell class];
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //    [[_button cell] setRepresentedObject:itemID];
        [self setBezelStyle:NSTexturedRoundedBezelStyle];
    }
    return self;
}

@end
