//
//  TDDispatcher.h
//  DevApp
//
//  Created by Todd Ditchendorf on 9/27/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDDispatcher <NSObject>
- (void)performOnMainThread:(void (^)(void))block;
- (void)performOnControlThread:(void (^)(void))block;
- (void)performOnExecuteThread:(void (^)(void))block;
@end
