//
//  EDProjectWindowController.h
//  Editor
//
//  Created by Todd Ditchendorf on 11/29/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TDColorView;
@class EDNewProjectParams;

@interface EDProjectWindowController : NSWindowController <NSTextFieldDelegate, NSMenuDelegate>

- (id)init;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

@property (nonatomic, retain) IBOutlet NSView *imageContainerView;
@property (nonatomic, retain) IBOutlet NSImageView *dimImageView;
@property (nonatomic, retain) IBOutlet TDColorView *formContainerView;

@property (nonatomic, retain) IBOutlet NSView *nameContainerView;
@property (nonatomic, retain) IBOutlet NSTextField *nameTextField;
@property (nonatomic, retain) IBOutlet NSButton *okButton;

@property (nonatomic, retain) EDNewProjectParams *projParams;
@end
