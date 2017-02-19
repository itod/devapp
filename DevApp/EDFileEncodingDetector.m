//
//  EDFileEncodingDetector.m
//  Editor
//
//  Created by Todd Ditchendorf on 12/29/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFileEncodingDetector.h"
#import "EDUtils.h"
#import <TDAppKit/TDUtils.h>

#define MAX_LEN 15

static EDFileEncodingDetector *sInstance = nil;
static NSRegularExpression *sRegex = nil;

@implementation EDFileEncodingDetector

+ (void)initialize {
    if ([EDFileEncodingDetector class] == self) {
        
        EDAssert(!sInstance);
        sInstance = [[EDFileEncodingDetector alloc] init];
        
        EDAssert(!sRegex);
        NSString *pat =

                // invalid match
//            @"("
//            @"[\\xC0-\\xC1] # Invalid UTF-8 Bytes\n"
//            @"| [\\xF5-\\xFF] # Invalid UTF-8 Bytes\n"
//            @"| \\xE0[\\x80-\\x9F] # Overlong encoding of prior code point\n"
//            @"| \\xF0[\\x80-\\x8F] # Overlong encoding of prior code point\n"
//            @"| [\\xC2-\\xDF](?![\\x80-\\xBF]) # Invalid UTF-8 Sequence Start\n"
//            @"| [\\xE0-\\xEF](?![\\x80-\\xBF]{2}) # Invalid UTF-8 Sequence Start\n"
//            @"| [\\xF0-\\xF4](?![\\x80-\\xBF]{3}) # Invalid UTF-8 Sequence Start\n"
//            @"| (?<=[\\x0-\\x7F\\xF5-\\xFF])[\\x80-\\xBF] # Invalid UTF-8 Sequence Middle\n"
//            @"| (?<![\\xC2-\\xDF]|[\\xE0-\\xEF]|[\\xE0-\\xEF][\\x80-\\xBF]|[\\xF0-\\xF4]|[\\xF0-\\xF4][\\x80-\\xBF]|[\\xF0-\\xF4][\\x80-\\xBF]{2})[\\x80-\\xBF] # Overlong Sequence\n"
//            @"| (?<=[\\xE0-\\xEF])[\\x80-\\xBF](?![\\x80-\\xBF]) # Short 3 byte sequence\n"
//            @"| (?<=[\\xF0-\\xF4])[\\x80-\\xBF](?![\\x80-\\xBF]{2}) # Short 4 byte sequence\n"
//            @"| (?<=[\\xF0-\\xF4][\\x80-\\xBF])[\\x80-\\xBF](?![\\x80-\\xBF]) # Short 4 byte sequence (2)\n"
//            @")";

        // valid match
        @"^(\n"
        @"  [\\x09\\x0A\\x0D\\x20-\\x7E]            # ASCII\n"
        @"| [\\xC2-\\xDF][\\x80-\\xBF]             # non-overlong 2-byte\n"
        @"|  \\xE0[\\xA0-\\xBF][\\x80-\\xBF]        # excluding overlongs\n"
        @"| [\\xE1-\\xEC\\xEE\\xEF][\\x80-\\xBF]{2}  # straight 3-byte\n"
        @"|  \\xED[\\x80-\\x9F][\\x80-\\xBF]        # excluding surrogates\n"
        @"|  \\xF0[\\x90-\\xBF][\\x80-\\xBF]{2}     # planes 1-3\n"
        @"| [\\xF1-\\xF3][\\x80-\\xBF]{3}          # planes 4-15\n"
        @"|  \\xF4[\\x80-\\x8F][\\x80-\\xBF]{2}     # plane 16\n"
        @")*$";
        
        NSError *err = nil;
        sRegex = [[NSRegularExpression alloc] initWithPattern:pat options:NSRegularExpressionAllowCommentsAndWhitespace error:&err];
        if (!sRegex) {
            if (err) NSLog(@"%@", err);
            EDAssert(0);
        }
    }
}


+ (instancetype)instance {
    return sInstance;
}


- (id)init {
    EDAssertMainThread();
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)dealloc {

    [super dealloc];
}


- (NSStringEncoding)stringEncodingForData:(NSData *)data fromPath:(NSString *)absPath {
    NSStringEncoding result = 0;
    
    NSUInteger totalLen = [data length];
    NSUInteger buffLen = MIN(MAX_LEN, totalLen);
    
    uint8_t buff[buffLen];
    [data getBytes:buff length:buffLen];
    
    // UTF-32BE BOM 0x00,0x00,0xFE,0xFF
    if (buffLen >= 4 && 0x00 == buff[0] && 0x00 == buff[1] && 0xFE == buff[2] && 0xFF == buff[3]) {
        result = NSUTF32BigEndianStringEncoding;
        goto done;
    }
    
    // UTF-32LE BOM 0xFF,0xFE,0x00,0x00
    if (buffLen >= 4 && 0xFF == buff[0] && 0xFE == buff[1] && 0x00 == buff[2] && 0x00 == buff[3]) {
        result = NSUTF32LittleEndianStringEncoding;
        goto done;
    }
    
    // UTF-16BE BOM 0xFE,0xFF
    if (buffLen >= 2 && 0xFE == buff[0] && 0xFF == buff[1]) {
        result = NSUTF16BigEndianStringEncoding;
        goto done;
    }
    
    // UTF-16LE BOM 0xFF,0xFE
    if (buffLen >= 2 && 0xFF == buff[0] && 0xFE == buff[1]) {
        result = NSUTF16LittleEndianStringEncoding;
        goto done;
    }
    
    // UTF-8 BOM 0xEF,0xBB,0xBF (ewww)
    if (buffLen >= 3 && 0xEF == buff[0] && 0xBB == buff[1] && 0xBF == buff[2]) {
        result = NSUTF8StringEncoding;
        goto done;
    }
    
    // check extended attrs
    result = [self stringEncodingFromExtendedAttrsAtPath:absPath];
    if (result > 0 && NSNotFound != result) {
        // found it!
        //NSLog(@"%@", TDTextEncodingNameFromNSStringEncoding(result));
        goto done;
    }
    
    // ok, it's a file with zero length contents and no BOM or xattr. Assume UTF-8
    if (0 == buffLen) {
        result = NSUTF8StringEncoding;
        goto done;
    }
    
    // ok, it's a file with non-zero length contents and no BOM or xattr. Probably UTF-8
    if ([self isBufferProbablyValidUTF8:buff length:buffLen]) {
        result = NSUTF8StringEncoding;
        goto done;
    }

done:
    return result;
}


#pragma mark -
#pragma mark Private

- (NSStringEncoding)stringEncodingFromExtendedAttrsAtPath:(NSString *)absPath {
    NSStringEncoding result = 0;
    
    NSString *name = @"com.apple.TextEncoding";

    NSString *encName = EDGetXAttr(absPath, name, nil);
    if (![encName length]) {
        //EDAssert(0);
        goto done;
    }
    
    // utf-8;134217984
    // utf-16le;335544576
    NSArray *comps = [encName componentsSeparatedByString:@";"];
	
	if ([comps count] >= 2 && [comps[1] length]) {
		result = CFStringConvertEncodingToNSStringEncoding([comps[1] intValue]);
        //EDAssert(result > 0);
        goto done;
	}
    
    if ([comps count] && [comps[0] length]) {
		CFStringEncoding cfenc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)comps[0]);

		if (kCFStringEncodingInvalidId == cfenc) {
			NSLog(@"couldn't convert IANA charset");
			result = 0;
		} else {
            result = CFStringConvertEncodingToNSStringEncoding(cfenc);
        }
        EDAssert(result > 0);
        goto done;
    }
    
done:
    EDAssert(NSNotFound != result);
    return result;
}


- (BOOL)isBufferProbablyValidUTF8:(uint8_t *)buff length:(NSInteger)len {
    BOOL result = NO;
    
    if (len > 0) {
        NSString *str = [[[NSString alloc] initWithBytesNoCopy:buff length:len encoding:NSUTF8StringEncoding freeWhenDone:NO] autorelease];
        if ([str length]) {
            NSUInteger num = [sRegex numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])];
            //result = num == 0;
            result = num > 0;
        }
    }
    
    return result;
}

@end
