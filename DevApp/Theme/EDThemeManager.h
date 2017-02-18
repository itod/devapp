//
//  EDThemeManager.h
//  Editor
//
//  Created by Todd Ditchendorf on 12/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <OkudaKit/OKSyntaxHighlighter.h>

@class EDTheme;

@interface EDThemeManager : NSObject <OKSyntaxHighlighterAttributesProvider>

+ (EDThemeManager *)instance;

- (EDTheme *)themeNamed:(NSString *)name;

@property (nonatomic, retain) EDTheme *selectedTheme;
@property (nonatomic, retain, readonly) NSArray *orderedThemes;
@end
