//
//  EDBaseCodeRunner.h
//  DevApp
//
//  Created by Todd Ditchendorf on 9/27/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDCodeRunner.h"

@protocol TDDispatcher;

@interface EDBaseCodeRunner : NSObject <EDCodeRunner>

- (void)performOnMainThread:(void (^)(void))block;
- (void)performOnControlThread:(void (^)(void))block;
- (void)performOnExecuteThread:(void (^)(void))block;

@end
