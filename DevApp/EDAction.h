//
//  EDAction.h
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

@interface EDAction : EDModel //<NSCoding>

+ (NSString *)name;
+ (NSString *)displayName;
+ (NSString *)iconName;
+ (NSArray *)facetClassNames;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSImage *icon;

@property (nonatomic, copy) NSString *commandString;
@property (nonatomic, retain) NSMutableArray *environmentVariables;
@end
