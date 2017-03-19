//
//  EDApplication.h
//  Editor
//
//  Created by Todd Ditchendorf on 8/13/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <IDEKit/IDEApplication.h>

@interface EDApplication : IDEApplication

#ifndef APPSTORE
- (void)removeUnlicensedMenuItems;
#endif

@property (atomic, retain) NSGraphicsContext *canvasGraphicsContext;
@property (atomic, retain, readonly) NSMutableArray *strokeWeightStack;
@end
