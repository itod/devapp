//
//  EDMainWindowController+NewProject.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDMainWindowController+NewProject.h"
#import "EDProjectWindowController.h"
#import "EDDocument.h"
#import "EDTabModel.h"
#import "EDNewProjectParams.h"
#import <TDAppKit/TDUtils.h>

@interface EDMainWindowController ()
- (void)navigateToSourceDir;
- (void)syncFilesystemViewWithSelectedTab;
@end

@implementation EDMainWindowController (NewProject)

- (void)runNewProjectSheet {
    if (!self.projectWindowController) {
        self.projectWindowController = [[[EDProjectWindowController alloc] init] autorelease];
    }
    
    [NSApp beginSheet:[self.projectWindowController window]
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(newProjectSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}


- (void)newProjectSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)ctx {
    EDAssert(self.projectWindowController);
    EDAssert([self.projectWindowController window] == sheet);
    
    BOOL ok = NSOKButton == returnCode;
    
    if (ok) {
        EDNewProjectParams *params = self.projectWindowController.projParams;
        NSString *projName = params.name;
        EDAssert([projName length]);
        [self runProjectSavePanelWithName:projName];
    } else {
        [self orderOutNewProjectSheet:YES];
    }
}


- (void)orderOutNewProjectSheet:(BOOL)alsoClose {
    EDAssertMainThread();
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        EDAssert(self.projectWindowController);
        [[self.projectWindowController window] orderOut:self];
        self.projectWindowController = nil;
        if (alsoClose) {
            [self close];
        } else {
            TDPerformOnMainThreadAfterDelay(0.0, ^{
                EDAssert([self document]);
                EDAssert([[self document] fileURL]);
                EDAssert([[self window] isVisible]);
                [[self window] makeKeyAndOrderFront:nil];
                [[self window] makeFirstResponder:self.selectedSourceViewController.textView];
            });
        }
    });
}


- (void)runProjectSavePanelWithName:(NSString *)projName {
    EDAssertMainThread();
    EDAssert([projName length]);
    
    //    NSSavePanel *openPanel = [NSSavePanel savePanel];
    //    [openPanel setNameFieldStringValue:projName];
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    [openPanel setCanCreateDirectories:YES];
    [openPanel setCanSelectHiddenExtension:NO];
    [openPanel setPrompt:NSLocalizedString(@"Create", @"")];
    [openPanel setExtensionHidden:YES];
    
    EDAssert([[self.projectWindowController window] isVisible]);
    [openPanel beginSheetModalForWindow:[self.projectWindowController window] completionHandler:^(NSInteger returnCode) {
        EDAssertMainThread();
        EDAssert([[self.projectWindowController window] isVisible]);
        
        TDPerformOnMainThreadAfterDelay(0.0, ^{
            // if Canceled
            if (NSFileHandlingPanelCancelButton == returnCode) {
                [self runNewProjectSheet];
                EDAssert([[self.projectWindowController window] isKeyWindow]);
                return;
            }
            
            NSURL *dirURL = [openPanel URL];
            NSString *dirPath = [[dirURL relativePath] stringByStandardizingPath];
            EDAssert([dirPath length]);
            
            dirPath = [dirPath stringByAppendingPathComponent:projName];
            
            // if already exists
            if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
                [self runOverwriteDirSheet:dirPath];
            }
            
            // save success
            else {
                [self createProjectAtPath:dirPath];
            }
        });
    }];
}


- (void)runOverwriteDirSheet:(NSString *)dirPath {
    EDAssertMainThread();
    EDAssert([dirPath length]);
    
    NSString *projName = [dirPath lastPathComponent];
    EDAssert([projName length]);
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"“%@” already exists. Do you want to replace it?", @""), projName];
    NSString *defaultBtn = NSLocalizedString(@"Cancel", @"");
    NSString *altBtn = NSLocalizedString(@"Replace", @"");
    NSString *msgFmt = NSLocalizedString(@"A file or folder with the same name already exists in the folder %@. Replacing it will overwrite its current contents.", @"");
    
    EDAssert([[self.projectWindowController window] isVisible]);
    NSBeginCriticalAlertSheet(title, defaultBtn, altBtn, nil, [self.projectWindowController window],
                              self,
                              @selector(overwriteDirSheetDidEnd:returnCode:contextInfo:), nil,
                              [dirPath retain], // +1
                              msgFmt, projName);
}


- (void)overwriteDirSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)ctx {
    EDAssert([(id)ctx isKindOfClass:[NSString class]]);
    NSString *dirPath = [(id)ctx autorelease]; // -1
    EDAssert([dirPath length]);
    
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        
        // Cancel is default
        if (NSAlertDefaultReturn == returnCode) {
            NSString *projName = [dirPath lastPathComponent];
            EDAssert([projName length]);
            [self runProjectSavePanelWithName:projName];
        }
        
        // else save
        else {
            [self createProjectAtPath:dirPath];
        }
    });
}


- (void)createProjectAtPath:(NSString *)dirPath {
    EDAssertMainThread();
    
    if ([self saveProjectToDirectory:dirPath]) {
        //EDNewProjectParams *params = self.projectWindowController.projParams;
        [self orderOutNewProjectSheet:NO];
    }
}


- (BOOL)saveProjectToDirectory:(NSString *)dirPath {
    EDAssertMainThread();
    EDAssert([dirPath length]);
    
    NSString *projName = [dirPath lastPathComponent];
    EDAssert([projName length]);
    
    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    if ([mgr fileExistsAtPath:dirPath]) {
        
        NSURL *furl = [NSURL fileURLWithPath:dirPath];
        if (![mgr trashItemAtURL:furl resultingItemURL:nil error:&err]) {
            if (err) NSLog(@"%@", err);
            
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Could not overwrite “%@”", @""), projName];
            NSString *defaultBtn = NSLocalizedString(@"OK", @"");
            NSString *altBtn = nil; //NSLocalizedString(@"Cancel", @"");
            NSString *otherBtn = nil;
            NSString *msg = [err localizedDescription];
            
            NSRunAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
            return NO;
        }
    }
    
    EDAssert([self document]);
    NSString *srcDirName = [[self document] sourceDirName];
    EDAssert([srcDirName length]);
    NSString *srcDirPath = [dirPath stringByAppendingPathComponent:srcDirName];
    
    // create proj dir & src dir in one go.
    err = nil;
    if (![mgr createDirectoryAtPath:srcDirPath withIntermediateDirectories:YES attributes:nil error:&err]) {
        if (err) NSLog(@"%@", err);
        
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Could not create project “%@”", @""), projName];
        NSString *defaultBtn = NSLocalizedString(@"OK", @"");
        NSString *altBtn = nil; //NSLocalizedString(@"Cancel", @"");
        NSString *otherBtn = nil;
        NSString *msg = [err localizedDescription];
        
        NSRunAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
        return NO;
    }
    
    //    err = nil;
    //    NSDictionary *attrs = [mgr attributesOfItemAtPath:dirPath error:&err];
    //    NSLog(@"%@", attrs);
    
    NSString *filePath = [[dirPath stringByAppendingPathComponent:projName] stringByAppendingPathExtension:FILE_DOC_EXT];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    EDAssert(fileURL);
    
    EDAssertMainThread();
    EDDocument *doc = [self document];
    EDAssert(doc);
    EDAssert([[doc fileType] isEqualToString:FILE_DOC_TYPE]);
    
    NSString *mainSrcPath = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"js"];
    NSString *mainDestPath = [[srcDirPath stringByAppendingPathComponent:@"main"] stringByAppendingPathExtension:@"js"];
    
    err = nil;
    if (![mgr copyItemAtPath:mainSrcPath toPath:mainDestPath error:&err]) {
        if (err) NSLog(@"%@", err);
    }
    
    self.tempSourceDirPath = srcDirPath;
    
    err = nil;
    if (![self addTabWithContentsOfURLString:mainDestPath type:EDTabModelTypeSourceCodeFile error:&err]) {
        NSLog(@"%@", err);
    }
    
    self.tempSourceDirPath = nil;
    
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        EDAssert(![doc fileURL]);
        [doc moveToURL:fileURL completionHandler:^(NSError *err) {
            if (err) NSLog(@"%@", err);
            EDAssert([doc fileURL]);
            
            [self navigateToSourceDir];
        }];
    });
    
    return YES;
}

@end
