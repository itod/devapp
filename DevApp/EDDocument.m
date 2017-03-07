//
//  EDDocument.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDDocument.h"
#import "EDMainWindowController.h"
#import "EDTabModel.h"
#import "EDTarget.h"
#import "EDUtils.h"
#import <TabKit/TKTabModel.h>
#import <OkudaKit/OKViewController.h>
#import <OkudaKit/OKTextView.h>
#import <Language/XPBreakpointCollection.h>

@interface NSDocument ()
- (BOOL)_shouldShowAutosaveButtonForWindow:(NSWindow *)win;
@end

@interface EDDocument ()
@property (nonatomic, retain) NSMutableArray *tempTabModels;
@property (nonatomic, assign) NSUInteger tempSelectedTabIndex;
@end

@interface EDMainWindowController ()
- (void)didSetBreakpoints;
@end

@implementation EDDocument

- (id)init {
    self = [super init];
    if (self) {
        _breakpoints = [[XPBreakpointCollection alloc] init];
        _breakpointsEnabled = NO;
        
        EDTarget *target = [[[EDTarget alloc] init] autorelease];
        target.name = @"Default"; // TODO
        _targets = [[NSArray alloc] initWithObjects:target, nil];
        _selectedTargetName = [target.name copy];
        
        [self updateChangeCount:NSChangeCleared];
        
        [self registerForNotifications];
    }
    return self;
}


- (void)dealloc {
    self.breakpoints = nil;
    self.targets = nil;
    self.selectedTargetName = nil;
    
    self.tempTabModels = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSResponder 

//- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//    //NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, self, [self displayName]);
//    [super encodeRestorableStateWithCoder:coder];
//    
////    [coder encodeObject:_printInfoData forKey:@"printInfoData"];
//}
//
//
//- (void)restoreStateWithCoder:(NSCoder *)coder {
//    //NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, self, [self displayName]);
//    [super restoreStateWithCoder:coder];
//    
////    self.printInfoData = [coder decodeObjectForKey:@"printInfoData"];
//}


#pragma mark -
#pragma mark NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    BOOL result = YES;
    
    SEL action = [menuItem action];
    // NSLog(@"%@", NSStringFromSelector(action)); NSLog(@"%@", [menuItem target]);
    if (@selector(duplicateDocument:) == action  ||
        @selector(saveDocumentAs:) == action ||
        @selector(renameDocument:) == action ||
        @selector(moveDocument:) == action ||
        @selector(moveDocumentToUbiquityContainer:) == action ||
        @selector(revertDocumentToSaved:) == action)
    {
        [menuItem setHidden:YES];
        result = NO;
    }

    return result;
}


#pragma mark -
#pragma mark EDDocument

- (BOOL)wantsCustomDisplayName {
    return YES;
}


#pragma mark -
#pragma mark NSDocument

#ifndef APPSTORE
- (BOOL)_shouldShowAutosaveButtonForWindow:(NSWindow *)win {
    return NO;
}
#endif


- (NSString *)displayName {
    NSString *str = nil;
    if ([self wantsCustomDisplayName]) {
        NSString *docTitle = [[[[self fileURL] relativeString] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *tabTitle = self.mainWindowController.selectedTabModel.title;
        
        if ([tabTitle length]) {
            str = [NSString stringWithFormat:@"%@ — %@", docTitle, tabTitle];
        } else {
            str = docTitle;
        }
    } else {
        str = [super displayName];
    }
    
    //NSLog(@"%@", str);
    return str;
}


- (void)makeWindowControllers {
    EDMainWindowController *wc = [[[EDMainWindowController alloc] init] autorelease];
    [self addWindowController:wc];
}


- (void)windowControllerDidLoadNib:(NSWindowController *)wc {
    [super windowControllerDidLoadNib:wc];
    
    EDAssert(self.mainWindowController);
    EDAssert(wc == self.mainWindowController);
    
    if ([_tempTabModels count]) {
        EDMainWindowController *mwc = self.mainWindowController;

        for (TKTabModel *tm in _tempTabModels) {
            NSError *err = nil;
            NSString *URLString = [mwc absolutePathForTabModel:tm];
            id obj = [[mwc newRepresentedObjectWithContentsOfURLString:URLString type:tm.type error:&err] autorelease];
            tm.representedObject = obj;
            EDAssert(tm.representedObject);
            [mwc addTabModel:tm];
        }
        
        mwc.selectedTabIndex = _tempSelectedTabIndex;
        self.tempTabModels = nil;
    }
}


- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOp completionHandler:(void (^)(NSError *))completion {
    [super saveToURL:url ofType:typeName forSaveOperation:saveOp completionHandler:completion];
    
    [[self mainWindowController] saveSelectedTabModel];
}


- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outErr {
    
    // must do a dance here to preserve .svn directories in the .schwartzproj package dir. :(
    // this sucks.
    NSFileWrapper *wrap = nil;
    
    NSURL *fileURL = [self fileURL];
    if (fileURL) {
        NSError *err = nil;
        wrap = [[[NSFileWrapper alloc] initWithURL:fileURL options:NSFileWrapperReadingImmediate error:&err] autorelease];
        if (!wrap) {
            NSLog(@"%@", err);
        }
    }
    
    if (!wrap) {
        wrap = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}] autorelease];
    }

    NSDictionary *wrapTab = [wrap fileWrappers];
    
    // remove old proj plist
    NSFileWrapper *projPlistWrap = [wrapTab objectForKey:PROJ_PLIST_NAME];
    [wrap removeFileWrapper:projPlistWrap];
    
    // add new proj plist
    NSData *projPlistData = [self projPlistDataOfType:typeName error:outErr]; // type name ???
    [wrap addRegularFileWithContents:projPlistData preferredFilename:PROJ_PLIST_NAME];

    // add source dir
    NSFileWrapper *srcDirWrap = [wrapTab objectForKey:SRC_DIR_NAME];
    if (!srcDirWrap) {
        // load main.js
        NSString *mainFilePath = [[NSBundle mainBundle] pathForResource:MAIN_FILE_BASE ofType:MAIN_FILE_EXT];
        TDAssert([mainFilePath length]);
        NSData *mainFileData = [NSData dataWithContentsOfFile:mainFilePath options:0 error:nil];
        TDAssert(mainFileData);
        
        // create src dir
        srcDirWrap = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}] autorelease];
        srcDirWrap.preferredFilename = SRC_DIR_NAME;
        
        // add main.js
        [srcDirWrap addRegularFileWithContents:mainFileData preferredFilename:MAIN_FILE_NAME];
        
        // add src dir
        [wrap addFileWrapper:srcDirWrap];
    }

    return wrap;
}


- (BOOL)readFromFileWrapper:(NSFileWrapper *)wrap ofType:(NSString *)typeName error:(NSError **)outErr {
    NSDictionary *wrapTab = [wrap fileWrappers];
    
    NSFileWrapper *projPlistWrap = [wrapTab objectForKey:PROJ_PLIST_NAME];
    EDAssert(projPlistWrap);
    
    NSData *projPlistData = [projPlistWrap regularFileContents];
    
    BOOL result = [self readProjPlistFromData:projPlistData ofType:typeName error:outErr];
    return result;
}


- (NSData *)projPlistDataOfType:(NSString *)typeName error:(NSError **)outErr {
    NSParameterAssert([typeName isEqualToString:DEFAULT_DOC_TYPE_NAME]);
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:15];
    [self storeProjPlistOfType:typeName inDict:dict error:outErr];
    
    //    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    NSData *data = EDDataFromPlist(dict, outErr); //[NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListMutableContainers error:outErr];
    EDAssert([data length]);
    
    return data;
}


- (BOOL)readProjPlistFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outErr {
    NSParameterAssert([typeName isEqualToString:DEFAULT_DOC_TYPE_NAME]);
    
    NSDictionary *dict = EDPlistFromData(data, outErr); //[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:nil error:outErr];
    EDAssert([dict isKindOfClass:[NSDictionary class]]);
    EDAssert([dict count]);
    
    BOOL result = [self readProjPlistOfType:typeName inDict:dict error:outErr];
    [self updateChangeCount:NSChangeCleared];
    return result;
}


- (void)storeProjPlistOfType:(NSString *)typeName inDict:(NSMutableDictionary *)dict error:(NSError **)outErr {
    dict[@"version"] = @(2);

    EDAssert(_breakpoints);
    dict[@"breakpoints"] = [_breakpoints asPlist];
    dict[@"breakpointsEnabled"] = @(_breakpointsEnabled);
    
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:[_targets count]];
    for (EDTarget *t in _targets) {
        [targets addObject:[t asPlist]];
    }
    dict[@"targets"] = targets;
    
    if (_selectedTargetName) dict[@"selectedTargetName"] = _selectedTargetName;
    
    NSMutableArray *tms = [NSMutableArray array];
    for (EDTabModel *tm in self.mainWindowController.tabModels) {
        [tms addObject:[tm asPlist]];
    }
    if (tms) dict[@"tabs"] = tms;
    dict[@"selectedTabIndex"] = @(self.mainWindowController.selectedTabIndex);
}


- (BOOL)readProjPlistOfType:(NSString *)typeName inDict:(NSMutableDictionary *)dict error:(NSError **)outErr {
    //EDAssert(1 == [dict[@"version"] integerValue]);
    
    XPBreakpointCollection *bps = [XPBreakpointCollection fromPlist:dict[@"breakpoints"]];
    EDAssert(bps);
    [_breakpoints release];
    _breakpoints = [bps retain];

    _breakpointsEnabled = [dict[@"breakpointsEnabled"] boolValue];
        
    [_targets release];
    NSMutableArray *targets = [NSMutableArray array];
    for (NSDictionary *d in dict[@"targets"]) {
        EDTarget *t = [EDTarget fromPlist:d];
        [targets addObject:t];
    }
    _targets = [targets copy];
    
    [_selectedTargetName release];
    _selectedTargetName = [dict[@"selectedTargetName"] copy];
    
    NSArray *tempTabModels = dict[@"tabs"];
    
    [_tempTabModels release];
    _tempTabModels = [[NSMutableArray alloc] initWithCapacity:[tempTabModels count]];
    for (NSDictionary *d in tempTabModels) {
        EDTabModel *tm = [EDTabModel fromPlist:d];
        [_tempTabModels addObject:tm];
    }
    
    _tempSelectedTabIndex = [dict[@"selectedTabIndex"] integerValue];
    
    return YES;
}


- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outErr {
    NSData *data = [NSData dataWithContentsOfURL:absoluteURL options:NSDataReadingUncached error:outErr];
    if (data) {
        return [self readFromData:data ofType:typeName error:outErr];
    } else {
        if (outErr) NSLog(@"%@", *outErr);
        return NO;
    }
}


#pragma mark -
#pragma mark Printing

- (IBAction)printDocument:(id)sender {
    NSBeep();
    
}


- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)settings error:(NSError **)outErr {
    return nil;
}


#pragma mark -
#pragma mark Private

- (void)registerForNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(breakpointsDidChange:) name:EDBreakpointsDidChangeNotification object:self];
}


#pragma mark -
#pragma mark Notifications

- (void)breakpointsDidChange:(NSNotification *)n {
    EDAssert([n object] == self);
    
    [self updateChangeCount:NSChangeDone];
}


#pragma mark -
#pragma mark Properties

- (EDMainWindowController *)mainWindowController {
    EDAssertMainThread();
    
    EDMainWindowController *wc = nil;
    if ([[self windowControllers] count]) {
        wc = [self windowControllers][0];
    }
    return wc;
}


- (void)setBreakpoints:(XPBreakpointCollection *)breakpoints {
    EDAssertMainThread();
    
    if (breakpoints != _breakpoints) {
        [self willChangeValueForKey:@"breakpoints"];
        
        id oldbps = nil;
        if (_breakpoints) {
            oldbps = [XPBreakpointCollection fromPlist:[_breakpoints asPlist]]; // copy
        }
        [[[self undoManager] prepareWithInvocationTarget:self] setBreakpoints:oldbps];
        //[[self undoManager] setActionName:NSLocalizedString(@"Set Context Size", @"")];

        [_breakpoints release];
        _breakpoints = [breakpoints retain];
        
        [self updateChangeCount:NSChangeDone];
        
        [self.mainWindowController didSetBreakpoints];
        
        [self didChangeValueForKey:@"breakpoints"];
    }
}


- (void)setBreakpointsEnabled:(BOOL)yn {
    EDAssertMainThread();
    
    if (yn != _breakpointsEnabled) {
        [self willChangeValueForKey:@"breakpointsEnabled"];
        
        _breakpointsEnabled = yn;
        
        [self updateChangeCount:NSChangeDone];
                
        [self didChangeValueForKey:@"breakpointsEnabled"];
    }
}


- (EDTarget *)selectedTarget {
    EDAssertMainThread();
    EDAssert([_targets count]);
    EDAssert([_selectedTargetName length]);
    
    EDTarget *result = nil;
    for (EDTarget *target in _targets) {
        if ([target.name isEqualToString:_selectedTargetName]) {
            result = target;
            break;
        }
    }
    
    EDAssert(result);
    return result;
}


- (void)setSelectedTargetName:(NSString *)name {
    EDAssertMainThread();
    
    if (name != _selectedTargetName) {
        [self willChangeValueForKey:@"selectedTargetName"];
        
        [_selectedTargetName release];
        _selectedTargetName = [name copy];
        
        [self updateChangeCount:NSChangeDone];
        
        [self didChangeValueForKey:@"selectedTargetName"];
    }
}

@end
