//
//  FlatStyleCloseImageButton.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/15/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "FlatTabStyle.h"

@interface FlatStyleCloseImageButton : NSButton
@property (nonatomic, retain) NSImage *normalImage;
@property (nonatomic, retain) NSImage *selectedImage;
@property (nonatomic, retain) NSImage *nonMainNormalImage;
@property (nonatomic, retain) NSImage *hoverImage;
@property (nonatomic, retain) NSImage *pressedImage;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@property (nonatomic, assign) TKTabItemPointerState pointerState;
@end
