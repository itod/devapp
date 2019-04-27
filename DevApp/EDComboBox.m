//
//  EDComboBox.m
//  Grafik Konsol
//
//  Created by Todd Ditchendorf on 4/27/19.
//  Copyright © 2019 Celestial Teapot. All rights reserved.
//

#import "EDComboBox.h"
#import <TDAppKit/TDUtils.h>

NSString * const EDComboBoxDidBecomeFirstResponderNotification = @"EDComboBoxDidBecomeFirstResponderNotification";

@implementation EDComboBox

- (BOOL)becomeFirstResponder {
    BOOL status = [super becomeFirstResponder];
    if (status) {
        //[self.cellView textFieldDidBecomeFirstResponder:self];
        TDPerformOnMainThreadAfterDelay(0.0, ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:EDComboBoxDidBecomeFirstResponderNotification object:self];
        });
    }
    return status;
}


- (BOOL)resignFirstResponder {
    BOOL status = [super resignFirstResponder];
    //if (status) [self.cellView textFieldDidResignFirstResponder:self];
    return status;
}

@end
