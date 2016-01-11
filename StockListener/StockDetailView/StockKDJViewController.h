//
//  StockKDJViewController.h
//  StockListener
//
//  Created by Guozhen Li on 12/22/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZSYPopoverListView.h"

#define LEFT_PADDING 20
#define MAX_DISPLAY_COUNT 35
#define KLINE_VIEW_HEIGHT 130
#define AVOL_EXPAND 60

@class StockInfo;
@interface StockKDJViewController : UIViewController <UIScrollViewDelegate,ZSYPopoverListDatasource, ZSYPopoverListDelegate>

@property (nonatomic, strong) StockInfo* stockInfo;

@end
