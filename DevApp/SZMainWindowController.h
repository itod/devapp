//
//  SZMainWindowController.h
//  Editor
//
//  Created by Todd Ditchendorf on 11/2/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDMainWindowController.h"

@interface SZMainWindowController : EDMainWindowController

- (IBAction)toggleGridEnabled:(id)sender;
- (IBAction)changeGridTolerance:(id)sender;

- (IBAction)changeZoomScale:(id)sender;
- (IBAction)zoomCanvasToActualSize:(id)sender;
- (IBAction)zoomCanvasIn:(id)sender;
- (IBAction)zoomCanvasOut:(id)sender;
- (CGSize)canvasSize;
- (IBAction)print:(id)sender;
- (IBAction)export:(id)sender;
- (void)exportTypeDidChange;

@property (nonatomic, retain) NSSavePanel *savePanel;
@property (nonatomic, retain) IBOutlet NSView *exportAccessoryView;
@property (nonatomic, retain) IBOutlet NSTabView *exportTabView;

@property (nonatomic, assign) BOOL exporting;
@property (nonatomic, assign) BOOL printing;
@end
