//
//  EDScheme.h
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

@class EDRunAction;
@class EDTestAction;

@interface EDScheme : EDModel //<NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *selectedActionName;

@property (nonatomic, retain) EDRunAction *runAction;
@property (nonatomic, retain) EDTestAction *testAction;

@property (nonatomic, retain) NSArray *actions;
@end
