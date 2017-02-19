//
//  EDFileWindowController.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/29/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDFileWindowController.h"
#import "EDUserDefaults.h"
#import <TDAppKit/TDColorView.h>
#import <TDAppKit/TDUtils.h>

@interface EDFileWindowController ()
- (void)endSheet:(NSInteger)code;

@property (nonatomic, assign, readwrite) BOOL nameVisible;
@end

@implementation EDFileWindowController

- (id)init {
    self = [self initWithWindowNibName:@"EDFileWindow"];
    return self;
}


- (id)initWithWindowNibName:(NSString *)name {
    self = [super initWithWindowNibName:name];
    if (self) {

    }
    return self;
}


- (void)dealloc {
    self.imageContainerView = nil;
    self.dimImageView = nil;
    self.formContainerView = nil;
    self.filenameTextField = nil;
    self.filename = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSWindowController

- (void)windowDidLoad {
    EDAssert([self window]);
    EDAssert(_imageContainerView);
    EDAssert(_dimImageView);
    EDAssert(_formContainerView);
    EDAssert(_filenameTextField);
    
    [[self window] setOpaque:YES];
    [_dimImageView setAlphaValue:0.1];

    _formContainerView.color = [NSColor windowBackgroundColor];
    
    self.filename = @".py";
    [[_filenameTextField currentEditor] setSelectedRange:NSMakeRange(0, 0)];
    
    TDPerformOnMainThread(^{
        [[_filenameTextField currentEditor] moveToBeginningOfLine:nil];
    });
}


#pragma mark -
#pragma mark Actions

- (IBAction)ok:(id)sender {

    if (![_filename length]) {
        NSBeep();
        return;
    }
    
    if ([_filename rangeOfString:@"/"].length) {
        NSBeep();
        return;
    }
    
    if (![[_filename pathExtension] isEqualToString:@"py"]) {
        self.filename = [_filename stringByAppendingPathExtension:@"py"];
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

@end
