//
//  EDTarget.h
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

@class EDScheme;

@interface EDTarget : EDModel //<NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) EDScheme *scheme;
@end
