//
//  EDModel.h
//  Editor
//
//  Created by Todd Ditchendorf on 10/21/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDModel : NSObject
+ (instancetype)fromPlist:(NSDictionary *)plist;
- (instancetype)initFromPlist:(NSDictionary *)plist;
- (NSDictionary *)asPlist;
@end
