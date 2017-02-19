//
//  EDFilesystemNavBar.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/22/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFilesystemNavBar.h"
#import <TDAppKit/TDUtils.h>

@implementation EDFilesystemNavBar

- (void)awakeFromNib {
    self.mainBgGradient = TDVertGradient(0xeeeeee, 0xcccccc);
    self.mainBottomBevelColor = TDHexColor(0x999999);

    self.nonMainBgGradient = TDVertGradient(0xefefef, 0xdddddd);
    self.nonMainBottomBevelColor = TDHexColor(0xaaaaaa);
}

@end
