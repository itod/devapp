//
//  EDApplication.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/13/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDApplication.h"
#import "OAPreferenceController.h"
#import "EDThemePreferences.h"
#import <TDAppKit/TDUtils.h>

#define PURCHASE_MENU_TAG 847
#define REGISTER_MENU_TAG 947

@interface NSObject (FUPurchaseAdditions)
- (BOOL)isLicensed;
- (IBAction)showLicenseInfo:(id)sender;
@end

@interface EDApplication ()
@property (atomic, retain, readwrite) NSMutableArray *strokeWeightStack;
@end

@implementation EDApplication

- (id)init {
    self = [super init];
    if (self) {
        self.strokeWeightStack = [NSMutableArray arrayWithObjects:@1.0, nil];
    }
    return self;
}


- (void)dealloc {
    self.canvasGraphicsContext = nil;
    [super dealloc];
}


- (BOOL)setUpAppSupportDir {
    BOOL result = [super setUpAppSupportDir];
    return result;
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
