//
//  EDTextEditingPreferences.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/13/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDTextEditingPreferences.h"
#import <TDAppKit/TDViewController.h>
#import <OkudaKit/OKViewController.h>

@interface EDTextEditingPreferences ()

@end

@implementation EDTextEditingPreferences

- (void)dealloc {

    [super dealloc];
}


#pragma mark -
#pragma mark NSWindowController

- (void)awakeFromNib {

}


#pragma mark -
#pragma mark Actions


- (IBAction)resetAutocompletionDelay:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:DEFAULT_VALUES_FILENAME ofType:@"plist"];
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    
    double val = [[defaultValues objectForKey:OKAutocompletionDelayKey] doubleValue];
    [[NSUserDefaults standardUserDefaults] setDouble:val forKey:OKAutocompletionDelayKey];

    val = [[defaultValues objectForKey:OKCanAcceptCompletionDelayKey] doubleValue];
    [[NSUserDefaults standardUserDefaults] setDouble:val forKey:OKCanAcceptCompletionDelayKey];
}

#pragma mark -
#pragma mark Private

@end
