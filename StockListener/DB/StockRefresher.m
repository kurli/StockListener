//
//  StockRefresher.m
//  StockListener
//
//  Created by Guozhen Li on 12/9/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockRefresher.h"
#import "GetStockValueTask.h"
#import "KingdaWorker.h"
#import "DatabaseHelper.h"
#import "StockInfo.h"

#define REFRESH_RATE 6
//#define REFRESH_RATE 1

@interface StockRefresher()

@property (nonatomic,strong) NSTimer *stockRefreshTimer;
@property (nonatomic,strong) DatabaseHelper *dbHelper;

@end

@implementation StockRefresher

-(void) startRefresh:(DatabaseHelper*) dbhelper {
    if (_stockRefreshTimer == nil) {
        _stockRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_RATE target:self selector:@selector(stockRefreshFired) userInfo:nil repeats:YES];
    }
    self.dbHelper = dbhelper;
    [self stockRefreshFired];
}

-(void) stopRefreshStock {
    [_stockRefreshTimer invalidate];
    [self setStockRefreshTimer:nil];
}

- (void)stockRefreshFired {
//    if ([self.dbHelper.stockList count] == 0) {
//        return;
//    }
    GetStockValueTask* task = [[GetStockValueTask alloc] initWithStocks:self.dbHelper.stockList];
    task.delegate = self;
    [[KingdaWorker getInstance] queue: task];
}

-(void)onStockValuesRefreshed {
    NSNotification * notice = [NSNotification notificationWithName:STOCK_VALUE_REFRESHED_NOTIFICATION object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter]postNotification:notice];
}
@end
