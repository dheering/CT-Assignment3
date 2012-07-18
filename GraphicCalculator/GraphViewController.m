//
//  GraphViewController.m
//  GraphicCalculator
//
//  Created by Donald Heering on 7/14/12.
//  Copyright (c) 2012 Bombadilla.com. All rights reserved.
//

#import "GraphViewController.h"
#import "GraphView.h"
#import "CalculatorBrain.h"

@interface GraphViewController () <GraphViewDataSource>
@property (nonatomic, strong) IBOutlet GraphView *graphView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *splitViewBarButtonItem;
@end

@implementation GraphViewController
@synthesize dotsOrLines             = _dotsOrLines;
@synthesize graphView               = _graphView;
@synthesize programToGraph          = _programToGraph;
@synthesize splitViewBarButtonItem  = _splitViewBarButtonItem;
@synthesize toolbar                 = _toolbar;

#pragma mark - 
#pragma mark Viewcontroller lifecylcle stuff

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.graphView.delegate = self;
    self.splitViewController.delegate = self;
    [self.dotsOrLines addTarget:self
                         action:@selector(switchDotsOrLines:)
               forControlEvents:UIControlEventValueChanged];
    
    self.dotsOrLines.selectedSegmentIndex = (self.graphView.useLines) ? 1 : 0;
}

- (void)viewDidUnload
{
    self.graphView = nil;
    self.graphView.delegate = nil;
    [self setDotsOrLines:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark -
#pragma mark Custom getters and setters

- (void)setProgramToGraph:(id)programToGraph
{
    if (_programToGraph == programToGraph)
        return; // Bail out if there is no change.
    else
        _programToGraph = programToGraph;
    
    // If we're on iPad, set NeedsDisplay on the graphView after setting the program
    if (self.splitViewController)
        [self.graphView setNeedsDisplay];
}

- (void)setGraphView:(GraphView *)graphView
{
    _graphView = graphView;
    
    // Add the pinch gesture recognizer
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:graphView action:@selector(pinch:)];
    [graphView addGestureRecognizer:pinchRecognizer];
    
    // Add the pan gesture recognizer
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:graphView action:@selector(pan:)];
    [graphView addGestureRecognizer:panRecognizer];
    
    // Add the triple-tap recognizer
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:graphView action:@selector(tap:)];
    tapRecognizer.numberOfTapsRequired = 3;
    tapRecognizer.numberOfTouchesRequired = 1;
    [graphView addGestureRecognizer:tapRecognizer];
}

#pragma mark -
#pragma mark GraphViewDataSource protocol stuff

- (CGFloat)yValueForX:(CGFloat)x
{
    id returnValue = [CalculatorBrain runProgram:self.programToGraph 
                                  usingVariables:[NSDictionary dictionaryWithObjectsAndKeys: 
                                                  [NSNumber numberWithDouble:(double)x],
                                                  @"x", 
                                                  nil]];
    
    if ([returnValue isKindOfClass:[NSNumber class]])
        return (CGFloat)[returnValue doubleValue];
    else 
        return (CGFloat)0.0;
}

- (NSString *)descriptionOfProgram
{
    return [CalculatorBrain descriptionOfProgram:self.programToGraph];
}
#pragma mark -
#pragma mark UISplitviewController delegate methods

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    // Should the splitviewcontroller hide the master view controller in this particular orientation?
    
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    // This gets called whenever the master view controller is about to be hidden.
    barButtonItem.title = self.title;
    self.splitViewBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // This gets called whenever the master view controller is about to be shown.
    self.splitViewBarButtonItem = nil;
}

#pragma mark -
#pragma mark SplitViewBarButtonForMasterViewChanger delegate method

- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
    if (splitViewBarButtonItem != _splitViewBarButtonItem)
    {
        NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
        
        if (_splitViewBarButtonItem)
            [toolbarItems removeObject:_splitViewBarButtonItem];
        if (splitViewBarButtonItem)
            [toolbarItems insertObject:splitViewBarButtonItem atIndex:0];
        self.toolbar.items = toolbarItems;
        _splitViewBarButtonItem = splitViewBarButtonItem;
    }
}

#pragma mark -
#pragma mark Miscellaneous methods

- (void)switchDotsOrLines:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0)
        // Dots
        self.graphView.useLines = NO;
    if (sender.selectedSegmentIndex == 1)
        // Lines
        self.graphView.useLines = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (self.splitViewController == nil)
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    else
        return YES;
}

@end
