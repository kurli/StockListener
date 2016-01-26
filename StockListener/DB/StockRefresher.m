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
#import "ConfigHelper.h"

@interface StockRefresher()

@property (nonatomic,strong) NSTimer *stockRefreshTimer;
@property (nonatomic,strong) DatabaseHelper *dbHelper;

@end

@implementation StockRefresher

-(void) startRefresh:(DatabaseHelper*) dbhelper {
    if ([ConfigHelper getInstance].stockRefreshInterval == 0) {
        [self stopRefreshStock];
        return;
    }
    if (_stockRefreshTimer == nil) {
        _stockRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:[ConfigHelper getInstance].stockRefreshInterval target:self selector:@selector(stockRefreshFired) userInfo:nil repeats:YES];
    }
    self.dbHelper = dbhelper;
    [self stockRefreshFired];
}

-(void) stopRefreshStock {
    [_stockRefreshTimer invalidate];
    [self setStockRefreshTimer:nil];
}

-(BOOL) isRefreshing {
    return self.stockRefreshTimer != nil;
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
