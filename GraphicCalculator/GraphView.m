//
//  GraphView.m
//  GraphicCalculator
//
//  Created by Donald Heering on 7/15/12.
//  Copyright (c) 2012 Bombadilla.com. All rights reserved.
//

#import "GraphView.h"
#import "AxesDrawer.h"

@interface GraphView()
@property (nonatomic) CGFloat scale;
@property (nonatomic) CGPoint origin;
@end

@implementation GraphView
@synthesize delegate            = _delegate;
@synthesize scale               = _scale;
@synthesize origin              = _origin;
@synthesize useLines            = _useLines;

#pragma mark -
#pragma mark Setup of view 

- (void)setup
{
    // Setup of view, is called whenever view is loaded from nib or initWithFrame
    //
    // Steps taken:
    // 1. Try to get origin and scale from user defaults
    // 2. If we get none, set some defaults for origin and scale
    // 3. If we do get values, set origin and scale based on them
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *ud_origin_x = [userDefaults objectForKey:@"origin_x"];
    NSNumber *ud_origin_y = [userDefaults objectForKey:@"origin_y"];
    NSNumber *ud_scale    = [userDefaults objectForKey:@"scale"];
    NSString *ud_lines    = [userDefaults objectForKey:@"lines"];
    
    if (ud_origin_x)
        _origin = CGPointMake([ud_origin_x floatValue], [ud_origin_y floatValue]);
    else 
        _origin = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);

    if (ud_scale)
        _scale = [ud_scale floatValue];
    else
        _scale = 10.0;
    
    if (ud_lines)
        _useLines = [ud_lines boolValue];
    else 
        _useLines = YES;
    
    // We want to redraw or view with drawRect whenever needed.
    self.contentMode = UIViewContentModeRedraw;
}

- (void) awakeFromNib
{
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    [self setup];
    return self;
}

#pragma mark -
#pragma mark Custom setters

- (void) setScale:(CGFloat)scale
{
    if (scale == _scale)
        return;  // No change, bail out.
    
    _scale = scale;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *ud_scale = [NSNumber numberWithFloat:scale];
    [userDefaults setObject:ud_scale forKey:@"scale"];
    [self setNeedsDisplay];
}

- (void) setOrigin:(CGPoint)origin
{
    if (CGPointEqualToPoint(origin, _origin))
        return; // No change, bail out.
    
    _origin = origin;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *ud_origin_x = [NSNumber numberWithFloat:origin.x];
    NSNumber *ud_origin_y = [NSNumber numberWithFloat:origin.y];
    
    [userDefaults setObject:ud_origin_x forKey:@"origin_x"];
    [userDefaults setObject:ud_origin_y forKey:@"origin_y"];
    [self setNeedsDisplay];
}

- (void) setUseLines:(BOOL)useLines
{
    if (useLines == _useLines)
        return; // No change, bail out
    
    _useLines = useLines;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSNumber *ud_lines = [NSNumber numberWithBool:useLines];
    [userDefaults setObject:ud_lines forKey:@"lines"];    
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Gesture recognizers

- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) || (gesture.state == UIGestureRecognizerStateEnded))
    {
        self.scale *= gesture.scale;
        gesture.scale = (CGFloat)1.0;
    }
}

- (void)pan:(UIPanGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) || (gesture.state == UIGestureRecognizerStateEnded))
    {
        CGPoint translation = [gesture translationInView:self];
        self.origin = CGPointMake(self.origin.x + translation.x, self.origin.y + translation.y);
        [gesture setTranslation:CGPointZero inView:self];
    }
}

- (void)tap:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized)
    {
        self.origin = [gesture locationInView:self];
    }
}

#pragma mark -
#pragma mark Custom drawing stuff

+ (void)drawString:(NSString *)text atPoint:(CGPoint)location
{
    
	if ([text length])
	{
		UIFont *font = [UIFont systemFontOfSize:12.0];
		
		CGRect textRect;
		textRect.size = [text sizeWithFont:font];
		textRect.origin.x = location.x;
		textRect.origin.y = location.y;
				
		[text drawInRect:textRect withFont:font];
	}
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    // First, draw the axes in black.
    [[UIColor blackColor] setStroke];
    [AxesDrawer drawAxesInRect:self.bounds originAtPoint:self.origin scale:self.scale];
    
    // Now, draw the graph in red.
    [[UIColor redColor] setStroke];
    [[UIColor greenColor] setFill];
    BOOL drawing = NO;
    CGPoint previousPoint;
    
    for (int x = 0; x < self.bounds.size.width; x++)
    {
        // Algorithm is as follows:
        // 1. Based on origin and scale, calculate x-value to send to delegate in proper coordinates
        // 2. Send this x value to the delegate so it can run the program to get y value
        // 3. Based on origin and scale, calculate y value for view based on value returned by delegate
        // 4. If line based graph:
        //      - start out with drawing = NO
        //      - check if point to draw is within bounds of view
        //      - if so: make this the previousPoint and set drawing to YES
        //      - from then on, if point is within bounds, draw from previousPoint to current point
        //      - if points is out of bounds, set drawing to no
        // 5. If point based graph: just draw point if within bounds
        
        CGFloat program_x = (x - self.origin.x) / self.scale;
        CGFloat program_y = [self.delegate yValueForX:program_x];
        CGFloat y = self.origin.y - program_y * self.scale;
        
        if (self.useLines)
        {
            if (CGRectContainsPoint(self.bounds, CGPointMake(x, y)))
            {
                if (drawing)
                {
                    CGContextMoveToPoint(context, previousPoint.x, previousPoint.y);
                    CGContextAddLineToPoint(context, x, y);
                    CGContextStrokePath(context);
                    previousPoint = CGPointMake(x, y);
                }
                else
                {
                    previousPoint = CGPointMake(x, y);
                    drawing = YES;
                }
            }
            else
            {
                drawing = NO;
            }
            
        }
        else
        {
            if (CGRectContainsPoint(self.bounds, CGPointMake(x, y)))
                CGContextFillRect(context, CGRectMake(x,y,1,1));
        }
    }
    
    [[UIColor blackColor] setStroke];
    [[UIColor blackColor] setFill];
    
    [[self class] drawString:[self.delegate descriptionOfProgram] atPoint:CGPointMake(20,10)];
}



@end
