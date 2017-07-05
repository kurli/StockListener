//
//  OrgnizedViewUpdator.m
//  StockListener
//
//  Created by Guozhen Li on 6/16/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "OrgnizedViewUpdator.h"
#import "DatabaseHelper.h"
#import "OrgnizedItem.h"
#import "CalculateKDJ.h"
#import "GetTodayStockValue.h"
#import "KingdaWorker.h"
#import "StockInfo.h"
#import "GetFiveDayStockValue.h"
#import "GetDaysStockValue.h"
#import "GetWeeksStockValue.h"
#import "SyncPoint.h"
#import "StockRefresher.h"
#import "StockKDJViewController.h"
#import "KDJViewController.h"
#import "KLineViewController.h"
#import "CalculateAVOL.h"
#import "ConfigHelper.h"
#import "AVOLChartViewController.h"
#import "VOLChartViewController.h"

@interface OrgnizedViewUpdator()

@property (nonatomic, strong) NSMutableArray* stockIdList;

@end

@implementation OrgnizedViewUpdator

-(id) init {
    if (self = [super init]) {
        self.stockIdList = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onStockValueRefreshed)
                                                     name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                                   object:nil];
    }
    return self;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) onStockValueRefreshed {
    [self refreshAll];
}

-(void) refreshAVOL:(float)l andHighest:(float)h andDic:(NSDictionary*)dic andStockInfo:(StockInfo*)stockInfo andAVOL:(AVOLChartViewController*)aVolController{
    // Average VOL
    float delta = 0.01;
    if (h < 3) {
        delta = 0.001;
    }
    if (l > 1000) {
        delta = 1;
    }
    [aVolController setStockInfo:stockInfo];
    int ll = l/delta;
    int hh = h/delta;
    
    if (ll == hh) {
        [aVolController setMin:0];
        [aVolController setMax:0];
        [aVolController reload];
        return;
    }
    
    [aVolController setMin:ll];
    [aVolController setMax:hh];
    [aVolController setAverageVolDic:dic];
    [aVolController reload];
}

-(void) refreshAVOLAsync:(float)l andHighest:(float)h andPrice:(NSArray*) prices andVols:(NSArray*)vols andStockInfo:(StockInfo*)stockInfo andAVOL:(AVOLChartViewController*)avolController{
    CalculateAVOL* task = [[CalculateAVOL alloc] initWithStockInfo:stockInfo];
    if ([ConfigHelper getInstance].avolCalType == AVOL_CAL_5_DAYS) {
        task.fiveDayPrice = prices;
        task.fiveDayVOL = vols;
    }
    task.onCompleteBlock = ^(NSDictionary* dic) {
        [self refreshAVOL:l andHighest:h andDic:dic andStockInfo:stockInfo andAVOL:avolController];
    };
    [task setSourceType:CalculateAVOLTypeHistory];
    [[KingdaWorker getInstance] queue:task];
}

-(void) refreshVOL:(NSInteger) startIndex andVolValues:(NSArray*)volValues andMaxCount:(NSInteger)maxCount andVOL:(VOLChartViewController*)volController {
    //VOL
    volController.volValues = [[NSMutableArray alloc] init];
    for (NSInteger i=startIndex; i<[volValues count]; i++) {
        NSNumber* vol = [volValues objectAtIndex:i];
        [volController.volValues addObject:vol];
    }
    // Insert zero for remaining
    NSInteger count = [volController.volValues count] - maxCount;
    for (NSInteger i=0; i<count; i++) {
        [volController.volValues addObject:[NSNumber numberWithInteger:0]];
    }
    [volController reload];
}

-(void) drawMarks:(StockInfo*)stockInfo andItem:(OrgnizedItem*)item {
    // Draw mark
    float price = 0;
    float isBuy = YES;
    NSInteger dealCount = 0;
    if ([stockInfo.buySellHistory count] > 0) {
        NSString* data = [stockInfo.buySellHistory lastObject];
        NSArray* array = [data componentsSeparatedByString:@":"];
        if ([array count] == 2) {
            price = [[array objectAtIndex:0] floatValue];
            dealCount = [[array objectAtIndex:1] integerValue];
            if (price == PRE_EARN_FLAG) {
                price = 0;
            } else {
                if (dealCount > 0) {
                    isBuy = YES;
                } else {
                    isBuy = NO;
                }
            }
        }
    }
    if (price > 0) {
        if (isBuy) {
            float tax = [stockInfo getTaxForBuy:price andDealCount:dealCount];
            tax += [stockInfo getTaxForSell:stockInfo.price andDealCount:dealCount];
            price = tax/(float)dealCount + price;
            [item.klineViewController setPriceMarkColor:[UIColor redColor]];
        } else {
            [item.klineViewController setPriceMarkColor:[UIColor greenColor]];
        }
        [item.klineViewController setPriceMark:price];
        float rate = (stockInfo.price-price)/price;
        [item.klineViewController setPriceInfoStr:[NSString stringWithFormat:@"  %.2f%%", rate*100]];

    } else {
        [item.klineViewController setPriceMark:-10];
    }
}

-(void) refreshUI:(OrgnizedItem*)item andData:(CalculateKDJ*)_self andMaxCount:(NSInteger)maxCount {
    StockInfo* stockInfo = [[DatabaseHelper getInstance] getInfoById:item.sid];
    item.kdjViewController.kdj_d = _self.kdj_d;
    item.kdjViewController.kdj_j = _self.kdj_j;
    item.kdjViewController.kdj_k = _self.kdj_k;
    item.kdjViewController.todayStartIndex = _self.todayStartIndex;
    
    item.klineViewController.todayStartIndex = _self.todayStartIndex;
    [item.klineViewController setSplitX:_self.todayStartIndex];
    item.klineViewController.priceKValues = _self.priceKValues;
    [item.klineViewController setStockInfo:stockInfo];
    item.klineViewController.boll_ma = _self.boll_ma;
    item.klineViewController.bool_md = _self.boll_md;
    
    item.klineViewController.timeDelta = item.delta;
    if (item.delta == ONE_DAY) {
        item.klineViewController.timeStartIndex = [stockInfo.hundredDaysPrice count] - [_self.kdj_d count];
    } else if (item.delta == ONE_WEEK) {
        item.klineViewController.timeStartIndex = [stockInfo.weeklyPrice count] - [_self.kdj_d count];
    } else {
        NSInteger minuteCount = [stockInfo.fiveDayPriceByMinutes count] + [stockInfo.todayPriceByMinutes count];
        NSInteger count = minuteCount / item.delta;
        if (minuteCount % item.delta != 0) {
            count ++;
        }
        item.klineViewController.timeStartIndex = count - [_self.kdj_d count];
    }
    
    NSInteger startIndex = [_self.priceKValues count] - [_self.kdj_d count];
    if (startIndex < 0) {
        startIndex = 0;
    }
    item.klineViewController.startIndex = startIndex;
    
    if (item.aVolController != nil) {
        [self refreshAVOLAsync:_self.lowest andHighest:_self.highest andPrice:_self.priceKValues andVols:_self.volValues andStockInfo:stockInfo andAVOL:item.aVolController];
    }
    
    if (item.volController != nil) {
        [self refreshVOL:startIndex andVolValues:_self.volValues andMaxCount:maxCount andVOL:item.volController];
    }
    
    [item.kdjViewController refresh:item.delta andStock:stockInfo];
    BOOL drawKLine = YES;
    if (maxCount == 30) {
        drawKLine = NO;
    }
    [item.klineViewController refresh:_self.lowest andHighest:_self.highest andDrawKLine:drawKLine];
    
    [self drawMarks:stockInfo andItem:item];
}

-(NSInteger) getMaxCountByDelta:(NSInteger)delta {
    NSInteger maxCount = 0;
    switch (delta) {
        case ONE_MINUTE:
            maxCount = 30;
            break;
        case FIVE_MINUTES:
            maxCount = 24;
            break;
        case FIFTEEN_MINUTES:
            maxCount = 16;
            break;
        case THIRTY_MINUTES:
            maxCount = 16;
            break;
        case ONE_HOUR:
            maxCount = 20;
            break;
        case ONE_DAY:
            maxCount = 10;
            break;
        case ONE_WEEK:
            maxCount = 20;
            break;
        default:
            break;
    }
    return maxCount;
}

-(void) refreshSID:(NSString*)sid {
    StockInfo* stockInfo = [[DatabaseHelper getInstance] getInfoById:sid];
    if (stockInfo == nil) {
        return;
    }
    NSArray* array = [DatabaseHelper getInstance].orgnizedList;
    for (OrgnizedItem* item in array) {
        if ([item.sid isEqualToString:sid] == YES) {
            NSInteger maxCount = [self getMaxCountByDelta:item.delta];
            CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:stockInfo andDelta:item.delta andCount:maxCount];
            __weak OrgnizedItem* _item = item;
            task.onCompleteBlock = ^(CalculateKDJ* _self) {
                [self refreshUI:_item andData:_self andMaxCount:maxCount];
            };
            [[KingdaWorker getInstance] queue:task];
        }
    }
}

-(void) refreshAll {
    for (NSString* sid in _stockIdList) {
        [self refreshSID:sid];
    }
}

-(void) refreshData:(NSString*)sid {
    StockInfo* stockInfo = [[DatabaseHelper getInstance] getInfoById:sid];
    if (stockInfo == nil) {
        return;
    }
    BOOL needSync = YES;
    StockInfo* shInfo = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    StockInfo* szInfo = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    StockInfo* cyInfo = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    //    if ([shInfo.todayPriceByMinutes count] < 3 || [self.stockInfo.todayPriceByMinutes count] < 3
    //        || [shInfo.todayPriceByMinutes count] - [self.stockInfo.todayPriceByMinutes count] > 2) {
    GetTodayStockValue* task = [[GetTodayStockValue alloc] initWithStock:stockInfo];
    [[KingdaWorker getInstance] queue:task];
    GetTodayStockValue* task2 = [[GetTodayStockValue alloc] initWithStock:shInfo];
    GetTodayStockValue* task3 = [[GetTodayStockValue alloc] initWithStock:szInfo];
    GetTodayStockValue* task4 = [[GetTodayStockValue alloc] initWithStock:cyInfo];
    [[KingdaWorker getInstance] queue:task2];
    [[KingdaWorker getInstance] queue:task3];
    [[KingdaWorker getInstance] queue:task4];
    needSync = YES;
    //    }
    
    //    NSDate* date = [NSDate date];
    //    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    //    [dateformatter setDateFormat:@"YYMMdd"];
    //    NSString* dateStr =[dateformatter stringFromDate:date];
    //    NSInteger intValue = [dateStr integerValue];
    NSString* str = [stockInfo.updateDay stringByReplacingOccurrencesOfString:@"-" withString:@""];
    str = [str substringFromIndex:2];
    NSInteger latest = [str integerValue];
    
    NSInteger historyDateValue = [stockInfo.fiveDayLastUpdateDay integerValue];
    //    historyDateValue = 0;
    if (historyDateValue == 0 || latest - historyDateValue >= 2) {
        GetFiveDayStockValue* task = [[GetFiveDayStockValue alloc] initWithStock:stockInfo];
        [[KingdaWorker getInstance] queue:task];
        needSync = YES;
    } else if (latest-historyDateValue == 1 && [stockInfo.fiveDayPriceByMinutes count] < 1200) {
        GetFiveDayStockValue* task = [[GetFiveDayStockValue alloc] initWithStock:stockInfo];
        [[KingdaWorker getInstance] queue:task];
        needSync = YES;
    }
    
    historyDateValue = [stockInfo.hundredDayLastUpdateDay integerValue];
    //    historyDateValue = 0;
    if (historyDateValue == 0 || latest - historyDateValue >= 2) {
        GetDaysStockValue* task5 = [[GetDaysStockValue alloc] initWithStock:stockInfo];
        [[KingdaWorker getInstance] queue:task5];
    } else if (latest-historyDateValue == 1 && [stockInfo.hundredDaysPrice count] < 100) {
        GetDaysStockValue* task5 = [[GetDaysStockValue alloc] initWithStock:stockInfo];
        [[KingdaWorker getInstance] queue:task5];
    }
    
    historyDateValue = [stockInfo.weeklyLastUpdateDay integerValue];
    //    historyDateValue = 0;
    if (historyDateValue == 0) {
        GetWeeksStockValue* task6 = [[GetWeeksStockValue alloc] initWithStock:stockInfo];
        [[KingdaWorker getInstance] queue:task6];
    }
    
//    if (needSync) {
//        SyncPoint* sync = [[SyncPoint alloc] init];
//        sync.onCompleteBlock = ^(StockInfo* info) {
//            [self onStockValueRefreshed];
//            [self onKDJTypeChanged:nil];
//        };
//        [[KingdaWorker getInstance] queue:sync];
//    }
}

-(BOOL) containsSID:(NSString*)_sid {
    for (NSInteger j=0; j<[_stockIdList count]; j++) {
        NSString* sid = [_stockIdList objectAtIndex:j];
        if ([_sid isEqualToString:sid] == YES) {
            return YES;
        }
    }
    return false;
}

-(void) updateOrgnizedStocks {
    [_stockIdList removeAllObjects];
    NSArray* array = [DatabaseHelper getInstance].orgnizedList;
    for (NSInteger i=0; i<[array count]; i++) {
        OrgnizedItem* item = [array objectAtIndex:i];
        if ([self containsSID:item.sid] == YES) {
            continue;
        }
        [_stockIdList addObject:item.sid];
        [self refreshData:item.sid];
    }
    [self refreshAll];
}


@end
