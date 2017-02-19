//
//  EDTabModel.h
//  Editor
//
//  Created by Todd Ditchendorf on 8/27/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TabKit/TKTabModel.h>

#define EDTabModelTypeREPL @"EDTabModelTypeREPL"
#define EDTabModelTypeProjectSettings @"EDTabModelTypeProjectSettings"
#define EDTabModelTypeSourceCodeFile @"EDTabModelTypeSourceCodeFile"
#define EDTabModelTypeWebLocation @"EDTabModelTypeWebLocation"

@class EDHistory;

@interface EDTabModel : TKTabModel
+ (EDTabModel *)lastModified:(EDTabModel *)tm, ...;

+ (instancetype)fromPlist:(NSDictionary *)plist;
- (instancetype)initFromPlist:(NSDictionary *)plist;
- (NSDictionary *)asPlist;

- (void)setURLString:(NSString *)URLString storeInHistory:(BOOL)store;

- (void)modified;
- (BOOL)isMoreRecentlyModifiedThan:(EDTabModel *)tm;

@property (nonatomic, retain) EDHistory *history;
@property (nonatomic, assign) NSTimeInterval lastModified;
@end
