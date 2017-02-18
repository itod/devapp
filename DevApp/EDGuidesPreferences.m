//
//  EDGuidesPreferences.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/27/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDGuidesPreferences.h"
#import "EDUserDefaults.h"

@implementation EDGuidesPreferences

- (IBAction)toggleRulersVisible:(id)sender {
    //[[EDUserDefaults instance] setRulersVisible:![[EDUserDefaults instance] rulersVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDRulersVisibleDidChangeNotification object:nil];
}


- (IBAction)toggleGuidesVisible:(id)sender {
    //[[EDUserDefaults instance] setGuidesVisible:![[EDUserDefaults instance] guidesVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDGuidesVisibleDidChangeNotification object:nil];
}


- (IBAction)toggleGuidesLocked:(id)sender {
    //[[EDUserDefaults instance] setGuidesLocked:![[EDUserDefaults instance] guidesLocked]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDGuidesLockedDidChangeNotification object:nil];
}


- (IBAction)toggleGridVisible:(id)sender {
    //[[EDUserDefaults instance] setGridVisible:![[EDUserDefaults instance] gridVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDGridVisibleDidChangeNotification object:nil];
}

@end
