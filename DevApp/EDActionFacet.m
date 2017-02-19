//
//  EDActionFacet.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDActionFacet.h"
#import <TDAppKit/TDViewControllerView.h>
#import <TDAppKit/TDUtils.h>

@interface EDActionFacet ()

@end

@implementation EDActionFacet

+ (NSString *)name {
    return NSStringFromClass(self);
}


+ (NSString *)displayName {
    NSAssert2(0, @"%s is an abstract method and must be implemented in %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


+ (NSString *)nibName {
    return NSStringFromClass(self);
}


- (id)init {
    self = [self initWithNibName:[[self class] nibName] bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    EDAssert([name length]);
    self = [super initWithNibName:name bundle:b];
    if (self) {
        self.title = [[self class] displayName];
    }
    return self;
}


- (void)dealloc {
    self.selectedAction = nil;
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    TDViewControllerView *vcv = (TDViewControllerView *)self.view;
    vcv.color = TDHexColor(0xffffff);
}

@end
