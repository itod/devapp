//
//  EDFileEncodingDialogController.h
//  Editor
//
//  Created by Todd Ditchendorf on 1/3/14.
//  Copyright (c) 2014 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EDFileEncodingDialogController;

@protocol EDFileEncodingDialogControllerDelegate <NSObject>
- (void)fileEncodingDialogControllerDidCancel:(EDFileEncodingDialogController *)fedc;
- (void)fileEncodingDialogController:(EDFileEncodingDialogController *)fedc didSelectStringEncoding:(NSStringEncoding)enc;
@end

@interface EDFileEncodingDialogController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

@property (nonatomic, retain) IBOutlet NSTableView *tableView;

@property (nonatomic, assign) id <EDFileEncodingDialogControllerDelegate>delegate;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) NSUInteger selectedIndex;

@property (nonatomic, retain) NSArray *displayedEncodings;
@property (nonatomic, retain) NSDictionary *displayedEncodingNamesTab;
@end
