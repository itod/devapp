//
//  EDMainWindow.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/19/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDMainWindow.h"
#import "EDMainWindowController.h"
#import "EDDocumentController.h"

@implementation EDMainWindow

//- (void)performClose:(id)sender {
//    [super performClose:sender];
//    
//}
//
//
//- (void)close {
//    [super close];
//}


// this is necessary to prevent NSBeep() on every key press in the findPanel
- (BOOL)makeFirstResponder:(NSResponder *)resp {
    EDMainWindowController *wc = [self windowController];
    if (wc.isTypingInFindPanel) {
        if ([[resp className] isEqualToString:@"WebHTMLView"]) {
            return NO;
        }
    }
    return [super makeFirstResponder:resp];
}


- (IBAction)toggleFullScreen:(id)sender {
#ifndef APPSTORE
    if (![[EDDocumentController instance] isLicensed]) {
        [[EDDocumentController instance] runNagDialog];
        return;
    }
#endif
    if ([super respondsToSelector:@selector(toggleFullScreen:)]) {
        [super toggleFullScreen:sender];
    }
}

@end
