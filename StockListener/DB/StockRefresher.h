//
//  StockRefresher.h
//  StockListener
//
//  Created by Guozhen Li on 12/9/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GetStockValueTask.h"

#define STOCK_VALUE_REFRESHED_NOTIFICATION @"STOCK_VALUE_CHANGED_NOTIFICATION"

@class DatabaseHelper;
@interface StockRefresher : NSObject <GetStockValueDoneDelegate>

-(void) startRefresh:(DatabaseHelper*) helper;

-(void) stopRefreshStock;

@end
