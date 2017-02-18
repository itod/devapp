//
//  EDDefaultFontTextField.m
//  Shapes
//
//  Created by Todd Ditchendorf on 11/14/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFontPickerTextField.h"
#import <TDAppKit/TDUtils.h>

NSString * const EDFontPickerTextFieldDidFocusNotification = @"EDFontPickerTextFieldDidFocusNotification";

@implementation EDFontPickerTextField

//- (BOOL)becomeFirstResponder {
//    BOOL result = [super becomeFirstResponder];
//    if (result) {
//        TDPerformOnMainThreadAfterDelay(0.0, ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:EDDefaultFontTextFieldDidFocusNotification object:self];
//        });
//    }
//    return result;
//}


- (void)mouseDown:(NSEvent *)evt {
    [super mouseDown:evt];
    
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:EDFontPickerTextFieldDidFocusNotification object:self];
    });
}

@end
