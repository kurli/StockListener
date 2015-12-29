//
//  UserLoginTask.m
//  SmartHome
//
//  Created by LiGuozhen on 15-2-4.
//  Copyright (c) 2015年 LiGuozhen. All rights reserved.
//

#import "GetStockValueTask.h"
#import <CommonCrypto/CommonDigest.h>
#import "StockPlayerManager.h"
#import "StockInfo.h"
#import "DatabaseHelper.h"

//#define ENABLE_TEST

@interface GetStockValueTask()

@property (nonatomic, strong) NSMutableString* ids;
@property (nonatomic, strong) StockInfo* neededNewInfo;
#ifdef ENABLE_TEST
@property (nonatomic, strong) NSArray* testArray;
#endif
@end

@implementation GetStockValueTask

-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.ids = [[NSMutableString alloc] init];
        [self.ids appendString:info.sid];
        self.neededNewInfo = info;
    }
    return self;
}

-(id) initWithStocks:(NSArray*) infos {
    if ((self = [super init]) != nil) {
#ifdef ENABLE_TEST
        self.ids = [[NSMutableString alloc] init];
        [self.ids appendString:@"sz000025"];
        return self;
#else
        self.ids = [[NSMutableString alloc] init];
        if (infos == nil) {
            return self;
        }
        for (StockInfo* info in infos) {
            [self.ids appendFormat:@"%@,", info.sid];
        }
#endif
    }
    return self;
}

-(void) run {
#ifdef ENABLE_TEST
    [self onComplete:@"var hq_str_s_sh000001=\"上证指数,3636.089,-15.678,-0.43,2982018,41990292\";\n\
     var hq_str_s_sz399001=\"深证成指,13007.868,-131.257,-1.00,312253260,57675659\";\n\
     var hq_str_s_sz399006=\"创业板指,2783.942,-55.910,-1.97,16247176,4849739\";\n\
     var hq_str_sz000025=\"特  力Ａ,91.40,92.33,90.05,92.78,90.01,90.05,90.06,11814273,1069541834.39,159570,90.05,47800,90.04,12400,90.03,3879,90.02,19100,90.01,30980,90.06,2700,90.07,9700,90.08,6200,90.09,4100,90.10,2015-12-23,15:36:55,00\";"];
#else
    [self post:self.ids];
#endif
}


-(void) calculateStep:(StockInfo*)info andNewPrice:(float)newPrice {
    if (info.price == 0 || info.price == newPrice) {
        info.step = 0;
        info.speed = 0;
        return;
    }
    float speed = (newPrice - info.price) / info.price;
    speed*=100;
    if (info.speed == 0) {
        info.step = 1;
    } else {
        float rt0 = info.speed < 0 ? info.speed * -1 : info.speed;
        float rt1 = speed < 0 ? speed * -1 : speed;
        float tmpDrt = rt1 / rt0;
        
        float t = tmpDrt * info.step;
        if (((int)(t*10) % 10) >= 5) {
            t += 1;
        }
        if (info.speed * speed > 0) {
            t++;
        }
        info.step = t;
    }
    if (info.step <= 0) {
        info.step = 1;
    }
    if (info.step > 5) {
        info.step = 5;
    }

    info.speed = speed;
}

-(void) parseDapan:(NSArray*)array andSID:(NSString*)sid {
    StockInfo* info = [[DatabaseHelper getInstance] getDapanInfoById:sid];
    info.name = [array objectAtIndex:0];
    float newPrice = [[array objectAtIndex:1] floatValue];
    info.changeRate = [[array objectAtIndex:3] floatValue]/100;
    [self calculateStep:info andNewPrice:newPrice];
    info.price = newPrice;
    //Hack
#ifndef ENABLE_TEST
    if (info.dealCount != [[array objectAtIndex:4] longLongValue]) {
#endif
        info.dealCount = [[array objectAtIndex:4] longLongValue];
        [info newPriceGot];
#ifndef ENABLE_TEST
    }
#endif
}

-(void) parseValueForSina:(NSString*)str {
    if (str == nil) {
        return;
    }

    NSRange range = [str rangeOfString:@"var hq_str_"];
    if (range.location == NSNotFound) {
        return;
    }
    NSRange equalRange = [str rangeOfString:@"="];
    if (equalRange.location == NSNotFound) {
        return;
    }
    NSRange sIDRange = NSMakeRange(range.location + range.length, equalRange.location - range.length - range.location);
    
    NSString* sid = [str substringWithRange:sIDRange];
    
    range.location = sIDRange.location + sIDRange.length + 2;
    NSString* subStr = [str substringFromIndex:range.location];
    NSArray* array = [subStr componentsSeparatedByString:@","];
    if ([array count] == 6) {
        [self parseDapan:array andSID:sid];
        return;
    }
    if ([array count] < 32) {
        return;
    }

    StockInfo* info = [[DatabaseHelper getInstance] getInfoById:sid];
    if (info == nil) {
        if (_neededNewInfo!= nil && [sid isEqualToString:_neededNewInfo.sid]) {
            info = _neededNewInfo;
        } else {
            return;
        }
    }
    info.lastDayPrice = [[array objectAtIndex:2] floatValue];
    if (info.lastDayPrice == 0) {
        return;
    }
    info.name = [array objectAtIndex:0];
    info.openPrice = [[array objectAtIndex:1] floatValue];
    info.lastDayPrice = [[array objectAtIndex:2] floatValue];
    float newPrice = [[array objectAtIndex:3] floatValue];
    info.todayHighestPrice = [[array objectAtIndex:4] floatValue];
    info.todayLoestPrice = [[array objectAtIndex:5] floatValue];
    info.dealCount = [[array objectAtIndex:8] longLongValue];
    info.dealTotalMoney = [[array objectAtIndex:9] floatValue];
    
    NSString* updateDay = [array objectAtIndex:30];
    if (![info.updateDay isEqualToString:updateDay]) {
        [info.buySellDic removeAllObjects];
        [info.priceHistoryFiveMinutes removeAllObjects];
        [info.priceHistoryHalfMinute removeAllObjects];
        [info.priceHistoryOneMinutes removeAllObjects];
    }
    info.updateDay = updateDay;

    info.buyOneCount = [[array objectAtIndex:10] longLongValue];
    info.buyOnePrice = [[array objectAtIndex:11] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.buyOneCount] forKey:[NSNumber numberWithFloat:info.buyOnePrice]];
    info.buyTwoCount = [[array objectAtIndex:12] longLongValue];
    info.buyTwoPrice = [[array objectAtIndex:13] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.buyTwoCount] forKey:[NSNumber numberWithFloat:info.buyTwoPrice]];
    info.buyThreeCount = [[array objectAtIndex:14] longLongValue];
    info.buyThreePrice = [[array objectAtIndex:15] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.buyThreeCount] forKey:[NSNumber numberWithFloat:info.buyThreePrice]];
    info.buyFourCount = [[array objectAtIndex:16] longLongValue];
    info.buyFourPrice = [[array objectAtIndex:17] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.buyFourCount] forKey:[NSNumber numberWithFloat:info.buyFourPrice]];
    info.buyFiveCount = [[array objectAtIndex:18] longLongValue];
    info.buyFivePrice = [[array objectAtIndex:19] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.buyFiveCount] forKey:[NSNumber numberWithFloat:info.buyFivePrice]];
    info.sellOneCount = [[array objectAtIndex:20] longLongValue];
    info.sellOnePrice = [[array objectAtIndex:21] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.sellOneCount] forKey:[NSNumber numberWithFloat:info.sellOnePrice]];
    info.sellTwoCount = [[array objectAtIndex:22] longLongValue];
    info.sellTwoPrice = [[array objectAtIndex:23] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.sellTwoCount] forKey:[NSNumber numberWithFloat:info.sellTwoPrice]];
    info.sellThreeCount = [[array objectAtIndex:24] longLongValue];
    info.sellThreePrice = [[array objectAtIndex:25] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.sellThreeCount] forKey:[NSNumber numberWithFloat:info.sellThreePrice]];
    info.sellFourCount = [[array objectAtIndex:26] longLongValue];
    info.sellFourPrice = [[array objectAtIndex:27] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.sellFourCount] forKey:[NSNumber numberWithFloat:info.sellFourPrice]];
    info.sellFiveCount = [[array objectAtIndex:28] longLongValue];
    info.sellFivePrice = [[array objectAtIndex:29] floatValue];
    [info.buySellDic setObject:[NSNumber numberWithLongLong:info.sellFiveCount] forKey:[NSNumber numberWithFloat:info.sellFivePrice]];
    
//    [info.buySellDic setObject:[NSNumber numberWithLongLong:8330000] forKey:[NSNumber numberWithFloat:0.833]];
//    [info.buySellDic setObject:[NSNumber numberWithLongLong:8350000] forKey:[NSNumber numberWithFloat:0.835]];
//    [info.buySellDic setObject:[NSNumber numberWithLongLong:8370000] forKey:[NSNumber numberWithFloat:0.837]];
//    [info.buySellDic setObject:[NSNumber numberWithLongLong:8500000] forKey:[NSNumber numberWithFloat:0.848]];
    
#ifndef ENABLE_TEST
    if (info.updateTime != nil && [info.updateTime isEqualToString:[array objectAtIndex:31]]) {
        return;
    }
#endif
    info.updateTime = [array objectAtIndex:31];

#ifdef ENABLE_TEST
    newPrice = [self getTestData:info];
#endif
    info.changeRate = (newPrice - info.lastDayPrice) / info.lastDayPrice;

    if (info.price <= 0) {
        info.price = newPrice;
        info.step = 0;
        info.speed = 0;
    } else {
        [self calculateStep:info andNewPrice:newPrice];
        info.price = newPrice;
    }
    [info newPriceGot];
}

-(void) onComplete:(NSString *)data {
    NSArray* array = [data componentsSeparatedByString:@";"];
    if ([array count] == 0) {
        return;
    }
    for (NSString* str in array) {
        [self parseValueForSina:str];
    }

    if (self.delegate) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate onStockValuesRefreshed];
        });
    }
    if (self.onCompleteBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            StockInfo* info = [[DatabaseHelper getInstance] getInfoById:self.ids];
            if (info == nil) {
                info = _neededNewInfo;
            }
            self.onCompleteBlock(info);
        });
    }
}
#ifdef ENABLE_TEST
-(float)getTestData:(StockInfo*)info {
    static int index = 200;
    if (self.testArray == nil) {
        NSString* data = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"test" withExtension:@"data"]  encoding:NSUTF8StringEncoding error:nil];
        self.testArray = [data componentsSeparatedByString:@"\n"];
    }
    if (index >= [self.testArray count]) {
        index = 0;
    }
    NSString* str = [self.testArray objectAtIndex:index];
    index+=2;
    NSArray* arr2 = [str componentsSeparatedByString:@" "];
    info.updateTime = [arr2 objectAtIndex:0];
    NSString* price = [arr2 objectAtIndex:1];
    info.lastDayPrice = 92.33;
    info.openPrice = 91.40;
    
    return [price floatValue];
}
#endif

@end
