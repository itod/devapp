//
//  EDProjectWindowController.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/29/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDProjectWindowController.h"
#import "EDUserDefaults.h"
#import "EDNewProjectParams.h"
#import <TDAppKit/TDColorView.h>
#import <TDAppKit/TDUtils.h>

@interface EDProjectWindowController ()
- (void)endSheet:(NSInteger)code;
@end

@implementation EDProjectWindowController {
    BOOL menuLoaded;
}

- (id)init {
    self = [super initWithWindowNibName:@"EDProjectWindow"];
    if (self) {
        self.projParams = [[[EDNewProjectParams alloc] init] autorelease];
    }
    return self;
}


- (id)initWithWindowNibName:(NSString *)name {
    EDAssert(0);
    self = nil;
    return self;
}


- (void)dealloc {
    self.imageContainerView = nil;
    self.dimImageView = nil;
    self.formContainerView = nil;

    self.nameContainerView = nil;
    self.nameTextField = nil;
    self.okButton = nil;

    self.filename = nil;
    self.projParams = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark NSWindowController

- (void)windowDidLoad {
    EDAssert([self window]);
    EDAssert(_imageContainerView);
    EDAssert(_dimImageView);
    EDAssert(_formContainerView);
    EDAssert(_nameContainerView);
    EDAssert(_nameTextField);
    EDAssert(_okButton);
    
    [[self window] setOpaque:YES];
    
    _formContainerView.color = [NSColor windowBackgroundColor];
    
    [_dimImageView setAlphaValue:0.1];
    
    NSString *ok = NSLocalizedString(@"Next…", @"");
    [_okButton setTitle:ok];
    
    [[_nameTextField currentEditor] setSelectedRange:NSMakeRange(0, 0)];

    TDPerformOnMainThread(^{
        [[_nameTextField currentEditor] moveToBeginningOfLine:nil];
    });
}


#pragma mark -
#pragma mark Actions

- (IBAction)ok:(id)sender {
    //NSLog(@"%@", [selectedMetrics displayString]);
    if (![_projParams.name length]) {
        NSBeep();
        return;
    }
    
    [self endSheet:[sender tag]];
}


- (IBAction)cancel:(id)sender {
    [self endSheet:[sender tag]];
}


#pragma mark -
#pragma mark Private

- (void)endSheet:(NSInteger)code {
    [NSApp endSheet:[self window] returnCode:code];
}


//- (void)updateMenu {
//    if (_presetsPopUpButton) {
//        [self menuNeedsUpdate:[_presetsPopUpButton menu]];
//
//        // yep you have to do this in both places.
//        [self updateSelectedMenuItem];
//    }
//}
//
//
//- (void)updateSelectedMenuItem {
//    EDAssert([self.presetMetrics count]);
//    NSUInteger tag = [self.presetMetrics indexOfObject:_selectedMetrics];
//    if (NSNotFound == tag) {
//        tag = 0;
//    }
//    [_presetsPopUpButton selectItemWithTag:tag];
//    [_presetsPopUpButton synchronizeTitleAndSelectedItem];
//    [[[_presetsPopUpButton menu] itemWithTag:tag] setState:NSOnState];    
//}
//
//
//- (void)checkForMatchWithPresets {
//    EDAssert(_selectedMetrics);
//    CGFloat w = _selectedMetrics.width;
//    CGFloat h = _selectedMetrics.height;
//    
//    for (EDMetrics *m in self.presetMetrics) {
//        if (w == m.width && h == m.height) {
//            self.selectedMetrics = m;
//            [self updateMenu];
//            break;
//        }
//    }
//}


#pragma mark -
#pragma mark NSMenuDelegate

//- (void)menuWillOpen:(NSMenu *)menu {
//    // yep you have to do this in both places.
//    [self updateSelectedMenuItem];
//}
//
//
//- (void)menuNeedsUpdate:(NSMenu *)menu {
//    [menu removeAllItems];
//    
//    NSInteger group = 0;
//    
//    NSUInteger i = 0;
//    for (EDMetrics *m in self.presetMetrics) {
//        if (group != m.group) {
//            group = m.group;
//            [menu addItem:[NSMenuItem separatorItem]];
//        }
//        
//        NSString *title = nil;
//        if ([m isCustom]) {
//            title = [m name];
//        } else {
//            title = [m displayString];
//        }
//        NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title
//                                                       action:@selector(metricsSelected:)
//                                                keyEquivalent:@""] autorelease];
//        
//        [item setTarget:self];
//        [item setTag:i++];
//        [item setRepresentedObject:m];
//        [item setState:NSOffState];
//
//        [menu addItem:item];
//    }
//}


#pragma mark -
#pragma mark NSTextFieldDelegate

//- (void)controlTextDidChange:(NSNotification *)n {
//    EDMetrics *oldMetrics = self.selectedMetrics;
//    EDMetrics *newMetrics = [self.presetMetrics objectAtIndex:0]; // custom
//    
//    newMetrics.width = oldMetrics.width;
//    newMetrics.height = oldMetrics.height;
//    self.selectedMetrics = newMetrics;
//    
//    [self updateMenu];
//}
//
//
//- (void)controlTextDidEndEditing:(NSNotification *)n {
//    [self checkForMatchWithPresets];
//}


#pragma mark -
#pragma mark Properties

@end
