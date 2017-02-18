//
//  EDPattern.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 1/31/13.
//
//

#import <Foundation/Foundation.h>

@interface EDPattern : NSObject

+ (id)patternWithString:(NSString *)s;

- (id)initWithString:(NSString *)s;
- (BOOL)isMatch:(NSString *)s;

- (void)stringDidChange;

@property (nonatomic, copy) NSString *string;
@end
