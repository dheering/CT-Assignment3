//
//  GraphView.h
//  GraphicCalculator
//
//  Created by Donald Heering on 7/15/12.
//  Copyright (c) 2012 Bombadilla.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GraphViewDataSource <NSObject>
- (CGFloat)yValueForX:(CGFloat)x;
- (NSString *)descriptionOfProgram;
@end

@interface GraphView : UIView
@property (nonatomic, strong) id <GraphViewDataSource> delegate;
@property (nonatomic) BOOL useLines;
@end
