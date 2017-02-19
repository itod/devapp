//
//  EDConsoleControlBar.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/29/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDConsoleControlBar.h"

@implementation EDConsoleControlBar

+ (CGFloat)defaultHeight {
    return 21.0;
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.mainBgGradient = TDVertGradient(0xefefef, 0xcccccc);
        self.mainBottomBevelColor = TDHexColor(0x999999);

        self.nonMainBgGradient = TDVertGradient(0xefefef, 0xdfdfdf);
        self.nonMainBottomBevelColor = TDHexColor(0xafafaf);
}
    
    return self;
}
//
//
//- (void)dealloc {
//    
//    [super dealloc];
//}
//
//
//- (void)drawRect:(NSRect)dirtyRect {
//
//}


- (void)awakeFromNib {
    [[self window] setAcceptsMouseMovedEvents:YES];

}


- (BOOL)acceptsFirstResponder {
    return YES;
}


- (void)mouseEntered:(NSEvent *)evt {
    [[NSCursor dragCopyCursor] push];
}

- (void)mouseExited:(NSEvent *)evt {
    [[NSCursor currentCursor] pop];
}

@end
