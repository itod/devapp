//
//  EDEnvironmentVariable.h
//  Editor
//
//  Created by Todd Ditchendorf on 10/22/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

@interface EDEnvironmentVariable : EDModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *value;
@end
