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
#define PRICE_HISTORY_MINUTE @"price_history_minute"
#define PRICE_HISTORY_FIVE_MINUTE @"price_history_five_minute"
#define PRICE_HISTORY_HALF_MINUTE @"price_history_half_minute"

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
        self.priceHistoryHalfMinute = [[NSMutableDictionary alloc] init];
        self.priceHistoryOneMinutes = [[NSMutableDictionary alloc] init];
        self.priceHistoryFiveMinutes = [[NSMutableDictionary alloc] init];
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
    info.priceHistoryFiveMinutes = [self.priceHistoryFiveMinutes copy];
    info.priceHistoryHalfMinute = [self.priceHistoryHalfMinute copy];
    info.priceHistoryOneMinutes = [self.priceHistoryOneMinutes copy];
    
    return info;
}

//-(void) assign:(StockInfo*) info {
//    self.name = info.name;
//    self.currentPrice = info.currentPrice;
//    self.lastChangeRate = info.lastChangeRate;
//    self.changeRate = info.changeRate;
//    self.lastStep = info.lastStep;
//    self.lastPrice = info.lastPrice;
//}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.sid forKey:SID];
    [aCoder encodeObject:self.name forKey:NAME];
    [aCoder encodeObject:self.updateDay forKey:UPDATE_DAY];
    if (self.buySellDic != nil) {
        [aCoder encodeObject:self.buySellDic forKey:BUY_SELL_DIC];
    }
    if (self.priceHistoryFiveMinutes != nil) {
        [aCoder encodeObject:self.priceHistoryFiveMinutes forKey:PRICE_HISTORY_FIVE_MINUTE];
    }
    if (self.priceHistoryHalfMinute != nil) {
        [aCoder encodeObject:self.priceHistoryHalfMinute forKey:PRICE_HISTORY_HALF_MINUTE];
    }
    if (self.priceHistoryOneMinutes != nil) {
        [aCoder encodeObject:self.priceHistoryOneMinutes forKey:PRICE_HISTORY_MINUTE];
    }
//    [aCoder encodeObject:[NSNumber numberWithFloat:self.currentPrice] forKey:CURRENT_PRICE];
//    [aCoder encodeObject:[NSNumber numberWithFloat:self.changeRate] forKey:CHANGE_RATE];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.sid = [aDecoder decodeObjectForKey:SID];
        self.name = [aDecoder decodeObjectForKey:NAME];
        self.buySellDic = [aDecoder decodeObjectForKey:BUY_SELL_DIC];
        self.updateDay = [aDecoder decodeObjectForKey:UPDATE_DAY];
        self.priceHistoryFiveMinutes = [aDecoder decodeObjectForKey:PRICE_HISTORY_FIVE_MINUTE];
        self.priceHistoryHalfMinute = [aDecoder decodeObjectForKey:PRICE_HISTORY_HALF_MINUTE];
        self.priceHistoryOneMinutes = [aDecoder decodeObjectForKey:PRICE_HISTORY_MINUTE];

        if (self.buySellDic == nil) {
            self.buySellDic = [[NSMutableDictionary alloc] init];
        }
        if (self.priceHistoryFiveMinutes == nil) {
            self.priceHistoryFiveMinutes = [[NSMutableDictionary alloc] init];
        }
        if (self.priceHistoryHalfMinute == nil) {
            self.priceHistoryHalfMinute = [[NSMutableDictionary alloc] init];
        }
        if (self.priceHistoryOneMinutes == nil) {
            self.priceHistoryOneMinutes = [[NSMutableDictionary alloc] init];
        }
//        self.currentPrice = [(NSNumber*)[aDecoder decodeObjectForKey:CURRENT_PRICE] floatValue];
//        self.changeRate = [(NSNumber*)[aDecoder decodeObjectForKey:CHANGE_RATE] floatValue];
    }
    return self;
}

-(void) newPriceGot {
    NSArray* timeArray = [self.updateTime componentsSeparatedByString:@":"];
    if ([timeArray count] != 3) {
        return;
    }
    long hour = [[timeArray objectAtIndex:0] longLongValue] ;
    long minute = [[timeArray objectAtIndex:1] longLongValue];
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
}

@end
