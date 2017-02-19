//
//  EDFilesystemViewController.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewController.h>

@class EDFilesystemViewController;
@class EDFilesystemItem;

@protocol EDFilesystemViewControllerDelegate <NSObject>
- (NSString *)projectFilePathForFilesystemViewController:(EDFilesystemViewController *)fsc;
- (void)filesystemViewController:(EDFilesystemViewController *)fsc wantsNewFileInDirPath:(NSString *)dirPath;
- (void)filesystemViewController:(EDFilesystemViewController *)fsc didActivateItemAtPath:(NSString *)path;
- (void)filesystemViewController:(EDFilesystemViewController *)fsc didDeleteItemAtPath:(NSString *)oldPath andActivateItemAtPath:(NSString *)newPath;
- (void)filesystemViewController:(EDFilesystemViewController *)fsc willCopyItemFromPath:(NSString *)oldPath toPath:(NSString *)newPath;
- (void)filesystemViewController:(EDFilesystemViewController *)fsc didCopyItemFromPath:(NSString *)oldPath toPath:(NSString *)newPath;
- (void)filesystemViewController:(EDFilesystemViewController *)fsc willMoveItemFromPath:(NSString *)oldPath toPath:(NSString *)newPath;
- (void)filesystemViewController:(EDFilesystemViewController *)fsc didMoveItemFromPath:(NSString *)oldPath toPath:(NSString *)newPath;
- (BOOL)filesystemViewController:(EDFilesystemViewController *)fsc isItemDirtyAtPath:(NSString *)path;
@end

@interface EDFilesystemViewController : TDViewController <NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate>

- (id)init; // use me

- (void)changeDir:(NSString *)dirPath;
- (void)selectItemAtPath:(NSString *)fullPath;
- (void)reloadItemAtPath:(NSString *)fullPath;
- (void)reloadData;

- (IBAction)menuNavigate:(id)sender;
- (IBAction)menuNewFile:(id)sender;
- (IBAction)menuNewFolder:(id)sender;
- (IBAction)menuOpen:(id)sender;
- (IBAction)menuOpenWith:(id)sender;
- (IBAction)menuRename:(id)sender;
- (IBAction)menuDelete:(id)sender;
- (IBAction)menuRevealInFinder:(id)sender;

- (void)displayContextMenu:(NSEvent *)evt;

@property (nonatomic, retain) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, retain) IBOutlet NSMenu *actionPopUpButtonMenu;
@property (nonatomic, retain) IBOutlet NSPopUpButton *navPopUpButton;
@property (nonatomic, retain) IBOutlet NSMenu *navPopUpButtonMenu;

@property (nonatomic, assign) id <EDFilesystemViewControllerDelegate>delegate; // weakref
@property (nonatomic, retain) EDFilesystemItem *projItem;
@property (nonatomic, retain) EDFilesystemItem *sourceDirItem;
@property (nonatomic, retain) EDFilesystemItem *pwdItem;
@end
