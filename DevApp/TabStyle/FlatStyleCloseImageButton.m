//
//  FlatStyleCloseImageButton.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/15/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "FlatStyleCloseImageButton.h"
#import <TabKit/TKTabListItemStyle.h>

@implementation FlatStyleCloseImageButton

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setButtonType:NSMomentaryChangeButton];
        [self setImagePosition:NSImageOnly];
        [self setBordered:NO];
        
        self.nonMainNormalImage = [NSImage imageNamed:@"flat_tab_non_main_normal"];
        TDAssert(_nonMainNormalImage);

        self.normalImage = [NSImage imageNamed:@"flat_tab_normal"];
        TDAssert(_normalImage);
        [self setImage:_normalImage];
        
        self.selectedImage = [NSImage imageNamed:@"flat_tab_selected"];
        TDAssert(_selectedImage);
        
        self.pressedImage = [NSImage imageNamed:@"flat_tab_hover"];
        TDAssert(_pressedImage);
        [self setAlternateImage:_pressedImage];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.normalImage = nil;
    self.selectedImage = nil;
    self.nonMainNormalImage = nil;
    self.hoverImage = nil;
    self.pressedImage = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    
}


- (void)viewDidMoveToWindow {
    NSWindow *win = [self window];
    if (win) {
        [self updateImage];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:win];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidResignMainNotification object:win];
    }
}


- (void)updateImage {
    TDAssert(_normalImage);
    TDAssert(_nonMainNormalImage);
    TDAssert([self window]);
    if (![self window]) return;
    
    BOOL isMain = [[self window] isMainWindow];
    NSImage *img = nil;
    if (isMain) {
        img = _selected ? _selectedImage : _normalImage;
    } else {
        img = _nonMainNormalImage;
    }
    if (img != [self image]) {
        [self setImage:img];
        [self setNeedsDisplay:YES];
    }
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    // this can be called right after a window is closed (it resigned as well)
    if ([self window]) {
        [self updateImage];
    }
}


- (void)setSelected:(BOOL)selected {
    if (selected != _selected) {
        _selected = selected;
        
        if ([self window]) {
            [self updateImage];
        }
    }
}

@end
