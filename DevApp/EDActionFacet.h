//
//  EDActionFacet.h
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewController.h>

@class EDAction;

@interface EDActionFacet : TDViewController

+ (NSString *)name;
+ (NSString *)displayName;
+ (NSString *)nibName;

- (id)init; // use me

@property (nonatomic, retain) EDAction *selectedAction;
@end
