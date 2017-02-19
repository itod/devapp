//
//  EDFindParameters.m
//  Editor
//
//  Created by Todd Ditchendorf on 9/10/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFindParameters.h"

@implementation EDFindParameters

+ (EDFindParameters *)findParametersWithRootPath:(NSString *)root searchText:(NSString *)search replaceText:(NSString *)replace matchCase:(BOOL)matchCase useRegex:(BOOL)useRegex {
    EDFindParameters *params = [[[EDFindParameters alloc] init] autorelease];
    params.rootPath = root;
    params.searchText = search;
    params.replaceText = replace;
    params.matchCase = matchCase;
    params.useRegex = useRegex;
    return params;
}


- (void)dealloc {
    self.rootPath = nil;
    self.searchText = nil;
    self.replaceText = nil;
//    self.searchRegex = nil;
//    self.replaceRegex = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p\nRoot: `%@`\nSearch: `%@`\nReplace: `%@`\nWhitespace: %d\nRegex: %d>", [self class], self, _rootPath, _searchText, _replaceText, _matchCase, _useRegex];
}


- (BOOL)isEqual:(id)obj {
    if (![obj isKindOfClass:[EDFindParameters class]]) {
        return NO;
    }
    
    EDFindParameters *params = (EDFindParameters *)obj;
    if (_matchCase != params->_matchCase) {
        return NO;
    }

    if (_useRegex != params->_useRegex) {
        return NO;
    }

    if (![_rootPath isEqualToString:params->_rootPath]) {
        return NO;
    }

    if (![_searchText isEqualToString:params->_searchText]) {
        return NO;
    }

    if (![_replaceText isEqualToString:params->_replaceText]) {
        return NO;
    }

    return YES;
}

@end
