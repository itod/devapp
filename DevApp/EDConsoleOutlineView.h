//
//  EDConsoleOutlineView.h
//  Editor
//
//  Created by Todd Ditchendorf on 7/29/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EDConsoleOutlineView : NSOutlineView

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSColor *selectionColor;
@end
