//
//  EDFilesystemItem.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/21/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDFilesystemItem : NSObject <NSCoding>

+ (NSString *)pasteboardType;
+ (void)clearCache;
+ (EDFilesystemItem *)rootItem;
+ (EDFilesystemItem *)itemWithFullPath:(NSString *)fullPath;

- (NSInteger)numberOfChildren; // Returns -1 for leaf nodes
- (EDFilesystemItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes

- (EDFilesystemItem *)descendantAtFullPath:(NSString *)fullPath;

- (void)reloadChildren;

@property (nonatomic, copy, readonly) NSString *relativePath;
@property (nonatomic, copy, readonly) NSString *fullPath;
@property (nonatomic, retain, readonly) NSMutableArray *children;
@property (nonatomic, retain, readonly) NSImage *icon;

@property (nonatomic, assign, readonly) BOOL isLeaf;
@end
