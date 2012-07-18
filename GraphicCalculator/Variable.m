//
//  Variable.m
//  Calculator
//
//  Created by Donald Heering on 7/9/12.
//  Copyright (c) 2012 Bombadilla.com. All rights reserved.
//

#import "Variable.h"

// This class is a subclass of NSObject. It's only purpose is to be able to use
// introspection in CalculatorBrain to see if an item on the program is of class Variable

@implementation Variable

@synthesize variableName = _variableName;

- (id) init
{
    if (self = [super init])
        return self;
    return nil;
}

+ (Variable *)variableWithName:(NSString *)variable
{
    Variable *variableObject = [[Variable alloc] init];
    variableObject.variableName = variable;
    
    return variableObject;
}

@end
