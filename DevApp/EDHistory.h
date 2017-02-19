//
//  EDHistory.h
//  Editor
//
//  Created by Todd Ditchendorf on 8/25/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDHistory : NSObject <NSCoding>

- (void)clear;
- (void)fastForward;

- (BOOL)canGoBack;
- (BOOL)canGoForward;

- (id)current;
- (void)insert:(id)item;

- (id)goBackBy:(NSUInteger)i;
- (id)goForwardBy:(NSUInteger)i;

- (NSArray *)backList;
- (NSArray *)forwardList;
@end
