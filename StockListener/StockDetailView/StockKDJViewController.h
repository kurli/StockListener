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

#define ONE_MINUTE 1
#define FIVE_MINUTES 5
#define FIFTEEN_MINUTES 15
#define THIRTY_MINUTES 30
#define ONE_HOUR 60
#define ONE_DAY 240
#define ONE_WEEK 1200

@class StockInfo;
@interface StockKDJViewController : UIViewController <UIScrollViewDelegate,ZSYPopoverListDatasource, ZSYPopoverListDelegate>

@property (nonatomic, strong) StockInfo* stockInfo;

@end
