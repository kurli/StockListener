//
//  StockInfo.m
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockInfo.h"

@interface StockInfo()
@end

@implementation StockInfo

@synthesize sid;
@synthesize name;

#define SID @"sid"
#define NAME @"name"
#define CURRENT_PRICE @"current_price"
#define CHANGE_RATE @"change_rate"
#define BUY_SELL_DIC @"buy_sell_dic"
#define UPDATE_DAY @"upreate_day"
#define FIVE_DAY_PRICE_HISTORY @"five_day_price_history"
#define FIVE_DAY_VOL_HISTORY @"five_day_vol_history"
#define FIVE_DAY_LAST_UPDAT_DAY @"five_day_update_day"
#define HUNDRED_DAY_PRICE_HISTORY @"hundred_day_price_history"
#define HUNDRED_DAY_VOL_HISTORY @"hundred_day_vol_history"
#define HUNDRED_DAY_UPDATE_DAY @"hundred_day_update_day"
#define AVERAGE_VOL_DIC @"average_vol_dic"
#define WEEKLY_PRICE_HISTORY @"weekly_price_history"
#define WEEKLY_VOL_HISTORY @"weekly_vol_history"
#define WEEKLY_UPDATE_DAY @"weekly_update_day"
#define BUY_SELL_HISTORY @"buy_sell_history"

////
//Tax
#define YIN_HUA_SHUI 0.001
#define MAX_YONGJIN 0.003
#define YONG_JIN 0.0003
#define MIN_YONG_JIN 5
#define GUO_HU_FEI 0.0006
////

- (id) init {
    if (self = [super init]) {
        self.name = @"-";
        self.sid = @"-";
        self.step = 0;
        self.changeRate = 0;
        self.speed = 0;
        self.openPrice = 0;
        self.lastDayPrice = 0;
        self.price = 0;
        self.todayHighestPrice = 0;
        self.todayLoestPrice = 0;
        self.dealCount = 0;
        self.dealTotalMoney = 0;
        self.buyOneCount = 0;
        self.buyOnePrice = 0;
        self.buyTwoCount = 0;
        self.buyTwoPrice = 0;
        self.buyThreeCount = 0;
        self.buyThreePrice = 0;
        self.buyFourCount = 0;
        self.buyFourPrice = 0;
        self.buyFiveCount = 0;
        self.buyFivePrice = 0;
        self.sellOneCount = 0;
        self.sellOnePrice = 0;
        self.sellTwoPrice = 0;
        self.sellTwoCount = 0;
        self.sellThreeCount = 0;
        self.sellThreePrice = 0;
        self.sellFourCount = 0;
        self.sellFourPrice = 0;
        self.sellFiveCount = 0;
        self.sellFivePrice = 0;
        self.updateDay = @"";
        self.updateTime = @"";
        self.buySellDic = [[NSMutableDictionary alloc] init];
        self.fiveDayPriceByMinutes = [[NSMutableArray alloc] init];
        self.fiveDayVOLByMinutes = [[NSMutableArray alloc] init];
        self.fiveDayLastUpdateDay = @"";
        self.hundredDaysPrice = [[NSMutableArray alloc] init];
        self.hundredDaysVOL = [[NSMutableArray alloc] init];
        self.hundredDayLastUpdateDay = @"";
        self.averageVolDic = [[NSMutableDictionary alloc] init];
        self.weeklyPrice = [[NSMutableArray alloc] init];
        self.weeklyVOL = [[NSMutableArray alloc] init];
        self.weeklyLastUpdateDay = @"";
        self.buySellHistory = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    StockInfo* info = [[StockInfo allocWithZone:zone] init];
    info.sid = [self.sid copy];
    info.name = [self.name copy];
    info.price = self.price;
    info.changeRate = self.changeRate;
    info.step = self.step;
    
    info.openPrice = self.openPrice;
    info.lastDayPrice = self.lastDayPrice;
    
    info.buySellDic = [self.buySellDic copy];
    info.todayPriceByMinutes = [self.todayPriceByMinutes copy];
    info.fiveDayPriceByMinutes = [self.fiveDayPriceByMinutes copy];
    info.fiveDayVOLByMinutes = [self.fiveDayVOLByMinutes copy];
    info.fiveDayLastUpdateDay = [self.fiveDayLastUpdateDay copy];
    info.hundredDayLastUpdateDay = [self.hundredDayLastUpdateDay copy];
    info.hundredDaysVOL = [self.hundredDaysVOL copy];
    info.hundredDaysPrice = [self.hundredDaysPrice copy];
    info.averageVolDic = [self.averageVolDic copy];
    info.weeklyLastUpdateDay = [self.weeklyLastUpdateDay copy];
    info.weeklyVOL = [self.weeklyVOL copy];
    info.weeklyPrice = [self.weeklyPrice copy];
    info.buySellHistory = [self.buySellHistory copy];
    return info;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.sid forKey:SID];
    [aCoder encodeObject:self.name forKey:NAME];
    [aCoder encodeObject:self.updateDay forKey:UPDATE_DAY];
    if (self.buySellDic != nil) {
        [aCoder encodeObject:self.buySellDic forKey:BUY_SELL_DIC];
    }
    if (self.fiveDayLastUpdateDay != nil) {
        [aCoder encodeObject:self.fiveDayLastUpdateDay forKey:FIVE_DAY_LAST_UPDAT_DAY];
    }
    if (self.fiveDayPriceByMinutes != nil) {
        [aCoder encodeObject:self.fiveDayPriceByMinutes forKey:FIVE_DAY_PRICE_HISTORY];
    }
    if (self.fiveDayVOLByMinutes != nil) {
        [aCoder encodeObject:self.fiveDayVOLByMinutes forKey:FIVE_DAY_VOL_HISTORY];
    }
    if (self.hundredDaysPrice != nil) {
        [aCoder encodeObject:self.hundredDaysPrice forKey:HUNDRED_DAY_PRICE_HISTORY];
    }
    if (self.hundredDaysVOL != nil) {
        [aCoder encodeObject:self.hundredDaysVOL forKey:HUNDRED_DAY_VOL_HISTORY];
    }
    if (self.hundredDayLastUpdateDay != nil) {
        [aCoder encodeObject:self.hundredDayLastUpdateDay forKey:HUNDRED_DAY_UPDATE_DAY];
    }
    if (self.averageVolDic != nil) {
        [aCoder encodeObject:self.averageVolDic forKey:AVERAGE_VOL_DIC];
    }
    if (self.weeklyPrice != nil) {
        [aCoder encodeObject:self.weeklyPrice forKey:WEEKLY_PRICE_HISTORY];
    }
    if (self.weeklyVOL != nil) {
        [aCoder encodeObject:self.weeklyVOL forKey:WEEKLY_VOL_HISTORY];
    }
    if (self.weeklyLastUpdateDay != nil) {
        [aCoder encodeObject:self.weeklyLastUpdateDay forKey:WEEKLY_UPDATE_DAY];
    }
    if (self.buySellHistory != nil) {
        [aCoder encodeObject:self.buySellHistory forKey:BUY_SELL_HISTORY];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.sid = [aDecoder decodeObjectForKey:SID];
        self.name = [aDecoder decodeObjectForKey:NAME];
        self.buySellDic = [aDecoder decodeObjectForKey:BUY_SELL_DIC];
        self.updateDay = [aDecoder decodeObjectForKey:UPDATE_DAY];
        self.fiveDayLastUpdateDay = [aDecoder decodeObjectForKey:FIVE_DAY_LAST_UPDAT_DAY];
        self.fiveDayPriceByMinutes = [aDecoder decodeObjectForKey:FIVE_DAY_PRICE_HISTORY];
        self.fiveDayVOLByMinutes = [aDecoder decodeObjectForKey:FIVE_DAY_VOL_HISTORY];
        self.hundredDayLastUpdateDay = [aDecoder decodeObjectForKey:HUNDRED_DAY_UPDATE_DAY];
        self.hundredDaysVOL = [aDecoder decodeObjectForKey:HUNDRED_DAY_VOL_HISTORY];
        self.hundredDaysPrice = [aDecoder decodeObjectForKey:HUNDRED_DAY_PRICE_HISTORY];
        self.averageVolDic = [aDecoder decodeObjectForKey:AVERAGE_VOL_DIC];
        self.weeklyLastUpdateDay = [aDecoder decodeObjectForKey:WEEKLY_UPDATE_DAY];
        self.weeklyVOL = [aDecoder decodeObjectForKey:WEEKLY_VOL_HISTORY];
        self.weeklyPrice = [aDecoder decodeObjectForKey:WEEKLY_PRICE_HISTORY];
        self.buySellHistory = [aDecoder decodeObjectForKey:BUY_SELL_HISTORY];

        if (self.buySellDic == nil) {
            self.buySellDic = [[NSMutableDictionary alloc] init];
        }
        if (self.fiveDayLastUpdateDay == nil) {
            self.fiveDayLastUpdateDay = @"";
        }
        if (self.fiveDayPriceByMinutes == nil) {
            self.fiveDayPriceByMinutes = [[NSMutableArray alloc] init];
        }
        if (self.fiveDayVOLByMinutes == nil) {
            self.fiveDayVOLByMinutes = [[NSMutableArray alloc] init];
        }
        if (self.hundredDayLastUpdateDay == nil) {
            self.hundredDayLastUpdateDay = @"";
        }
        if (self.hundredDaysVOL == nil) {
            self.hundredDaysVOL = [[NSMutableArray alloc] init];
        }
        if (self.hundredDaysPrice == nil) {
            self.hundredDaysPrice = [[NSMutableArray alloc] init];
        }
        if (self.averageVolDic == nil) {
            self.averageVolDic = [[NSMutableDictionary alloc] init];
        }
        if (self.weeklyLastUpdateDay == nil) {
            self.weeklyLastUpdateDay = @"";
        }
        if (self.weeklyVOL == nil) {
            self.weeklyVOL = [[NSMutableArray alloc] init];
        }
        if (self.weeklyPrice == nil) {
            self.weeklyPrice = [[NSMutableArray alloc] init];
        }
        if (self.buySellHistory == nil) {
            self.buySellHistory = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

-(void) newPriceGot {
    if (self.price <= 0) {
        return;
    }
    if ([self.updateDay length] > 6 && [self.hundredDaysPrice count] > 0) {
        NSString* str = [self.updateDay stringByReplacingOccurrencesOfString:@"-" withString:@""];
        str = [str substringFromIndex:2];
        NSInteger latest = [str integerValue];
        NSInteger history = [self.hundredDayLastUpdateDay integerValue];
        if (latest - history == 0) {
            [self.hundredDaysPrice removeLastObject];
            [self.hundredDaysVOL removeLastObject];
            NSMutableArray* array = [[NSMutableArray alloc] init];
            [array addObject:[NSNumber numberWithFloat:self.todayHighestPrice]];
            [array addObject:[NSNumber numberWithFloat:self.price]];
            [array addObject:[NSNumber numberWithFloat:self.todayLoestPrice]];
            [self.hundredDaysPrice addObject:array];
            [self.hundredDaysVOL addObject:[NSNumber numberWithInteger:self.dealCount]];
        } else if (latest - history > 0) {
            NSMutableArray* array = [[NSMutableArray alloc] init];
            [array addObject:[NSNumber numberWithFloat:self.todayHighestPrice]];
            [array addObject:[NSNumber numberWithFloat:self.price]];
            [array addObject:[NSNumber numberWithFloat:self.todayLoestPrice]];
            [self.hundredDaysPrice addObject:array];
            [self.hundredDaysVOL addObject:[NSNumber numberWithInteger:self.dealCount]];
            self.hundredDayLastUpdateDay = [NSString stringWithFormat:@"%ld", latest];
        }
    }
    //TODO
//    if ([self.updateDay length] > 6 && [self.weeklyPrice count] > 0) {
//        NSString* str = [self.updateDay stringByReplacingOccurrencesOfString:@"-" withString:@""];
//        str = [str substringFromIndex:2];
//        NSInteger latest = [str integerValue];
//        NSInteger history = [self.weeklyLastUpdateDay integerValue];
//        if (latest - history == 0) {
//            [self.weeklyPrice removeLastObject];
//            [self.weeklyVOL removeLastObject];
//            NSMutableArray* array = [[NSMutableArray alloc] init];
//            [array addObject:[NSNumber numberWithFloat:self.todayHighestPrice]];
//            [array addObject:[NSNumber numberWithFloat:self.price]];
//            [array addObject:[NSNumber numberWithFloat:self.todayLoestPrice]];
//            [self.hundredDaysPrice addObject:array];
//            [self.hundredDaysVOL addObject:[NSNumber numberWithInteger:self.dealCount]];
//        } else if (latest - history > 0) {
//            NSMutableArray* array = [[NSMutableArray alloc] init];
//            [array addObject:[NSNumber numberWithFloat:self.todayHighestPrice]];
//            [array addObject:[NSNumber numberWithFloat:self.price]];
//            [array addObject:[NSNumber numberWithFloat:self.todayLoestPrice]];
//            [self.hundredDaysPrice addObject:array];
//            [self.hundredDaysVOL addObject:[NSNumber numberWithInteger:self.dealCount]];
//            self.hundredDayLastUpdateDay = [NSString stringWithFormat:@"%ld", latest];
//        }
//    }

    // Store price
    NSArray* timeArray = [self.updateTime componentsSeparatedByString:@":"];
    if ([timeArray count] != 3) {
        return;
    }
    long hour = [[timeArray objectAtIndex:0] integerValue] ;
    long minute = [[timeArray objectAtIndex:1] integerValue];

    NSInteger index = 0;
    index = (hour - 9) * 60 + minute - 30;
    if (hour >= 13) {
        index -= 90;
    }
    if (hour >= 11 && hour < 13 && minute >= 30) {
        return;
    }
    if ([self.todayPriceByMinutes count] == 0) {
        [self.todayPriceByMinutes addObject:[NSNumber numberWithFloat:self.price]];
        [self.todayVOLByMinutes addObject:[NSNumber numberWithInteger:self.dealCount]];
        return;
    }
    if (index >=240) {
        return;
    }
    if (index > [self.todayPriceByMinutes count]-1) {
        [self.todayPriceByMinutes addObject:[NSNumber numberWithFloat:self.price]];
        NSInteger preVol = 0;
        for (int i=0; i<[self.todayVOLByMinutes count]; i++) {
            preVol += [[self.todayVOLByMinutes objectAtIndex:i] integerValue];
        }
        [self.todayVOLByMinutes addObject:[NSNumber numberWithInteger:self.dealCount - preVol]];
        return;
    }
    [self.todayPriceByMinutes removeLastObject];
    [self.todayPriceByMinutes addObject:[NSNumber numberWithFloat:self.price]];
    [self.todayVOLByMinutes removeLastObject];
    
    NSInteger preVol = 0;
    for (int i=0; i<[self.todayVOLByMinutes count]; i++) {
        preVol += [[self.todayVOLByMinutes objectAtIndex:i] integerValue];
    }
    [self.todayVOLByMinutes addObject:[NSNumber numberWithInteger:self.dealCount - preVol]];
    /*
    long second = [[timeArray objectAtIndex:2] longLongValue];
    long totalSecond = hour * 60 * 60;
    totalSecond += (minute * 60);
    totalSecond += second;
    totalSecond -= (9*60*60 + 30*60);
    if (totalSecond < 0) {
        return;
    }
    if (totalSecond > (2*60*60)) {
        if (totalSecond < (3*60*60 + 30 *60)) {
            return;
        }
        totalSecond -= (60*60 + 30*60);
    }
    NSString* halfMinuteKey = [NSString stringWithFormat:@"%ld", totalSecond / 30];
    NSString* minuteKey = [NSString stringWithFormat:@"%ld", totalSecond / 60];
    NSString* fiveMinuteKey = [NSString stringWithFormat:@"%ld", totalSecond / (5 * 60)];
    NSLog(@"%@ %@ %@", halfMinuteKey, minuteKey, fiveMinuteKey);
    // Half minute data
    NSString* halfMinuteData = [self.priceHistoryHalfMinute valueForKey:halfMinuteKey];
    if (halfMinuteData != nil) {
        NSArray* prices = [halfMinuteData componentsSeparatedByString:@" "];
        if ([prices count] == 3) {
            float highP = [[prices objectAtIndex:0] floatValue];
            float lowP = [[prices objectAtIndex:2] floatValue];
            if (highP < self.price) {
                highP = self.price;
            }
            if (lowP > self.price) {
                lowP = self.price;
            }
            NSString* data = [NSString stringWithFormat:@"%f %f %f", highP, self.price, lowP];
            [self.priceHistoryHalfMinute setObject:data forKey:halfMinuteKey];
//            NSLog(@"%@", data);
        } else {
            halfMinuteData = nil;
        }
    }
    if (halfMinuteData == nil) {
        NSString* data = [NSString stringWithFormat:@"%f %f %f", self.price, self.price, self.price];
        [self.priceHistoryHalfMinute setObject:data forKey:halfMinuteKey];
//        NSLog(@"%@", data);
    }
    // minute data
    NSString* minuteData = [self.priceHistoryOneMinutes valueForKey:minuteKey];
    if (minuteData != nil) {
        NSArray* prices = [minuteData componentsSeparatedByString:@" "];
        if ([prices count] == 3) {
            float highP = [[prices objectAtIndex:0] floatValue];
            float lowP = [[prices objectAtIndex:2] floatValue];
            if (highP < self.price) {
                highP = self.price;
            }
            if (lowP > self.price) {
                lowP = self.price;
            }
            NSString* data = [NSString stringWithFormat:@"%f %f %f", highP, self.price, lowP];
            [self.priceHistoryOneMinutes setObject:data forKey:minuteKey];
//            NSLog(@"%@", data);
        } else {
            minuteData = nil;
        }
    }
    if (minuteData == nil) {
        NSString* data = [NSString stringWithFormat:@"%f %f %f", self.price, self.price, self.price];
        [self.priceHistoryOneMinutes setObject:data forKey:minuteKey];
//        NSLog(@"%@", data);
    }
    // Five minutes
    NSString* fiveMinuteData = [self.priceHistoryFiveMinutes valueForKey:fiveMinuteKey];
    if (fiveMinuteData != nil) {
        NSArray* prices = [fiveMinuteData componentsSeparatedByString:@" "];
        if ([prices count] == 3) {
            float highP = [[prices objectAtIndex:0] floatValue];
            float lowP = [[prices objectAtIndex:2] floatValue];
            if (highP < self.price) {
                highP = self.price;
            }
            if (lowP > self.price) {
                lowP = self.price;
            }
            NSString* data = [NSString stringWithFormat:@"%f %f %f", highP, self.price, lowP];
            [self.priceHistoryFiveMinutes setObject:data forKey:fiveMinuteKey];
//            NSLog(@"%@", data);
        } else {
            fiveMinuteData = nil;
        }
    }
    if (fiveMinuteData == nil) {
        NSString* data = [NSString stringWithFormat:@"%f %f %f", self.price, self.price, self.price];
        [self.priceHistoryFiveMinutes setObject:data forKey:fiveMinuteKey];
//        NSLog(@"%@", data);
    }
     */
}

-(float) getTaxForSell:(float)price andDealCount:(NSInteger) dealCount {
    float yongjin = price*dealCount * YONG_JIN;
    float maxYongjin = price*dealCount * MAX_YONGJIN;
    if (yongjin > maxYongjin) {
        yongjin = maxYongjin;
    }
    if (yongjin < 5.0) {
        yongjin = 5.0;
    }
    float guohu = (float)dealCount * GUO_HU_FEI;
    if (guohu < 1.0) {
        guohu = 1;
    }
    if ([self.sid containsString:@"sz"]) {
        guohu = 0;
    }
    float yinhua = price*dealCount * YIN_HUA_SHUI;
    NSString* start = [self.sid substringWithRange:NSMakeRange(2, 1)];
    if (![start isEqualToString:@"6"] && ![start isEqualToString:@"0"]
        && ![start isEqualToString:@"3"]) {
        guohu = 0;
        yinhua = 0;
    }
    return guohu + yongjin + yinhua;
}

-(float) getTaxForBuy:(float)price andDealCount:(NSInteger) dealCount {
    float yongjin = price*dealCount * YONG_JIN;
    float maxYongjin = price*dealCount * MAX_YONGJIN;
    if (yongjin > maxYongjin) {
        yongjin = maxYongjin;
    }
    if (yongjin < 5.0) {
        yongjin = 5.0;
    }
    float guohu = (float)dealCount * GUO_HU_FEI;
    if (guohu < 1.0) {
        guohu = 1;
    }
    if ([self.sid containsString:@"sz"]) {
        guohu = 0;
    }

    NSString* start = [self.sid substringWithRange:NSMakeRange(2, 1)];
    if (![start isEqualToString:@"6"] && ![start isEqualToString:@"0"]
        && ![start isEqualToString:@"3"]) {
        guohu = 0;
    }
    return guohu + yongjin;
}

@end
