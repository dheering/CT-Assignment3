//
//  CalculatorBrain.m
//  Calculator
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University.
//  All rights reserved.
//

#import "CalculatorBrain.h"
#import "Variable.h"

/*
** Private properties and methods
*/

@interface CalculatorBrain()
@property (nonatomic, strong) NSMutableArray *programStack;
+ (BOOL) isTwoOperandOperation:(NSString *)op;
+ (BOOL) isOneOperandOperation:(NSString *)op;
+ (BOOL) isNoOperandOperation:(NSString *)op;
+ (NSUInteger) operationPriority:(NSString *)op;
@end

/*
** Implementation
*/

@implementation CalculatorBrain

@synthesize programStack = _programStack;

#pragma mark -
#pragma mark Custom getters and setters

- (NSMutableArray *)programStack
{
    if (_programStack == nil) 
		_programStack = [[NSMutableArray alloc] init];
    return _programStack;
}

/*
** Getter for program that returns immutable copy of the program
*/
- (id)program
{
    return [self.programStack copy];
}

#pragma mark -
#pragma mark Public API methods

- (void)pushOperand:(double)operand
{
    [self.programStack addObject:[NSNumber numberWithDouble:operand]];
}

- (void)pushVariable:(NSString *)var
{
    // Instead of using NSString for a variable, use subclass of NSString
    // called Variable. Easy to use introspection later on...
    Variable *variableObject = [Variable variableWithName:var];
    
    [self.programStack addObject:variableObject];
}

- (void)pushOperation:(NSString *)operation
{
	[self.programStack addObject:operation];
}

- (void)removeLastItemFromProgram
{
	if (self.programStack)
		[self.programStack removeLastObject];
}

- (void) clearAll
{
    self.programStack = nil;
}

#pragma mark -
#pragma mark Methods to describe the program

/*
** Methods descriptionOfTopOfStack and descriptionOfProgram
**
** descriptionOfProgram makes mutable copy of program, then calls decriptionOfTopOfStack
** which recurses through the program
*/
+ (NSString *)descriptionOfTopOfStack:(NSMutableArray *)stack withNextOperation:(NSString *)nextOperation
{
    NSString *description;
    
    id topOfStack = [stack lastObject];
    if (topOfStack) [stack removeLastObject];
    
    if ([topOfStack isKindOfClass:[NSNumber class]])
    {
		// item pulled from the program stack is a number
        description = [NSString stringWithFormat:@"%g", [topOfStack doubleValue]];
    }
    else if ([topOfStack isKindOfClass:[Variable class]])
    {
		// item pulled from the program stack is a variable
        Variable *var = topOfStack;
        description = [NSString stringWithString:var.variableName];
    }
    else if ([topOfStack isKindOfClass:[NSString class]])
    {
		// item pulled from the program stack is an operation.
        NSString *operation = topOfStack;
        
        if ([[self class] isTwoOperandOperation:operation]) 
        {
			// operation needs two operands
            NSString *op2 = [self descriptionOfTopOfStack:stack withNextOperation:operation];
            NSString *op1 = [self descriptionOfTopOfStack:stack withNextOperation:operation];
			
            // Algorithm to determine whether to enclose in parentheses ():
			// if op1 & op2 both are nil -> just return operation
			// else if op1 == nil but not op2 -> just return "op2, operation"
			// else if nextOperation has higher priority than operation -> we DO need ()
            // else no () needed
			if (op2 == nil && op1 == nil)
			{
				description = [NSString stringWithFormat:@"%@", operation];
			}
			else if (op1 == nil)
			{
				description = [NSString stringWithFormat:@"%@, %@", op2, operation];
			}
			else if (nextOperation != nil &&
                     ([[self class] operationPriority:nextOperation] > 
                     [[self class] operationPriority:operation]))
			{
				description = [NSString stringWithFormat:@"(%@ %@ %@)", op1, operation, op2];
			}
			else
			{
				description = [NSString stringWithFormat:@"%@ %@ %@", op1, operation, op2];
			}
        } 
        else if ([[self class] isOneOperandOperation:operation])
        {
            NSString *op = [self descriptionOfTopOfStack:stack withNextOperation:operation];
            if (op == nil)
            {
                description = [NSString stringWithFormat:@"%@()", operation];
            }
            else 
            {
				description = [NSString stringWithFormat:@"%@(%@)",
							   operation,
							   op];
            }
        }
        else if ([[self class] isNoOperandOperation:operation])
        {
			// Operation does not need any operand (think: pi, +/-)
            description = [NSString stringWithFormat:@"%@", operation];
        }
    }
	
    return description;
}

+ (NSString *)descriptionOfProgram:(id)program
{
    NSString *description;
    NSMutableArray *stack;
    
    if ([program isKindOfClass:[NSArray class]]) {
        stack = [program mutableCopy];
    }
    
    description = [self descriptionOfTopOfStack:stack withNextOperation:nil];
	// If the stack is not empty, this means there are more items on it so we should recurse some more.
	while ([stack count] > 0)
	{
        NSString *temp = [NSString stringWithString:description];
		description = [NSString stringWithFormat:@"%@, %@", 
                       temp, 
                       [self descriptionOfTopOfStack:stack withNextOperation:nil]];
	}    
    return description;
}

#pragma mark -
#pragma mark Methods to calculate result of program

/*
** Methods popOperandOffProgramStack and runProgram
**
** runProgram stack makes mutable copy of program, then calls popOperandOffProgramStack which recurses through the program
*/
+ (id)popOperandOffProgramStack:(NSMutableArray *)stack
{
    double result = 0;

    id topOfStack = [stack lastObject];
    if (topOfStack) [stack removeLastObject];
    
    if ([topOfStack isKindOfClass:[NSNumber class]])
    {
        result = [topOfStack doubleValue];
    }
    else if ([topOfStack isKindOfClass:[NSString class]])
    {
        NSString *operation = topOfStack;
		
		// Check to see if there are enough operands available for the requested operation
		if ([[self class] isTwoOperandOperation:operation] && [stack count] < 2)
			return @"Not enough operands!";
			
        if ([operation isEqualToString:@"+"]) 
        {
            result = [[self popOperandOffProgramStack:stack] doubleValue] +
                     [[self popOperandOffProgramStack:stack] doubleValue];
        } 
        else if ([@"*" isEqualToString:operation]) 
        {
            result = [[self popOperandOffProgramStack:stack] doubleValue]*
                     [[self popOperandOffProgramStack:stack] doubleValue];
        } 
        else if ([operation isEqualToString:@"-"]) 
        {
            double subtrahend = [[self popOperandOffProgramStack:stack] doubleValue];
            result = [[self popOperandOffProgramStack:stack] doubleValue] - subtrahend;
        } 
        else if ([operation isEqualToString:@"/"]) 
        {
            double divisor = [[self popOperandOffProgramStack:stack] doubleValue];
            if (divisor) 
				result = [[self popOperandOffProgramStack:stack] doubleValue] / divisor;
			else
				return @"Division by zero!";
        }
        else if ([operation isEqualToString:@"π"])
        {
            result = M_PI;
        }
        else if ([operation isEqualToString:@"sin"])
        {
            result = sin([[self popOperandOffProgramStack:stack] doubleValue]);
        }
        else if ([operation isEqualToString:@"cos"])
        {
            result = cos([[self popOperandOffProgramStack:stack] doubleValue]);
        }
        else if ([operation isEqualToString:@"sqrt"])
        {
            double value = [[self popOperandOffProgramStack:stack] doubleValue];
            if (value >= 0)
                result = sqrt(value);
            else
                return @"Square root of negative number!";
        }
        else if ([operation isEqualToString:@"+/-"])
        {
            double value = [[self popOperandOffProgramStack:stack] doubleValue];
            result = -value;
        }
    }

    return [NSNumber numberWithFloat:result];
}

+ (id)runProgram:(id)program usingVariables:(NSDictionary *)variableValues
{
	// Create mutable copy of the program and call it stack.
	// Replace all variables in the stack by the corresponding value from variableValues
	//     or by 0 if variable is not found
    NSMutableArray *stack;
	
	// If program is not an NSArray we can bail out right away...
    if ([program isKindOfClass:[NSArray class]]) 
    {
        stack = [program mutableCopy];
		
		// Iterate through the stack (program) and fill in variables
        for (NSUInteger i = 0; i < [stack count]; i++)
        {
            if ([[stack objectAtIndex:i] isKindOfClass:[Variable class]])
            {
                Variable *var = [stack objectAtIndex:i];
                NSNumber *num = [variableValues objectForKey:var.variableName];
                
                if (num != nil)
					// Variable supplied in variableValues NSDictionary, so replace variable with corresponding value
                    [stack replaceObjectAtIndex:i withObject:num];
                else 
					// Variable is not supplied in variableValues, so just set it to 0.
                    [stack replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:0.0]];
            }
        }
		// Now start recursion by calling popOperandOffProgramStack
        return [self popOperandOffProgramStack:stack];
    }
	
	// We only get here if program is not an NSArray
    return [NSNumber numberWithFloat:0.0];;
}

/*
** Return an NSSet that contains the variables used in the specified programs. Filter out duplicate variables.
*/
+ (NSSet *)variablesUsedInProgram:(id)program
{
    NSMutableSet *setOfVariables = [[NSMutableSet alloc] initWithCapacity:3];
    
    for (id item in program) 
    {
        if ([item isKindOfClass:[Variable class]]) 
        {
            Variable *var = item;
            
            if (![setOfVariables containsObject:var.variableName])
                [setOfVariables addObject:var.variableName];
        }
    }
    
    if ([setOfVariables count] > 0)
        return [NSSet setWithSet:setOfVariables];
    else
        return nil;
}

#pragma mark -
#pragma mark Private convencience methods for determining number of operands needed for specific operation
                           
+ (BOOL) isTwoOperandOperation:(NSString *)op
{
    NSSet *twoOperandOperations = [NSSet setWithObjects:@"+", @"-", @"*", @"/", nil];
    
    if ([twoOperandOperations containsObject:op])
        return YES;
    return NO;
}

+ (BOOL) isOneOperandOperation:(NSString *)op
{
    NSSet *oneOperandOperations = [NSSet setWithObjects:@"cos", @"sin", @"sqrt", @"+/-", nil];
    
    if ([oneOperandOperations containsObject:op])
        return YES;
    return NO;
}

+ (BOOL) isNoOperandOperation:(NSString *)op
{
    NSSet *noOperandOperations = [NSSet setWithObjects:@"π", nil];
    
    if ([noOperandOperations containsObject:op])
        return YES;
    return NO;    
}

+ (NSUInteger) operationPriority:(NSString *)op
{
    NSUInteger priority;
    
    if ([op isEqualToString:@"*"] || [op isEqualToString:@"/"])
        priority = 3;
    if ([op isEqualToString:@"+"] || [op isEqualToString:@"-"])
        priority = 2;
    if ([op isEqualToString:@"sqrt"])
        priority =  1;
    return priority;
}

@end
