//
//  EDMainWindowController.m
//  DevApp
//
//  Created by Todd Ditchendorf on 23.01.17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDMainWindowController.h"

@interface EDMainWindowController ()

@end

@implementation EDMainWindowController

- (instancetype)init {
    return [self initWithWindowNibName:NSStringFromClass([self class])];
}


- (void)dealloc {
    
    [super dealloc];
}


#pragma mark -
#pragma mark NSWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

}

@end
