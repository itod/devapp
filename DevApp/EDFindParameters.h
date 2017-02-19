//
//  EDFindParameters.h
//  Editor
//
//  Created by Todd Ditchendorf on 9/10/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDFindParameters : NSObject

+ (EDFindParameters *)findParametersWithRootPath:(NSString *)root searchText:(NSString *)search replaceText:(NSString *)replace matchCase:(BOOL)matchCase useRegex:(BOOL)useRegex;

@property (nonatomic, copy) NSString *rootPath;

@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, copy) NSString *replaceText;

@property (nonatomic, assign) BOOL matchCase;
@property (nonatomic, assign) BOOL useRegex;

//@property (nonatomic, retain) NSRegularExpression *searchRegex;
//@property (nonatomic, retain) NSRegularExpression *replaceRegex;
@end
