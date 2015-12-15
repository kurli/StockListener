//
//  StockInfo.m
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockInfo.h"

@implementation StockInfo

@synthesize sid;
@synthesize name;

#define SID @"sid"
#define NAME @"name"
#define CURRENT_PRICE @"current_price"
#define CHANGE_RATE @"change_rate"
#define BUY_SELL_DIC @"buy_sell_dic"

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
    if (self.buySellDic != nil) {
        [aCoder encodeObject:self.buySellDic forKey:BUY_SELL_DIC];
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
        if (self.buySellDic == nil) {
            self.buySellDic = [[NSMutableDictionary alloc] init];
        }
//        self.currentPrice = [(NSNumber*)[aDecoder decodeObjectForKey:CURRENT_PRICE] floatValue];
//        self.changeRate = [(NSNumber*)[aDecoder decodeObjectForKey:CHANGE_RATE] floatValue];
    }
    return self;
}

@end
