//
//  EDFileLocation.h
//  Editor
//
//  Created by Todd Ditchendorf on 9/5/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

@interface EDFileLocation : EDModel <NSCopying>

+ (EDFileLocation *)fileLocationWithURLString:(NSString *)URLString;
+ (EDFileLocation *)fileLocationWithURLString:(NSString *)URLString lineNumber:(NSUInteger)lineNum;

+ (EDFileLocation *)fileLocationWithURLString:(NSString *)URLString selectedRange:(NSRange)selRange;
+ (EDFileLocation *)fileLocationWithURLString:(NSString *)URLString selectedRange:(NSRange)selRange visibleRange:(NSRange)visRange;

- (id)initWithURLString:(NSString *)URLString;

@property (nonatomic, retain, readonly) NSString *URLString;
@property (nonatomic, assign) NSUInteger lineNumber;
@property (nonatomic, assign) NSRange selectedRange;
@property (nonatomic, assign) NSRange visibleRange;

@property (nonatomic, assign, readonly) BOOL hasSelectedRange;
@property (nonatomic, assign, readonly) BOOL hasVisibleRange;

// display
@property (nonatomic, retain) NSAttributedString *preview;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, retain, readonly) NSImage *icon;
@property (nonatomic, assign) BOOL selected;
@end
