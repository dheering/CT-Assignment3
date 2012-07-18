//
//  CalculatorBrain.h
//  Calculator
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University.
//  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CalculatorBrain : NSObject

@property (nonatomic, readonly) id program;

- (void)pushOperand:(double)operand;
- (void)pushVariable:(NSString *)var;
- (void)pushOperation:(NSString *)operation;
- (void)removeLastItemFromProgram;
- (void)clearAll;

+ (NSString *)descriptionOfProgram:(id)program;
+ (id)runProgram:(id)program usingVariables:(NSDictionary *)variableValues;
+ (NSSet *)variablesUsedInProgram:(id)program;

@end
