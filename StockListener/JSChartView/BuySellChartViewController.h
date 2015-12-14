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

@interface BuySellChartViewController : NSObject

@property (nonatomic, strong) StockInfo* stockInfo;

-(id) initWithParentView:(UIView*)view;
- (void) reload;
- (void)loadView;
@end
