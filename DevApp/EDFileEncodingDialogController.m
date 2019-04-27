//
//  EDFileEncodingDialogController.m
//  Editor
//
//  Created by Todd Ditchendorf on 1/3/14.
//  Copyright (c) 2014 Todd Ditchendorf. All rights reserved.
//

#import "EDFileEncodingDialogController.h"
#import <TDAppKit/TDUtils.h>

//#define NUM_ENCODINGS 
//
//static NSUInteger sDisplayedEncodings[] = {
//    NSUTF8StringEncoding,
//    NSASCIIStringEncoding,
//    NSISOLatin1StringEncoding,
//    NSMacOSRomanStringEncoding,
//    NSUTF16BigEndianStringEncoding,
//    NSUTF16LittleEndianStringEncoding,
//    NSUTF32BigEndianStringEncoding,
//    NSUTF32LittleEndianStringEncoding,
//};

@interface EDFileEncodingDialogController ()

@end

@implementation EDFileEncodingDialogController

- (id)init {
    self = [self initWithWindowNibName:@"EDFileEncodingDialogController"];
    return self;
}


- (id)initWithWindowNibName:(NSString *)name {
    self = [super initWithWindowNibName:name];
    if (self) {
        self.displayedEncodings = @[
                                    @(NSUTF8StringEncoding),
                                    @(NSASCIIStringEncoding),
                                    @(NSISOLatin1StringEncoding),
                                    @(NSMacOSRomanStringEncoding),
                                    @(NSUTF16StringEncoding),
                                    @(NSUTF16BigEndianStringEncoding),
                                    @(NSUTF16LittleEndianStringEncoding),
                                    @(NSUTF32StringEncoding),
                                    @(NSUTF32BigEndianStringEncoding),
                                    @(NSUTF32LittleEndianStringEncoding),
                                    ];
        
        self.displayedEncodingNamesTab = @{
                                           @(NSUTF8StringEncoding): @"UTF-8",
                                           @(NSASCIIStringEncoding): @"ASCII",
                                           @(NSISOLatin1StringEncoding): @"ISO 8859-1 (Latin 1)",
                                           @(NSMacOSRomanStringEncoding): @"Mac Roman",
                                           @(NSUTF16StringEncoding): @"UTF-16",
                                           @(NSUTF16BigEndianStringEncoding): @"UTF-16BE",
                                           @(NSUTF16LittleEndianStringEncoding): @"UTF-16LE",
                                           @(NSUTF32StringEncoding): @"UTF-32",
                                           @(NSUTF32BigEndianStringEncoding): @"UTF-32BE",
                                           @(NSUTF32LittleEndianStringEncoding): @"UTF-32LE",
                                           };

        
//        id d = [NSMutableDictionary dictionaryWithCapacity:[_displayedEncodings count]];
//        for (NSNumber *encObj in _displayedEncodings) {
//            NSStringEncoding enc = [encObj unsignedIntegerValue];
//            EDAssert(NSNotFound != enc);
//            EDAssert(0 != enc);
//            
//            NSString *name = [TDTextEncodingNameFromNSStringEncoding(enc) uppercaseString];
//            EDAssert([name length]);
//            
//            d[encObj] = name;
//        }
//        self.displayedEncodingNamesTab = [[d copy] autorelease];
        
//        const CFStringEncoding *cfencs = CFStringGetListOfAvailableEncodings(); // terminated with 'invalid'
//        
//        id v = [NSMutableArray array];
//        id tab = [NSMutableDictionary dictionary];
//        
//        CFStringEncoding cfenc;
//        while ((cfenc = *cfencs++) != kCFStringEncodingInvalidId) {
//            NSStringEncoding nsenc = CFStringConvertEncodingToNSStringEncoding(cfenc);
//            
//            NSString *name = [(id)CFStringConvertEncodingToIANACharSetName(cfenc) capitalizedString];
//            if ([name length]) {
//                [v addObject:@(nsenc)];
//                tab[@(nsenc)] = name;
//            }
//        }
//        self.displayedEncodings = [[v copy] autorelease];
//        self.displayedEncodingNamesTab = [[tab copy] autorelease];
    }
    return self;
}


- (void)dealloc {
    EDAssert(_tableView);
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
    
    self.tableView = nil;
    self.delegate = nil;
    self.filePath = nil;
    self.displayedEncodings = nil;
    self.displayedEncodingNamesTab = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    EDAssertMainThread();
    EDAssert(_tableView);
    EDAssert(_tableView.dataSource == self);
    EDAssert(_tableView.delegate == self);
    
    self.selectedIndex = 0;
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}


#pragma mark -
#pragma mark Actions

- (IBAction)ok:(id)sender {
    EDAssertMainThread()
    EDAssert(_selectedIndex < [_displayedEncodings count]);
    EDAssert(_delegate);
    
    EDAssert([_displayedEncodings count]);
    EDAssert(_selectedIndex < [_displayedEncodings count]);
    
    NSStringEncoding enc = [_displayedEncodings[_selectedIndex] unsignedIntegerValue];
    EDAssert(NSNotFound != enc);
    EDAssert(0 != enc);
    
    NSLog(@"selected: %@", _displayedEncodingNamesTab[_displayedEncodings[_selectedIndex]]);

    [_delegate fileEncodingDialogController:self didSelectStringEncoding:enc];
}


- (IBAction)cancel:(id)sender {
    EDAssertMainThread()
    EDAssert(_delegate);

    [_delegate fileEncodingDialogControllerDidCancel:self];
}


#pragma mark -
#pragma mark NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tv shouldSelectRow:(NSInteger)row {
    EDAssertMainThread();
    EDAssert(row < [_displayedEncodings count]);
    self.selectedIndex = row;
    return YES;
}


- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:(NSTableColumn *)col row:(NSInteger)row {
    return NO;
}


#pragma mark -
#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv {
    EDAssertMainThread();
    
    NSUInteger c = [_displayedEncodings count];
    EDAssert(NSNotFound != c);
    EDAssert(c > 0);
    
    return c;
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)row {
    EDAssertMainThread();
    EDAssert([_displayedEncodings count]);
    EDAssert([_displayedEncodingNamesTab count]);
    EDAssert(row < [_displayedEncodings count]);

    id encObj = _displayedEncodings[row];
    NSString *name = _displayedEncodingNamesTab[encObj];
    EDAssert([name length]);
    
    return name;
}

@end
