//
//  EDFileEncodingDetector.h
//  Editor
//
//  Created by Todd Ditchendorf on 12/29/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDFileEncodingDetector : NSObject

+ (instancetype)instance;

// returns 0 on failure

// NSUTF8StringEncoding = 4,
// NSUTF16BigEndianStringEncoding = 0x90000100,          /* NSUTF16StringEncoding encoding with explicit endianness specified */
// NSUTF16LittleEndianStringEncoding = 0x94000100,       /* NSUTF16StringEncoding encoding with explicit endianness specified */

- (NSStringEncoding)stringEncodingForData:(NSData *)data fromPath:(NSString *)absPath;
@end
