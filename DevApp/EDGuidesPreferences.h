//
//  EDGuidesPreferences.h
//  Editor
//
//  Created by Todd Ditchendorf on 11/27/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <IDEKit/IDEBasePreferences.h>

@interface EDGuidesPreferences : IDEBasePreferences

- (IBAction)toggleRulersVisible:(id)sender;
- (IBAction)toggleGuidesVisible:(id)sender;
- (IBAction)toggleGuidesLocked:(id)sender;
- (IBAction)toggleGridVisible:(id)sender;
@end
