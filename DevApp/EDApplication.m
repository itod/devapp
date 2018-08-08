//
//  EDApplication.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/13/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDApplication.h"
#import "EDThemePreferences.h"
#import <TDAppKit/TDUtils.h>

#define PURCHASE_MENU_TAG 847
#define REGISTER_MENU_TAG 947

@interface NSObject (FUPurchaseAdditions)
- (BOOL)isLicensed;
- (IBAction)showLicenseInfo:(id)sender;
@end

@implementation EDApplication

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)dealloc {

    [super dealloc];
}


- (BOOL)setUpAppSupportDir {
    NSString *dirName = [[NSProcessInfo processInfo] processName];
    NSArray *pathComps = [NSArray arrayWithObjects:@"~", @"Library", @"Application Support", dirName, nil];
    NSString *path = [[NSString pathWithComponents:pathComps] stringByExpandingTildeInPath];
    self.appSupportDirPath = path;

    BOOL success = [self createDirAtPathIfDoesntExist:_appSupportDirPath];

    if (success) {
        self.startupItemsDirPath = [self.appSupportDirPath stringByAppendingPathComponent:@"Startup Items"];
        [self createDirAtPathIfDoesntExist:self.startupItemsDirPath];

        self.shutdownItemsDirPath = [self.appSupportDirPath stringByAppendingPathComponent:@"Shutdown Items"];
        [self createDirAtPathIfDoesntExist:self.shutdownItemsDirPath];

        self.scriptsDirPath = [self.appSupportDirPath stringByAppendingPathComponent:@"Menu Scripts"];
        [self createDirAtPathIfDoesntExist:self.scriptsDirPath];

        self.resourcesDirPath = [self.appSupportDirPath stringByAppendingPathComponent:@"Resources"];
        [self createDirAtPathIfDoesntExist:self.resourcesDirPath];
    }

    return success;
}


- (BOOL)createDirAtPathIfDoesntExist:(NSString *)path {
    BOOL exists, isDir;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];

    BOOL success = (exists && isDir);

    if (!success) {
        NSError *err = nil;
        success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
        if (!success) {
            NSLog(@"could not create dir at path: %@: %@", path, err);
        }
    }

    return success;
}


- (void)finishLaunching {
    [super finishLaunching];
    
    [self setUpFontManager];
}


#ifndef APPSTORE
- (void)removeUnlicensedMenuItems {
    NSMenu *appMenu = [[[self mainMenu] itemAtIndex:0] submenu];
    
    if (appMenu) {
        id del = [self delegate];
        BOOL isLicensed = [del respondsToSelector:@selector(isLicensed)] && [del isLicensed];
        if (!isLicensed) return;
        
        @try {
            NSUInteger purchaseIdx = [appMenu indexOfItemWithTag:PURCHASE_MENU_TAG];
            NSUInteger c = [appMenu numberOfItems];
            if (NSNotFound != purchaseIdx && c > 0 && purchaseIdx < c) {
                [appMenu removeItemAtIndex:purchaseIdx];
                
                NSMenuItem *licenseInfoItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"License Info", @"")
                                                                          action:@selector(showLicenseInfo:)
                                                                   keyEquivalent:@""] autorelease];
                [appMenu insertItem:licenseInfoItem atIndex:purchaseIdx];
            }
            NSUInteger registerIdx = [appMenu indexOfItemWithTag:REGISTER_MENU_TAG];
            c = [appMenu numberOfItems];
            if (NSNotFound != registerIdx && c > 0 && registerIdx < c) {
                [appMenu removeItemAtIndex:registerIdx];
            }
        }
        @catch (NSException *gulp) {
            
        }
    }
}
#endif


#pragma mark -
#pragma mark Actions

//- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender {
//    BOOL result = NO;
//    
//    if (@selector(changeFont:) == action) {
//        // WTF. why is this necessary? dunno. it is.
//        [self changeFont:sender];
//        result = YES;
//        
//    } else {
//        result = [super sendAction:action to:target from:sender];
//    }
//    return result;
//}


#pragma mark -
#pragma mark NSFontManagerDelegate

- (void)setUpFontManager {
    TDPerformOnMainThreadAfterDelay(0.3, ^{
        if ([[NSFontPanel sharedFontPanel] isVisible]) {
            [[NSFontPanel sharedFontPanel] close];
        }
        
        [[NSFontManager sharedFontManager] setDelegate:self];
        [[NSFontManager sharedFontManager] setAction:@selector(myChangeFont:)];
    });
}


- (IBAction)myChangeFont:(id)sender {
    IDEAssertMainThread();
    IDEAssert([sender isKindOfClass:[NSFontManager class]]);
    
    NSString *oldFontFamily = [[EDUserDefaults instance] selectedFontFamily];
    IDEAssert([oldFontFamily length]);
    CGFloat oldFontSize = [[EDUserDefaults instance] selectedFontSize];
    IDEAssert(oldFontSize > 0.0);
    
    NSFont *oldFont = [NSFont fontWithName:oldFontFamily size:oldFontSize];
    NSFont *newFont = [sender convertFont:oldFont];
    
    NSString *newFontFamily = [newFont familyName];
    IDEAssert([newFontFamily length]);
    CGFloat newFontSize = [newFont pointSize];
    IDEAssert(newFontSize > 0.0);
    
    [[EDUserDefaults instance] setSelectedFontFamily:newFontFamily];
    [[EDUserDefaults instance] setSelectedFontSize:newFontSize];
    
    // notify
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:EDSelectedThemeDidChangeNotification object:nil];
}

@end
