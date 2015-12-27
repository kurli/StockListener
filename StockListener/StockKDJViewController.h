//
//  StockKDJViewController.h
//  StockListener
//
//  Created by Guozhen Li on 12/22/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZSYPopoverListView.h"

@class StockInfo;
@interface StockKDJViewController : UIViewController <UIScrollViewDelegate,ZSYPopoverListDatasource, ZSYPopoverListDelegate>

@property (nonatomic, strong) StockInfo* stockInfo;

@end
