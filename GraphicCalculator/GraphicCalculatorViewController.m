//
//  GC_ViewController.m
//  GraphicCalculator
//
//  Created by Donald Heering on 7/14/12.
//  Copyright (c) 2012 Bombadilla.com. All rights reserved.
//

#import "GraphicCalculatorViewController.h"
#import "GraphViewController.h"
#import "Variable.h"
#import "CalculatorBrain.h"

@interface GraphicCalculatorViewController ()
@property (nonatomic) BOOL userIsInTheMiddleOfEnteringANumber;
@property (nonatomic, strong) CalculatorBrain *brain;
@property (nonatomic, strong) NSDictionary *testVariableValues;
- (void)updateDisplayLabels;
@end


@implementation GraphicCalculatorViewController
@synthesize display                             = _display;
@synthesize sendToBrainDisplay                  = _sendToBrainDisplay;
@synthesize variablesDisplay                    = _variablesDisplay;
@synthesize userIsInTheMiddleOfEnteringANumber  = _userIsInTheMiddleOfEnteringANumber;
@synthesize brain                               = _brain;
@synthesize testVariableValues                  = _testVariableValues;

#pragma mark -
#pragma mark Custom getters and setters

/*
 ** Lazy instantiation getter for property: brain
 */
- (CalculatorBrain *)brain
{
    if (!_brain)
        _brain = [[CalculatorBrain alloc] init];
    return _brain;
}

#pragma mark -
#pragma mark IBActions for buttons

/*
 ** IBActions for the different kind of buttons
 */
- (IBAction)digitPressed:(UIButton *)sender 
{
    NSString *digit = [sender currentTitle];
    if (self.userIsInTheMiddleOfEnteringANumber)
    {
        self.display.text = [self.display.text stringByAppendingString:digit];    
    }
    else 
    {
        self.display.text = digit;
        self.userIsInTheMiddleOfEnteringANumber = YES;
    }
}

- (IBAction)decimalDotPressed:(UIButton *)sender 
{
    if (!self.userIsInTheMiddleOfEnteringANumber)
    {
		// User is NOT in the middle of entering a number and first input is a ".".
        self.display.text = @"0.";
        self.userIsInTheMiddleOfEnteringANumber = YES;
    }
    else if ([self.display.text rangeOfString:@"."].location == NSNotFound)
    {
		// User IS in the middle of entering a number and there is not a "." in the display.
        self.display.text = [self.display.text stringByAppendingString:@"."];
    }
}

- (IBAction)enterPressed 
{
    double value = [self.display.text doubleValue];
    [self.brain pushOperand:value];
    [self updateDisplayLabels];
    self.userIsInTheMiddleOfEnteringANumber = NO;
}

- (IBAction)operationPressed:(UIButton *)sender 
{
    if (self.userIsInTheMiddleOfEnteringANumber)
        [self enterPressed];
    NSString *operation = [sender currentTitle];
    [self.brain pushOperation:operation];
    [self updateDisplayLabels];
}

- (IBAction)clearPressed 
{
    self.userIsInTheMiddleOfEnteringANumber = NO;
    [self.brain clearAll];
    [self updateDisplayLabels];
}

- (IBAction)undoPressed 
{
	/*
     ** Undo: 
     ** - If the use is entering a number, remove the last entered digit. 
     ** - If the undo removes the last remaining digit: 
     **		- show the result of the current program
     **		- set status so user is not in the middle of entering a number any more.
     ** - If the user is NOT entering a number, remove the top of the program stack.
     */
	
    if (self.userIsInTheMiddleOfEnteringANumber)
    {
        NSUInteger displayStringLength = [self.display.text length];
        if (displayStringLength > 1)
        {
            self.display.text = [self.display.text substringToIndex:displayStringLength - 1];
        }
        else
        {
            self.userIsInTheMiddleOfEnteringANumber = NO;
            [self updateDisplayLabels];
        }
    }
    else 
    {
        [self.brain removeLastItemFromProgram];
        [self updateDisplayLabels];
    }
}

- (IBAction)variablePressed:(UIButton *)sender 
{
    if (self.userIsInTheMiddleOfEnteringANumber)
        [self enterPressed];
    NSString *variable = [sender currentTitle];
    [self.brain pushVariable:variable];
    [self updateDisplayLabels];
}

- (IBAction)changeSignPressed:(UIButton *)sender
{
    if (self.userIsInTheMiddleOfEnteringANumber)
        self.display.text = [NSString stringWithFormat:@"%g", -[self.display.text doubleValue]];
    else 
        [self operationPressed:sender];
}

- (IBAction)testVariableValuesPressed:(UIButton *)sender
{
    NSString *testSetTitle = [sender currentTitle];
    if ([testSetTitle isEqualToString:@"Test 1"])
        self.testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat:25], @"x",
                                   [NSNumber numberWithFloat:0.00],  @"a",
                                   [NSNumber numberWithFloat:-1.01], @"b",
                                   nil];
    else if ([testSetTitle isEqualToString:@"Test 2"])
        self.testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat:1], @"x",
                                   [NSNumber numberWithFloat:2],  @"a",
                                   [NSNumber numberWithFloat:3], @"b",
                                   nil];
    else if ([testSetTitle isEqualToString:@"Test 0"])
        self.testVariableValues = nil;
    
    [self updateDisplayLabels];
}

#pragma mark -
#pragma mark Segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"graphView"])
    {
        [[segue destinationViewController] setProgramToGraph:self.brain.program];
    }
}

#pragma mark -
#pragma mark iPad only IBAction method for feeding stuff to the graphView

- (IBAction)updateGraphView
{
    id detailVC = [self.splitViewController.viewControllers lastObject];
    
    [detailVC setProgramToGraph:self.brain.program];
}

#pragma mark -
#pragma mark Miscellaneous methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (self.splitViewController == nil)
        return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
    else
        return YES;
}

- (void)updateDisplayLabels
{
	// Result is either an NSNumber (program valid and calculable) or an NSString (program invalid of calculation error)
    id result = [CalculatorBrain runProgram:self.brain.program usingVariables:self.testVariableValues];
	
	// Update main result display.
	if ([result isKindOfClass:[NSString class]])
		self.display.text = [NSString stringWithFormat:@"%@", result];
	else
		self.display.text = [NSString stringWithFormat:@"%g", [result doubleValue]];
    
	// Update 'brain' display with description of program
    self.sendToBrainDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    
	// Update 'variables' display
    self.variablesDisplay.text = @"";
    NSSet *variablesInProgram = [CalculatorBrain variablesUsedInProgram:self.brain.program];
    for (id item in variablesInProgram) 
    {
        self.variablesDisplay.text = [self.variablesDisplay.text stringByAppendingFormat:@" %@=%@", 
                                      item, 
                                      [self.testVariableValues objectForKey:item]];
    }
}

- (void)viewDidUnload {
    [self setSendToBrainDisplay:nil];
    [self setVariablesDisplay:nil];
    [super viewDidUnload];
}
@end

