//
//  EDThemeManager.m
//  Editor
//
//  Created by Todd Ditchendorf on 12/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDThemeManager.h"
#import "EDTheme.h"

#import "OKMiniCSSParser.h"
#import "OKMiniCSSAssembler.h"

#import <OkudaKit/OKUtils.h>

static EDThemeManager *sInstance = nil;

@interface EDThemeManager ()
@property (nonatomic, retain) NSMutableDictionary *themeCache;
@property (nonatomic, retain, readwrite) NSArray *orderedThemes;

@property (nonatomic, retain) PKParser *miniCSSParser;
@property (nonatomic, retain) OKMiniCSSAssembler *miniCSSAssembler;
@end

@implementation EDThemeManager

+ (void)initialize {
    EDAssertMainThread()
    if ([EDThemeManager class] == self) {
        EDAssert(!sInstance);
        sInstance = [[EDThemeManager alloc] init];
    }
}


+ (EDThemeManager *)instance {
    EDAssertMainThread();
    return sInstance;
}


- (id)init {
    self = [super init];
    if (self) {
        self.themeCache = [NSMutableDictionary dictionary];
        
        NSString *selThemeName = [[EDUserDefaults instance] selectedThemeName];
        self.selectedTheme = [self themeNamed:selThemeName];
        EDAssert(_selectedTheme);
    }
    return self;
}


- (void)dealloc {
    self.selectedTheme = nil;
    self.themeCache = nil;
    self.orderedThemes = nil;
    
    self.miniCSSParser = nil;
    self.miniCSSAssembler = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (EDTheme *)themeNamed:(NSString *)name {
    EDAssertMainThread();
    EDAssert([name length]);
    EDAssert(_themeCache);
    
    EDTheme *theme = _themeCache[name];
    
    if (!theme) {
        theme = [self loadThemeNamed:name];
        _themeCache[name] = theme;
    }
    
    return theme;
}


#pragma mark -
#pragma mark Private

- (NSString *)themeDirPath {
    NSString *themeDirPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"css"];
    return themeDirPath;
}


- (NSString *)filenameForThemeName:(NSString *)themeName {
    NSString *filename = [themeName stringByAppendingPathExtension:@"css"];
    EDAssert([filename length]);
    return filename;
}


- (NSString *)themeNameForFilename:(NSString *)filename {
    NSString *themeName = [filename stringByDeletingPathExtension];
    EDAssert([themeName length]);
    return themeName;
}


- (EDTheme *)loadThemeNamed:(NSString *)themeName {
    EDAssertMainThread();
    EDAssert([themeName length]);
    EDAssert(_themeCache);
    EDAssert(!_themeCache[themeName]);
    
    NSString *themeDirPath = [self themeDirPath];
    NSString *filename = [self filenameForThemeName:themeName];
    
    NSString *absPath = [themeDirPath stringByAppendingPathComponent:filename];
    
    // fallback on default if not present
    if (![[NSFileManager defaultManager] fileExistsAtPath:absPath]) {
        themeName = [[EDUserDefaults instance] defaultThemeName];

        [[EDUserDefaults instance] setSelectedThemeName:themeName];
        filename = [self filenameForThemeName:themeName];
        
        absPath = [themeDirPath stringByAppendingPathComponent:filename];
    }
    
    EDTheme *theme = [self loadThemeAtPath:absPath];
    EDAssert(theme);
    
    return theme;
}


- (EDTheme *)loadThemeAtPath:(NSString *)absPath {
    NSError *err = nil;
    NSString *cssSrc = [NSString stringWithContentsOfFile:absPath encoding:NSUTF8StringEncoding error:&err];
    EDAssert([cssSrc length]);
    
    if (!cssSrc) {
        if (err) NSLog(@"%@", err);
    }
    
    NSString *themeName = [self themeNameForFilename:[absPath lastPathComponent]];
    EDAssert([themeName length]);

    NSDictionary *attrs = [self attributesFromCSSSource:cssSrc];
    EDAssert([attrs count]);
    
    EDTheme *theme = [EDTheme themeWithName:themeName attributes:attrs];
    EDAssert(theme);
    
    return theme;
}


- (void)loadAllThemes {
    EDAssertMainThread();
    EDAssert(_themeCache)
    
    NSString *themeDirPath = [self themeDirPath];
    
    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSArray *filenames = [mgr contentsOfDirectoryAtPath:themeDirPath error:&err];
    EDAssert([filenames count]);
    
    for (NSString *filename in filenames) {
        NSString *cssFilePath = [themeDirPath stringByAppendingPathComponent:filename];
        NSString *themeName = [self themeNameForFilename:filename];
        
        if (!_themeCache[themeName]) {
            EDTheme *theme = [self loadThemeAtPath:cssFilePath];
            _themeCache[themeName] = theme;
        }
    }

    EDAssert([_themeCache count]);
}


- (NSDictionary *)attributesFromCSSSource:(NSString *)cssSrc {
    NSError *err = nil;
    id result = [self.miniCSSParser parseString:cssSrc error:&err];
    EDAssert(result);
    
    if (!result) {
        if (err) NSLog(@"%@", err);
    }
    
    NSDictionary *attrs = [[self.miniCSSAssembler.attributes copy] autorelease];
    EDAssert(attrs);
    
    // Add Tab Interval
    NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paraStyle setTabStops:[NSArray array]];
    NSInteger tabWidth = [[NSUserDefaults standardUserDefaults] integerForKey:@"OKTabWidth"];
    if (tabWidth <= 0) {
        tabWidth = 4;
    }
    
    NSMutableDictionary *defaultAttrs = [attrs objectForKey:@".default"];
    NSFont *font = [defaultAttrs objectForKey:NSFontAttributeName];
    
    [paraStyle setDefaultTabInterval:round(tabWidth * [font pointSize] / 2.0)];
    
    [defaultAttrs setObject:paraStyle forKey:NSParagraphStyleAttributeName];
    
    self.miniCSSParser = nil;
    self.miniCSSAssembler = nil;

    return attrs;
}


#pragma mark -
#pragma mark OKSyntaxHighlighterAttributesProvider

- (NSMutableDictionary *)syntaxHighlighter:(OKSyntaxHighlighter *)highlighter attributesForGrammarNamed:(NSString *)grammarName {
    EDAssertMainThread();
    EDAssert(_selectedTheme);
    
    NSMutableDictionary *attrCollection = [[_selectedTheme.attributes mutableCopy] autorelease];
    EDAssert([attrCollection count]);
    
    NSString *fontFamily = [[EDUserDefaults instance] selectedFontFamily];
    CGFloat fontSize = [[EDUserDefaults instance] selectedFontSize];
    NSFont *defaultFont = [NSFont fontWithName:fontFamily size:fontSize];
    
    for (NSString *ruleKey in attrCollection) {
        NSFont *font = defaultFont;

        NSMutableDictionary *ruleAttrs = attrCollection[ruleKey];
        id fontFace = ruleAttrs[OKFontFace];
        
        if (fontFace) {
            EDAssert([fontFace length]);
            id fontDescAttrs = [NSMutableDictionary dictionaryWithObject:fontFamily forKey:NSFontFamilyAttribute];
            [fontDescAttrs setObject:fontFace forKey:NSFontFaceAttribute];
            
            NSFontDescriptor *desc = [[[NSFontDescriptor alloc] initWithFontAttributes:fontDescAttrs] autorelease];
            font = [NSFont fontWithDescriptor:desc size:fontSize];
            if (!font) font = defaultFont;
        }

        EDAssert(font);
        [ruleAttrs setObject:font forKey:NSFontAttributeName];
    }
    
    return attrCollection;
}


#pragma mark -
#pragma mark Properties

- (NSArray *)orderedThemes {
    if (!_orderedThemes) {
        [self loadAllThemes];

        NSArray *vec = [_themeCache allValues];
        
        vec = [vec sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSComparisonResult result = [[obj1 name] caseInsensitiveCompare:[obj2 name]];
            return result;
        }];
        
        self.orderedThemes = vec;
    }
    return _orderedThemes;
}


- (OKMiniCSSAssembler *)miniCSSAssembler {
    if (!_miniCSSAssembler) {
        self.miniCSSAssembler = [[[OKMiniCSSAssembler alloc] init] autorelease];
    }
    return _miniCSSAssembler;
}


- (PKParser *)miniCSSParser {
    if (!_miniCSSParser) {
        self.miniCSSParser = [[[OKMiniCSSParser alloc] initWithDelegate:self.miniCSSAssembler] autorelease];
        
    }
    return _miniCSSParser;
}

@end
