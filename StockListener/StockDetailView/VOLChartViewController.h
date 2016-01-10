//
//  BuySellChartViewController.h
//  StockListener
//
//  Created by Guozhen Li on 12/14/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StockInfo;

@interface VOLChartViewController : NSObject

@property (nonatomic, strong) NSMutableArray* volValues;

-(id) initWithParentView:(UIView*)view;
- (void) reload;
-(void)loadView:(CGRect) rect;
@end
