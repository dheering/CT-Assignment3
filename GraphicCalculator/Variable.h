//
//  Variable.h
//  Calculator
//
//  Created by Donald Heering on 7/9/12.
//  Copyright (c) 2012 Bombadilla.com. All rights reserved.
//

#import <Foundation/Foundation.h>

// This class is a subclass of NSObject. It's only purpose is to be able to use
// introspection in CalculatorBrain to see if an item on the program is of class Variable

@interface Variable : NSObject

@property (nonatomic, strong) NSString *variableName;

- (id)init;
+ (Variable *)variableWithName:(NSString *)variable;

@end
