//
//  EDWelcomeWindowController.m
//  Editor
//
//  Created by Todd Ditchendorf on 9/27/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDWelcomeWindowController.h"
#import "EDWelcomeTableCellView.h"

@interface EDWelcomeWindowController ()

@end

@implementation EDWelcomeWindowController

- (id)init {
    self = [self initWithWindowNibName:@"EDWelcomeWindowController"];
    return self;
}


- (id)initWithWindowNibName:(NSString *)name {
    self = [super initWithWindowNibName:name];
    if (self) {
        self.wantsExampleProjButton = YES;
    }
    return self;
}


- (void)dealloc {
    self.tableView = nil;
    self.titleText = nil;
    self.versionText = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    EDAssert(_tableView);
    [self updateTitleText];
    [self udpateVersionText];
    
    [_tableView setDoubleAction:@selector(doubleClick:)];
}


#pragma mark -
#pragma mark NSWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

//    EDAssert([self window]);
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
}


- (IBAction)showWindow:(id)sender {
    EDAssertMainThread();
    [super showWindow:sender];
    self.busy = NO;
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    EDAssert([n object] == [self window]);
    EDAssert(_tableView);
    [_tableView reloadData];
}


#pragma mark -
#pragma mark Private

- (void)updateTitleText {
    NSString *appName = [[NSProcessInfo processInfo] processName];

    NSString *fmt = NSLocalizedString(@"Welcome to %@", @"");
    self.titleText = [NSString stringWithFormat:fmt, appName];
}


- (void)udpateVersionText {
    NSString *versNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *buildNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    NSString *fmt = NSLocalizedString(@"Version %@ (%@)", @"");
    self.versionText = [NSString stringWithFormat:fmt, versNum, buildNum];
}


#pragma mark -
#pragma mark Actions

- (IBAction)newProject:(id)sender {
    [[NSDocumentController sharedDocumentController] newDocument:sender];
    [self close];
}


- (IBAction)openSampleProject:(id)sender {
    //[[EDDocumentController instance] openSampleProject:sender];
    [self close];
}


#pragma mark -
#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv {
    NSArray *recents = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    NSUInteger c = [recents count];
    return c;
}


- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)row {
    NSArray *recents = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    NSString *path = [recents[row] relativePath];
    return path;
}

#pragma mark -
#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)tv didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    NSArray *recents = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    
    NSString *path = [recents[row] relativePath];
    NSString *name = [[path lastPathComponent] stringByDeletingPathExtension];
    
    path = [[path stringByAbbreviatingWithTildeInPath] stringByDeletingLastPathComponent];
    
    NSImage *img = [NSImage imageNamed:DOC_ICON_NAME];
    
    EDWelcomeTableCellView *cell = [rowView viewAtColumn:0];
    [cell.textField setStringValue:name];
    [cell.pathLabel setStringValue:path];
    [cell.imageView setImage:img];
}


- (BOOL)tableView:(NSTableView *)tv shouldSelectRow:(NSInteger)row {
    return YES;
}


- (IBAction)doubleClick:(id)sender {
    EDAssertMainThread();
    EDAssert(_tableView);

    if (_busy) return;
    
    self.busy = YES;

    NSInteger row = [_tableView clickedRow];
    
    [_tableView deselectAll:nil];
    [self close];
    
    NSArray *recents = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    
    NSString *path = [recents[row] relativePath];
    
    NSURL *furl = [NSURL fileURLWithPath:path];
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:furl display:YES completionHandler:^(NSDocument *doc, BOOL documentWasAlreadyOpen, NSError *err) {
       if (err) NSLog(@"%@", err);
        self.busy = NO;
    }];
}

@end
