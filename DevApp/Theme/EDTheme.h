//
//  EDTheme.h
//  Editor
//
//  Created by Todd Ditchendorf on 11/26/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDTheme : NSObject

+ (EDTheme *)themeWithName:(NSString *)name attributes:(NSDictionary *)attrs;
- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attrs;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDictionary *attributes;
@end
