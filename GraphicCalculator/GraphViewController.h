//
//  GraphViewController.h
//  GraphicCalculator
//
//  Created by Donald Heering on 7/14/12.
//  Copyright (c) 2012 Bombadilla.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplitViewBarButtonForMasterViewChanger.h"
#import "GraphView.h"

@interface GraphViewController : UIViewController <UISplitViewControllerDelegate>
@property (nonatomic, strong) id programToGraph;
@property (nonatomic, weak) IBOutlet UISegmentedControl *dotsOrLines;
- (CGFloat)yValueForX:(CGFloat)x;
@end
