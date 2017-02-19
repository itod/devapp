//
//  EXDocumentController.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDApplication.h"
#import "EDDocumentController.h"
#import <TDAppKit/TDUtils.h>

#ifndef APPSTORE
#import <TDAppKit/TDRegisterWindowController.h>
#import "EDWelcomeWindowController.h"
#import <Sparkle/Sparkle.h>
#import "AquaticPrime.h"

#define LICENSE_NAME_KEY @"Name"
#define LICENSE_EMAIL_KEY @"Email"

static BOOL sHasCheckedLicense = NO;
static BOOL sIsLicensed = NO;
#endif

@implementation EDDocumentController

- (void)dealloc {
#ifndef APPSTORE
    self.registerWindowController = nil;
    self.welcomeWindowController = nil;
#endif
    [super dealloc];
}


#pragma mark -
#pragma mark NSApplicationDelegate

#ifndef APPSTORE
- (void)applicationDidFinishLaunching:(NSNotification *)n {
    [super applicationDidFinishLaunching:n];
    
    [(id)[EDApplication instance] removeUnlicensedMenuItems];

    TDPerformOnMainThreadAfterDelay(0.8, ^{
        if (![[self documents] count] && [[EDUserDefaults instance] showWelcomeWindowOnLaunch]) {
            [self showWelcomeWindow:nil];
        }
    });
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)app {
    BOOL result = YES;
    
    if ([[EDUserDefaults instance] showWelcomeWindowOnLaunch]) {
        result = NO;
        [self showWelcomeWindow:nil];
    }

    return result;
}


- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename {
    NSString *ext = [filename pathExtension];
    if ([ext isEqualToString:LICENSE_EXT] || [filename hasSuffix:[LICENSE_EXT stringByAppendingPathExtension:@"xml"]] || [filename hasSuffix:[LICENSE_EXT stringByAppendingPathExtension:@"plist"]]) {
        [self registerWithLicenseAtPath:filename];
        return YES;
    } else {
        return NO;
    }
}


- (void)checkForUpdates {
    SUUpdater *updater = [SUUpdater sharedUpdater];
    if ([updater automaticallyChecksForUpdates]) {
        [updater checkForUpdatesInBackground];
    }
}


#pragma mark -
#pragma mark License

- (BOOL)isLicensed {
    @synchronized (self) {
        if (!sHasCheckedLicense) {
            sHasCheckedLicense = YES;
            NSDictionary *d = [self licenseDictionary];
            sIsLicensed = [d count] > 0; // TODO
        }
    }
    
    return sIsLicensed;
}


- (BOOL)registerWithLicenseAtPath:(NSString *)path {
    if ([self installLicenseAtPath:path]) {
        @synchronized (self) {
            sHasCheckedLicense = NO;
        }
        if (_registerWindowController) {
            [_registerWindowController close];
        }
        [(id)[EDApplication instance] removeUnlicensedMenuItems];
        [self runThankYouDialog];
        return YES;
    } else {
        [self runInvalidLicenseDialog];
        return NO;
    }
}


- (BOOL)installLicenseAtPath:(NSString *)srcPath {
    NString *licenseValidator = [NString stringWithKey:[self publicKey]];
    NSDictionary *d = [licenseValidator dictionaryForLicenseFile:srcPath];
    if (!d) {
        return NO;
    }
    
    NSString *destPath = [self licensePath];
    //BOOL result = [licenseValidator writeLicenseFileForDictionary:d toPath:destPath];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    // remove any old license
    NSError *err = nil;
    if ([mgr fileExistsAtPath:destPath]) {
        if (![mgr removeItemAtPath:destPath error:&err]) {
            if (err) {
                NSLog(@"Error removing old license file: %@", err);
            }
        }
    }
    
    // move new license to correct path
    err = nil;
    BOOL success = [mgr moveItemAtPath:srcPath toPath:destPath error:&err];
    if (!success && err) {
        NSLog(@"Error installing license file: %@", err);
    }
    
    return success;
}


- (void)runInvalidLicenseDialog {
    NSString *title = NSLocalizedString(@"Invalid License File.", @"");
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Sorry, that doesn't appear to be a valid %@ License.\n\nPlease contact support for help.\n", @""), APP_NAME];
    NSString *defaultBtn = NSLocalizedString(@"Online Support", @"");
    NSString *altBtn = NSLocalizedString(@"Cancel", @"");
    NSString *otherBtn = nil;
    NSInteger button = NSRunInformationalAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
    if (NSAlertDefaultReturn == button) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:SUPPORT_URL]];
    }
}


- (NSString *)allowances {
    NSString *allowances = [NSString stringWithFormat:NSLocalizedString(@"\n\n• Add more than %d Breakpoints at a time.\n• Enter Full Screen mode.", @""), MAX_NUM_BREAKPOINTS];
    return allowances;
}

                                
- (void)runThankYouDialog {
    NSString *allowances = [self allowances];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Thank You for Purchasing %@!", @""), APP_NAME];
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"You have successfully registered your copy of %@. Now you can:%@\nEnjoy!", @""), APP_NAME, allowances];
    NSString *defaultBtn = NSLocalizedString(@"OK", @"");
    NSString *altBtn = nil;
    NSString *otherBtn = nil;
    NSRunInformationalAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
}


- (NSString *)nagText {
    NSString *allowances = [self allowances];
    NSString *text = [NSString stringWithFormat:NSLocalizedString(@"This free trial version of %@\n does not allow you to:%@\nPurchase a full license for this functionality.\n", @""), APP_NAME, allowances];
    return text;
}


- (void)runNagDialog {
    if (![self isLicensed]) {
        NSString *title = NSLocalizedString(@"Feature Not Available in Free Trial Version", @"");
        NSString *msg = [self nagText];
        NSString *defaultBtn = NSLocalizedString(@"Purchase Online", @"");
        NSString *altBtn = NSLocalizedString(@"Cancel", @"");
        NSString *otherBtn = nil;
        NSInteger button = NSRunAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
        if (NSAlertDefaultReturn == button) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:PURCHASE_URL]];
        }
    }
}


- (NSString *)licensePath {
    NSString *dirPath = [[[EDApplication instance] appSupportDirPath] stringByExpandingTildeInPath];
    return [[dirPath stringByAppendingPathComponent:LICENSE_FILENAME] stringByAppendingPathExtension:@"plist"];
}


- (NSString *)licenseExtension {
    return LICENSE_EXT;
}


- (NSDictionary *)licenseDictionary {
    NString *licenseValidator = [NString stringWithKey:[self publicKey]];
    
    // Get the dictionary from the license file
    // If the license is invalid, we get nil back instead of a dictionary
    return [licenseValidator dictionaryForLicenseFile:[self licensePath]];
}


- (NSString *)publicKey {
	// This string is specially constructed to prevent key replacement
    // *** Begin Public Key ***
	NSMutableString *key = [NSMutableString string];
	[key appendString:@"0xAC4FD60340A318C482EFD6EC987B"];
	[key appendString:@"3CB0"];
	[key appendString:@"7"];
	[key appendString:@"7"];
	[key appendString:@"9EF0C5EED6E80D5504147B6A"];
	[key appendString:@"B182543C272"];
	[key appendString:@"C"];
	[key appendString:@"C"];
	[key appendString:@"1E5ED00FEC02C2549"];
	[key appendString:@"72D"];
	[key appendString:@"B"];
	[key appendString:@"B"];
	[key appendString:@"00B94327DF7027AD567CA278E"];
	[key appendString:@""];
	[key appendString:@"5"];
	[key appendString:@"5"];
	[key appendString:@"EED2110887DC19BBB108170413A5"];
	[key appendString:@"E151FBEF8F06C1A7038E2F36D74E01"];
	[key appendString:@"1FE2BF1D3CF328DEC"];
	[key appendString:@"B"];
	[key appendString:@"B"];
	[key appendString:@"FAF903A6AF0"];
	[key appendString:@"EF58691C6413D7129C04B3CEB14693"];
	[key appendString:@"E2BA78C3B76A0AEF9B"];
	// *** End Public Key ***
    
    return [[key copy] autorelease];
}
#endif
        
        
#pragma mark -
#pragma mark Purchase Actions
        
#ifndef APPSTORE
- (IBAction)purchase:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:PURCHASE_URL]];
}


- (IBAction)registerApp:(id)sender {
    NSString *appName = [[NSProcessInfo processInfo] processName];
    NSString *licExt = [self licenseExtension];
    self.registerWindowController = [[[TDRegisterWindowController alloc] initWithAppName:appName licenseFileExtension:licExt] autorelease];
    [_registerWindowController showWindow:sender];
}


- (IBAction)showLicenseInfo:(id)sender {
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"This copy of %@ is licensed to", @""), APP_NAME];
    //    NSString *msgFmt = NSLocalizedString(@"%@ <%@>\n\nIf that's not you, please purchase online.", @"");
    NSString *msgFmt = NSLocalizedString(@"%@\n\nIf that's not you, please purchase online.", @"");
    NSString *defaultButton = NSLocalizedString(@"OK", @"");
    NSString *altButton = NSLocalizedString(@"Purchase Online", @"");
    NSDictionary *d = [self licenseDictionary];
    NSString *name = [d objectForKey:LICENSE_NAME_KEY];
    //    NSString *email = [d objectForKey:LICENSE_EMAIL_KEY];
    //    NSInteger result = NSRunInformationalAlertPanel(title, msgFmt, defaultButton, altButton, nil, name, email);
    NSInteger result = NSRunInformationalAlertPanel(title, msgFmt, defaultButton, altButton, nil, name);
    if (NSAlertAlternateReturn == result) {
        [self purchase:nil];
    }
}


- (IBAction)showWelcomeWindow:(id)sender {
    if (!_welcomeWindowController) {
        self.welcomeWindowController = [[[EDWelcomeWindowController alloc] init] autorelease];
    }

    [_welcomeWindowController showWindow:sender];
}
#endif


- (IBAction)toggleTabsListViewVisible:(id)sender {
    [[EDUserDefaults instance] setTabsListViewVisible:![[EDUserDefaults instance] tabsListViewVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDTabsListViewVisibleDidChangeNotification object:nil];
}


- (IBAction)toggleStatusBarVisible:(id)sender {
    [[EDUserDefaults instance] setStatusBarVisible:![[EDUserDefaults instance] statusBarVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDStatusBarVisibleDidChangeNotification object:nil];
}


- (IBAction)toggleNavigatorVisible:(id)sender {
    [[EDUserDefaults instance] setNavigatorViewVisible:![[EDUserDefaults instance] navigatorViewVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDNavigatorViewVisibleDidChangeNotification object:nil];
}


- (IBAction)toggleCanvasViewVisible:(id)sender {
    [[EDUserDefaults instance] setCanvasViewVisible:![[EDUserDefaults instance] canvasViewVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDCanvasViewVisibleDidChangeNotification object:nil];
}


- (IBAction)toggleConsoleViewVisible:(id)sender {
    [[EDUserDefaults instance] setConsoleViewVisible:![[EDUserDefaults instance] consoleViewVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDConsoleViewVisibleDidChangeNotification object:nil];
}


- (IBAction)toggleDebugLocalVaraiblesVisible:(id)sender {
    [[EDUserDefaults instance] setDebugLocalVariablesVisible:![[EDUserDefaults instance] debugLocalVariablesVisible]];
    [[NSNotificationCenter defaultCenter] postNotificationName:EDDebugLocalVariablesVisibleDidChangeNotification object:nil];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    BOOL result = YES;
    NSString *title = nil;
    
    SEL action = [menuItem action];
    if (@selector(toggleTabsListViewVisible:) == action) {
        title = [[EDUserDefaults instance] tabsListViewVisible] ? NSLocalizedString(@"Hide Tab Bar", @"") : NSLocalizedString(@"Show Tab Bar", @"");
    } else if (@selector(toggleStatusBarVisible:) == action) {
        title = [[EDUserDefaults instance] statusBarVisible] ? NSLocalizedString(@"Hide Status Bar", @"") : NSLocalizedString(@"Show Status Bar", @"");
    } else if (@selector(toggleNavigatorVisible:) == action) {
        title = [[EDUserDefaults instance] navigatorViewVisible] ? NSLocalizedString(@"Hide Navigator", @"") : NSLocalizedString(@"Show Navigator", @"");
    } else if (@selector(toggleConsoleViewVisible:) == action) {
        title = [[EDUserDefaults instance] consoleViewVisible] ? NSLocalizedString(@"Hide Debug Area", @"") : NSLocalizedString(@"Show Debug Area", @"");
    } else if (@selector(toggleDebugLocalVaraiblesVisible:) == action) {
        title = [[EDUserDefaults instance] debugLocalVariablesVisible] ? NSLocalizedString(@"Hide Local Variables", @"") : NSLocalizedString(@"Show Local Variables", @"");
    }

    if (title) {
        [menuItem setTitle:title];
    }
    return result;
}

@end
