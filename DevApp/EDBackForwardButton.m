//
//  EDBackForwardButton.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/29/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDBackForwardButton.h"
#import "EDMainWindowController.h"
#import "EDHistory.h"
#import "EDFileLocation.h"

#define BACK_FWD_ITEM_LIMIT 16
#define MENU_FUDGE_Y 3

@interface EDMainWindowController ()
- (EDHistory *)currentHistory;
@end

@implementation EDBackForwardButton {
    BOOL _didShowMenu;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self killTimer];
    [super dealloc];
}


- (void)killTimer {
    if (_timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}


- (void)mouseDown:(NSEvent *)evt {
    _didShowMenu = NO;
    if ([self isEnabled]) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(showMenu:) userInfo:nil repeats:NO];
        [self highlight:YES];
    }
}


- (void)mouseUp:(NSEvent *)evt {
    [self killTimer];
    
    if (!_didShowMenu) {
        [super mouseDown:evt];
        [super mouseUp:evt];
    } else {
        [self highlight:NO];
    }
}


- (void)menuDidEndTracking:(NSNotification *)n {
    [self highlight:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidEndTrackingNotification object:[n object]];
}


- (IBAction)showMenu:(id)sender {
    _didShowMenu = YES;
    NSMenu *menu = [self menu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidEndTracking:) name:NSMenuDidEndTrackingNotification object:menu];
    
    NSPoint point = NSZeroPoint;
    if ([self isFlipped]) {
        point.y = NSHeight([self frame]) + MENU_FUDGE_Y;
    } else {
        point.y = - MENU_FUDGE_Y;
    }
    point = [self convertPoint:point toView:nil];
    
    NSEvent *evt = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                      location:point
                                 modifierFlags:0
                                     timestamp:0.0
                                  windowNumber:[[self window] windowNumber]
                                       context:[NSGraphicsContext currentContext]
                                   eventNumber:0
                                    clickCount:1
                                      pressure:1.0];
    
    [NSMenu popUpContextMenu:menu withEvent:evt forView:self];
}


- (NSMenu *)menu {
    EDMainWindowController *wc = [[self window] windowController];
    EDHistory *history = [wc currentHistory];
    
    NSArray *historyItems = nil;
    
    BOOL isBackButton = (@selector(goBack:) == [self action]);
    if (isBackButton) {
        historyItems = [history backList];
    } else {
        historyItems = [history forwardList];
    }
    
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

    NSUInteger tag = 0;
    
    for (EDFileLocation *fileLoc in historyItems) {
        NSImage *icon = [fileLoc icon];
        
        NSString *title = [fileLoc title];
        if (![title length]) {
            title = [[fileLoc URLString] lastPathComponent];
        }
        
        NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:title
                                                           action:@selector(menuItemClick:)
                                                    keyEquivalent:@""] autorelease];
        [menuItem setTarget:self];
        [menuItem setImage:icon];
        [menuItem setTag:++tag];
        [menu addItem:menuItem];
    }
    
    return menu;
}


- (void)menuItemClick:(id)sender {
    EDMainWindowController *wc = [[self window] windowController];
    [wc performSelector:[self action] withObject:sender];
}

@end
