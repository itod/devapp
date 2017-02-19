//
//  EDActionArgumentsFacet.h
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDActionFacet.h"

@interface EDActionArgumentsFacet : EDActionFacet

@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain) NSMutableArray *environmentVariables;
@end
