//
//  EDShellViewController.m
//  Editor
//
//  Created by Todd Ditchendorf on 12/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDShellViewController.h"
#import "EDThemeManager.h"
#import "EDHistory.h"
#import "EDMainWindowController.h"
#import <TDAppKit/TDViewControllerView.h>
#import <TDAppKit/TDUtils.h>
#import <OkudaKit/OKTextView.h>
#import "NSString+OKAdditions.h"

@interface OKTextView ()
- (void)textDidChange:(NSNotification *)n;
- (id)peekTrigger;
- (void)clearTriggerStack;
@end

@interface EDShellViewController ()
@property (nonatomic, assign, getter=isAtPrompt) BOOL atPrompt;
@end

@implementation EDShellViewController

- (id)init {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    self = [super initWithNibName:name bundle:b];
    if (self) {
        self.history = [[[EDHistory alloc] init] autorelease];
        [_history insert:@""]; // insert dummy to allow going back to first real item
        
        [self clearHistoryIndex];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(selectedThemeDidChange:) name:EDSelectedThemeDidChangeNotification object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    EDAssert(_sourceViewController.delegate == self);
    _sourceViewController.delegate = nil;
    self.sourceViewController = nil;

    self.textView = nil;
    self.history = nil;
    
    [super dealloc];
}


- (void)viewDidLoad {
    TDViewControllerView *v = (id)[self view];
    
    self.sourceViewController = [[[OKViewController alloc] initWithDefaultNib] autorelease];
    _sourceViewController.delegate = self;
    
    [_sourceViewController loadView];
    
    _sourceViewController.hasGutterView = NO;

    [v addSubview:_sourceViewController.view];
    [v setNeedsLayout];

    self.textView = _sourceViewController.textView;
}


- (void)viewDidMoveToWindow {
    NSWindow *win = [self.view window];
    if (!win) return;
    
    EDMainWindowController *wc = [win windowController];
    EDAssert(wc);
    
    EDAssert(_sourceViewController);
    // only do this once
    if (!_sourceViewController.textView.listDataSource) {
        _sourceViewController.textView.listDataSource = wc;
        _sourceViewController.textView.listDelegate = wc;
        
        [_sourceViewController setGrammarName:MAIN_FILE_EXT attributeProvider:[EDThemeManager instance]];
        
        [_sourceViewController.textView setAllowsUndo:YES];
    }
}


#pragma mark -
#pragma mark Notifications

- (void)selectedThemeDidChange:(NSNotification *)n {
    EDAssertMainThread();
    
    EDAssert(self.sourceViewController);
    [self.sourceViewController setGrammarName:MAIN_FILE_EXT attributeProvider:[EDThemeManager instance]];
}


#pragma mark -
#pragma mark Actions

- (IBAction)clear:(id)sender {
    EDAssertMainThread();
    EDAssert(_textView);
    [_textView setString:@""];
    [self appendPrompt];
}


#pragma mark -
#pragma mark Public

- (void)appendPrompt {
    TDAssertMainThread();
    if (!_atPrompt) {
        [self append:[NSString stringWithFormat:@"%@ ", self.prompts[0]]];
        self.atPrompt = YES;
    }
}


- (void)removePrompt {
    TDAssertMainThread();
    // if last line starts with a prompt. delete entire line.
    NSRange lastLineRange;
    NSString *lastLine = [_textView getLineRange:&lastLineRange inRange:[_textView selectedRange]];
    NSRange promptRangeInLastLine = [self rangeOfPromptInLine:lastLine];
    if (0 == promptRangeInLastLine.location) {
        EDAssert(promptRangeInLastLine.length);
        [[_textView textStorage] replaceCharactersInRange:lastLineRange withString:@""];
        self.atPrompt = NO;
    }
}


- (void)clearPrompt {
    TDAssertMainThread();
    NSRange lastLineRange;
    NSString *lastLine = [_textView getLineRange:&lastLineRange inRange:[_textView selectedRange]];
    NSRange promptRangeInLastLine = [self rangeOfPromptInLine:lastLine];
    if (0 == promptRangeInLastLine.location) {
        self.atPrompt = NO;
        EDAssert(promptRangeInLastLine.length);
        NSUInteger loc = lastLineRange.location;// + NSMaxRange(promptRangeInLastLine);
        NSUInteger len = NSMaxRange(lastLineRange) - loc;
        NSRange delRange = NSMakeRange(loc, len);
        
        EDAssert(NSNotFound != delRange.location);
        EDAssert(NSNotFound != delRange.length);
        EDAssert(0 != delRange.length);
        EDAssert(NSMaxRange(delRange) <= [[_textView textStorage] length]);
        
        [[_textView textStorage] replaceCharactersInRange:delRange withString:@""];
    }
}



- (void)append:(NSString *)msg {
    TDAssertMainThread();
    self.atPrompt = NO;
    
    // trim multiple newlines at start of msg
    while ([msg length] > 3) {
        if ('\r' == [msg characterAtIndex:0] && '\n' == [msg characterAtIndex:1] && '\r' == [msg characterAtIndex:2] && '\n' == [msg characterAtIndex:3]) {
            msg = [msg substringFromIndex:2];
        } else {
            break;
        }
    }
    
    // trim starting newline of msg if the console already ends in a newline
    if ([msg length] > 0 && ('\r' == [msg characterAtIndex:0] || '\n' == [msg characterAtIndex:0])) {
        NSString *str = [_textView string];
        NSUInteger strLen = [str length];
        if (strLen) {
            unichar lastChar = [str characterAtIndex:strLen-1];
            if ('\n' == lastChar) {
                msg = [msg stringByTrimmingLeadingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            }
        }
    }
    
    TDAssert(_sourceViewController);
    NSDictionary *attrs = [_sourceViewController defaultAttributes];
    NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString:msg attributes:attrs] autorelease];
    TDAssert(_textView);
    [[_textView textStorage] appendAttributedString:attrStr];

    [[_textView undoManager] removeAllActionsWithTarget:_textView]; // clear undo stack after every auto-appended message
    
    [_sourceViewController refresh:nil];

    TDPerformOnMainThreadAfterDelay(0.0, ^{
        NSRange r = NSMakeRange([[_textView string] length], 0);
        [_textView scrollRangeToVisibleIfHidden:r];
        //[_textView textDidChange:nil]; // this can trigger the autocomplete list window, which is annoying when browsing shell history
    });
}


- (void)appendFormat:(NSString *)fmt, ... {
    va_list vargs;
    va_start(vargs, fmt);
    
    NSString *msg = [[[NSString alloc] initWithFormat:fmt arguments:vargs] autorelease];
    
    va_end(vargs);
    
    [self append:msg];
}


- (void)appendNewLine {
    [self append:@"\n"];
}


- (void)handleUserCommand:(NSString *)cmd {
    EDAssert(_history);
    EDAssert(cmd);
    if ([cmd length]) {
        NSString *current = [_history current];
        if (![cmd isEqualToString:current]) {
            [_history insert:cmd];
        }
    }
    
    // just double-check that the autocomplete list window is dismissed. I've seen this left behind before.
    [_sourceViewController.textView removeListWindow];
    
    [self appendNewLine];
}


- (NSArray *)prompts {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


- (NSRange)rangeOfPromptInLine:(NSString *)line {
    NSRange r = NSMakeRange(NSNotFound, 0);
    
    if ([line length]) {
        for (NSString *prompt in self.prompts) {
            r = [line rangeOfString:[NSString stringWithFormat:@"%@ ", prompt]];
            if (r.length) break;
        }
    }
    
    return r;
}


#pragma mark -
#pragma mark Private

- (BOOL)isOnPromptLine:(NSString **)outCmd {
    BOOL result = NO;
    
    NSString *str = [_textView string];
    NSUInteger strLen = [str length];
    if (strLen) {
        NSRange selRange = [_textView selectedRange];
        
        if (NSNotFound != selRange.location) {
            
            NSRange lastLineRange = [str lineRangeForRange:NSMakeRange(strLen, 0)];
            EDAssert(NSNotFound != lastLineRange.location);
            EDAssert(NSMaxRange(lastLineRange) <= strLen);
            //NSLog(@"`%@`", [str substringWithRange:lastLineRange]);
            
            if (selRange.location > lastLineRange.location) {
                EDAssert(NSNotFound != selRange.location);
                EDAssert(NSMaxRange(selRange) <= strLen);
                
                NSRange selLineRange = [str lineRangeForRange:selRange];
                NSString *line = [[str substringWithRange:selLineRange] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                
                NSRange relPromptRange = [self rangeOfPromptInLine:line];
                if (relPromptRange.length) {
                    result = YES;
                    if (outCmd) *outCmd = [line substringFromIndex:NSMaxRange(relPromptRange)];
                }
            }
        }
    }
    
    return result;
}


//- (BOOL)isOnNewLine {
//    BOOL result = NO;
//    
//    NSString *str = [_textView string];
//    NSUInteger strLen = [str length];
//    if (strLen) {
//        NSRange selRange = [_textView selectedRange];
//        
//        if (NSNotFound != selRange.location) {
//            
//            NSRange lastLineRange = [str lineRangeForRange:NSMakeRange(strLen, 0)];
//            EDAssert(NSNotFound != lastLineRange.location);
//            EDAssert(NSMaxRange(lastLineRange) <= strLen);
//            //NSLog(@"`%@`", [str substringWithRange:lastLineRange]);
//            
//            if (selRange.location > lastLineRange.location) {
//                EDAssert(NSNotFound != selRange.location);
//                EDAssert(NSMaxRange(selRange) <= strLen);
//                
//                NSRange selLineRange = [str lineRangeForRange:selRange];
//                NSString *line = [[str substringWithRange:selLineRange] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//
//                result = 0 == [line length];
//            }
//        }
//    }
//    
//    return result;
//}


- (NSString *)goBackInHistory {
    NSString *cmd = nil;
    
    if ([_history canGoBack]) {
        cmd = [_history current];
        [_history goBackBy:1];
    }
    
    return cmd;
}


- (NSString *)goForwardInHistory {
    NSString *cmd = @"";
    
    // don't display first real entry twice on bounce.
    if (![_history canGoBack]) {
        [_history goForwardBy:1];
    }
    
    if ([_history canGoForward]) {
        cmd = [_history goForwardBy:1];
    }
    
    EDAssert(cmd);
    return cmd;
}


- (void)clearHistoryIndex {
    [_history fastForward];
}


#pragma mark -
#pragma mark OKViewControllerDelegate

- (BOOL)isMoveLeftSelector:(SEL)sel {
    return

    //@selector(deleteBackward:) == sel ||
    
    @selector(moveLeft:) == sel ||
    @selector(moveLeftAndModifySelection:) == sel ||
    
    @selector(moveWordLeft:) == sel ||
    @selector(moveWordLeftAndModifySelection:) == sel ||
    
    [self isMoveLeftToBeginningSelector:sel] || [self isMoveLeftToBeginningAndModifySelector:sel];
}


- (BOOL)isMoveLeftToBeginningSelector:(SEL)sel {
    return
    
    @selector(moveToLeftEndOfLine:) == sel ||
    @selector(moveToBeginningOfLine:) == sel ||
    @selector(moveToBeginningOfParagraph:) == sel ||
    @selector(moveToBeginningOfDocument:) == sel;
}


- (BOOL)isMoveLeftToBeginningAndModifySelector:(SEL)sel {
    return
    
    @selector(moveToLeftEndOfLineAndModifySelection:) == sel ||
    @selector(moveToBeginningOfLineAndModifySelection:) == sel ||
    @selector(moveToBeginningOfParagraphAndModifySelection:) == sel ||
    @selector(moveToBeginningOfDocumentAndModifySelection:) == sel;
}


- (BOOL)okviewController:(OKViewController *)okvc doCommandBySelector:(SEL)sel {
    EDAssert(_sourceViewController == okvc);
    
    BOOL handled = NO;
    
    if (@selector(insertNewline:) == sel ||
        
        [self isMoveLeftSelector:sel] ||
        
        @selector(moveRight:) == sel ||
        @selector(moveUp:) == sel ||
        @selector(moveDown:) == sel)
    {
        handled = [self textView:_textView doCommandBySelector:sel];
    }
    
    return handled;
}


- (BOOL)okviewController:(OKViewController *)okvc shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
    BOOL result = [self isOnPromptLine:nil];
    return result;
}


#pragma mark -
#pragma mark NSTextViewDelegate

- (BOOL)textView:(OKTextView *)tv doCommandBySelector:(SEL)sel {
    
    BOOL suppressDefault = NO;
    
    NSString *cmd = nil;
    if ([self isMoveLeftSelector:sel]) {
        if ([self isAtPrompt]) {
            NSRange selRange = [tv selectedRange];
            if (selRange.length) {
                if ([self isMoveLeftToBeginningAndModifySelector:sel] || @selector(moveWordLeftAndModifySelection:) == sel || @selector(moveLeftAndModifySelection:) == sel) {
                    suppressDefault = YES;
                    NSBeep();
                } else if (@selector(deleteBackward:) == sel) {
                    suppressDefault = NO;
                } else {
                    suppressDefault = YES;
                    NSRange newSelRange = NSMakeRange(selRange.location, 0);
                    EDAssert(NSNotFound != newSelRange.location);
                    EDAssert(NSMaxRange(newSelRange) <= [[tv string] length]);
                    [tv setSelectedRange:newSelRange];
                }
            } else {
                suppressDefault = YES;
                NSBeep();
            }
        } else if ([self isOnPromptLine:nil]) {
            BOOL moveLeft = [self isMoveLeftToBeginningSelector:sel];
            BOOL moveLeftAndModify = [self isMoveLeftToBeginningAndModifySelector:sel];
            if (moveLeft || moveLeftAndModify) {
                NSString *str = [tv string];
                NSUInteger strLen = [str length];
                EDAssert(strLen);
                if (strLen) {
                    suppressDefault = YES;
                    NSRange lastLineRange = [str lineRangeForRange:NSMakeRange(strLen, 0)];
                    NSUInteger locInLine = [self.prompts[0] length] + 1;
                    NSUInteger len = moveLeftAndModify ? lastLineRange.length - locInLine : 0;
                    NSRange newSelRange = NSMakeRange(lastLineRange.location + locInLine, len);
                    EDAssert(NSNotFound != newSelRange.location);
                    EDAssert(NSMaxRange(newSelRange) <= strLen);
                    [tv setSelectedRange:newSelRange];
                }
            }
        }
    } else if (@selector(insertNewline:) == sel) {
        // let tv handle triggers before hijacking
        if ([tv peekTrigger]) {
            [tv clearTriggerStack];
        }
        if ([self isOnPromptLine:&cmd]) {
            [self clearHistoryIndex];
            [self handleUserCommand:cmd];
            // move to end of line JIC
            [tv setSelectedRange:NSMakeRange([[tv string] length], 0)];
        }
        suppressDefault = YES;
    } else if (@selector(moveUp:) == sel) {
        if ([self isOnPromptLine:nil]) {
            NSString *cmd = [self goBackInHistory];
            if (cmd) {
                [self clearPrompt];
                [self appendPrompt];
                [self append:cmd];
            } else {
                NSBeep();
            }
            suppressDefault = YES;
        }
    } else if (@selector(moveRight:) == sel) {
        // if arrowing down to last line, helpfully move the cursor to prompt
        NSRange selRange = [tv selectedRange];
        EDAssert(NSNotFound != selRange.location);
        if (NSNotFound != selRange.location) {
            NSString *str = [tv string];
            NSUInteger strLen = [str length];
            EDAssert(str);
            if (strLen) {
                NSRange oldLineRange = [str lineRangeForRange:selRange];
                EDAssert(NSNotFound != oldLineRange.location);
                if (NSNotFound != oldLineRange.location) {
                    BOOL isMovingToLastLine = NSMaxRange(selRange) + 1 == NSMaxRange(oldLineRange) - 1;
                    if (isMovingToLastLine) {
                        suppressDefault = YES;
                        NSRange newSelRange = NSMakeRange(strLen, 0);
                        
                        EDAssert(NSNotFound != newSelRange.location);
                        EDAssert(NSMaxRange(newSelRange) <= strLen);
                        
                        [tv setSelectedRange:newSelRange];
                        [tv scrollRangeToVisibleIfHidden:newSelRange];
                    }
                }
            }
        }
    } else if (@selector(moveDown:) == sel) {
        NSString *currentCmd = nil;
        if ([self isOnPromptLine:&currentCmd]) {
            NSString *cmd = [self goForwardInHistory];
            if (cmd) {
                [self clearPrompt];
                [self appendPrompt];
                [self append:cmd];
            }
            if (![currentCmd length]) {
                NSBeep();
            }
            suppressDefault = YES;
        } else {
            // if arrowing down to last line, helpfully move the cursor to prompt
            NSRange selRange = [tv selectedRange];
            EDAssert(NSNotFound != selRange.location);
            if (NSNotFound != selRange.location) {
                NSString *str = [tv string];
                NSUInteger strLen = [str length];
                EDAssert(str);
                if (strLen) {
                    NSRange oldLineRange = [str lineRangeForRange:selRange];
                    EDAssert(NSNotFound != oldLineRange.location);
                    if (NSNotFound != oldLineRange.location) {
                        NSRange followingLineRange = [str lineRangeForRange:NSMakeRange(NSMaxRange(oldLineRange), 0)];
                        BOOL isMovingToLastLine = NSMaxRange(followingLineRange) == strLen;
                        if (isMovingToLastLine) {
                            suppressDefault = YES;
                            NSRange newSelRange = NSMakeRange(strLen, 0);
                            
                            EDAssert(NSNotFound != newSelRange.location);
                            EDAssert(NSMaxRange(newSelRange) <= strLen);
                            
                            [tv setSelectedRange:newSelRange];
                            [tv scrollRangeToVisibleIfHidden:newSelRange];
                        }
                    }
                }
            }
        }
    }
    
    return suppressDefault;
}

@end
