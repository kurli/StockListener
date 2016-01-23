//
//  CalculateKDJ.m
//  StockListener
//
//  Created by Guozhen Li on 1/6/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "CalculateKDJ.h"
#import "StockInfo.h"
#import "StockKDJViewController.h"

@interface CalculateKDJ() {
    StockInfo* stockInfo;
    NSInteger delta;
}
@end

@implementation CalculateKDJ

-(id) initWithStockInfo:(StockInfo*)info andDelta:(NSInteger)_delta andCount:(NSInteger) count {
    if ((self = [super init]) != nil) {
        stockInfo = info;
        delta = _delta;
        self.calculateCount = count;
        self.kdj_k = [[NSMutableArray alloc] init];
        self.kdj_d = [[NSMutableArray alloc] init];
        self.kdj_j = [[NSMutableArray alloc] init];
        self.lowest = 10000;
        self.highest = -1000;
    }
    return self;
}

- (void) calculateKDJ:(NSArray *)data andStartIndex:(NSInteger)index {
    float prev_k = 50;
    float prev_d = 50;
    float rsv = 0;
//    if ([data count] > maxCount) {
//        index = [data count] - maxCount;
//    }
    [self.kdj_d removeAllObjects];
    [self.kdj_j removeAllObjects];
    [self.kdj_k removeAllObjects];
    for(NSInteger i = index;i < (data.count);i++){
        float h  = [[[data objectAtIndex:i] objectAtIndex:1] floatValue];
        float l = [[[data objectAtIndex:i] objectAtIndex:3] floatValue];
        float c = [[[data objectAtIndex:i] objectAtIndex:2] floatValue];
        if (i > 10) {
            for(NSInteger j=i;j>i-10;j--){
                if([[[data objectAtIndex:j] objectAtIndex:1] floatValue] > h){
                    h = [[[data objectAtIndex:j] objectAtIndex:1] floatValue];
                }
                
                if([[[data objectAtIndex:j] objectAtIndex:3] floatValue] < l){
                    l = [[[data objectAtIndex:j] objectAtIndex:3] floatValue];
                }
            }
        }
        
        if(h!=l)
            rsv = (c-l)/(h-l)*100;
        float k = 2*prev_k/3+1*rsv/3;
        float d = 2*prev_d/3+1*k/3;
        //        float j = d+2*(d-k);
        float j = 3*k - 2*d;
        
        prev_k = k;
        prev_d = d;
        if (k<0) k=0;
        if (d<0) d=0;
        if (j<0) j=0;
        if (k>100) k = 100;
        if (d>100) d = 100;
        if (j>100) j = 100;
        
        [self.kdj_k addObject:[NSNumber numberWithFloat:k]];
        [self.kdj_d addObject:[NSNumber numberWithFloat:d]];
        [self.kdj_j addObject:[NSNumber numberWithFloat:j]];
    }
}

-(void) calculateForWeek {
    if ([stockInfo.weeklyPrice count] == 0) {
        return;
    }
    NSInteger startIndex = 20;
    NSInteger needMinuteCount = (20 + self.calculateCount);
    NSMutableArray* needTreatArray = [[NSMutableArray alloc] init];
    
    if (self.calculateCount == MAX_COUNT) {
        needMinuteCount = [stockInfo.weeklyPrice count];
    }
    
    self.volValues = [[NSMutableArray alloc] init];
    NSInteger start = [stockInfo.weeklyPrice count]-needMinuteCount;
    if (start < 0) {
        start = 0;
    }
    for (NSInteger i=start; i<[stockInfo.weeklyPrice count]; i++) {
        NSMutableArray* array = [stockInfo.weeklyPrice objectAtIndex:i];
        if ([array count] == 4) {
            float curPrice = [[array objectAtIndex:2] floatValue];
            float open = [[array objectAtIndex:0] floatValue];
            float h = [[array objectAtIndex:1] floatValue];
            float l = [[array objectAtIndex:3] floatValue];
            if (h > self.highest) {
                self.highest = h;
            }
            if (l < self.lowest) {
                self.lowest = l;
            }
            [needTreatArray addObject:array];
            if ([stockInfo.weeklyVOL count] > i) {
                if (curPrice >= open) {
                    [self.volValues addObject:[stockInfo.weeklyVOL objectAtIndex:i]];
                } else {
                    NSInteger vol = [[stockInfo.weeklyVOL objectAtIndex:i] integerValue];
                    [self.volValues addObject:[NSNumber numberWithInteger:-1*vol]];
                }
            } else {
                [self.volValues addObject:[NSNumber numberWithInteger:0]];
            }
        }
    }
    startIndex = [needTreatArray count] - self.calculateCount;
    if (startIndex < 0) {
        startIndex = 0;
    }
    if (self.calculateCount == MAX_COUNT) {
        startIndex = 0;
    }
    [self calculateKDJ:needTreatArray andStartIndex:startIndex];
    self.priceKValues = needTreatArray;
    self.todayStartIndex = 0;
}

-(void) calculateForDay {
    if ([stockInfo.hundredDaysPrice count] == 0) {
        return;
    }
    NSInteger startIndex = 20;
    NSInteger needMinuteCount = (20 + self.calculateCount);
    NSMutableArray* needTreatArray = [[NSMutableArray alloc] init];
    
    if (self.calculateCount == MAX_COUNT) {
        needMinuteCount = [stockInfo.hundredDaysPrice count];
    }
    
    self.volValues = [[NSMutableArray alloc] init];
    NSInteger start = [stockInfo.hundredDaysPrice count]-needMinuteCount;
    if (start < 0) {
        start = 0;
    }
    for (NSInteger i=start; i<[stockInfo.hundredDaysPrice count]; i++) {
        NSMutableArray* array = [stockInfo.hundredDaysPrice objectAtIndex:i];
        if ([array count] == 4) {
            float curPrice = [[array objectAtIndex:2] floatValue];
            float open = [[array objectAtIndex:0] floatValue];
            float h = [[array objectAtIndex:1] floatValue];
            float l = [[array objectAtIndex:3] floatValue];
            if (h > self.highest) {
                self.highest = h;
            }
            if (l < self.lowest) {
                self.lowest = l;
            }
            [needTreatArray addObject:array];
            if ([stockInfo.hundredDaysVOL count] > i) {
                if (curPrice >= open) {
                    [self.volValues addObject:[stockInfo.hundredDaysVOL objectAtIndex:i]];
                } else {
                    NSInteger vol = [[stockInfo.hundredDaysVOL objectAtIndex:i] integerValue];
                    [self.volValues addObject:[NSNumber numberWithInteger:-1*vol]];
                }
            } else {
                [self.volValues addObject:[NSNumber numberWithInteger:0]];
            }
        }
    }
    startIndex = [needTreatArray count] - self.calculateCount;
    if (startIndex < 0) {
        startIndex = 0;
    }
    if (self.calculateCount == MAX_COUNT) {
        startIndex = 0;
    }
    [self calculateKDJ:needTreatArray andStartIndex:startIndex];
    self.priceKValues = needTreatArray;
    self.todayStartIndex = 0;
}

-(void) calculate {
    if ([stockInfo.fiveDayPriceByMinutes count] == 0) {
        return;
    }
    NSInteger startIndex = 20;
    NSInteger needMinuteCount = (20 + self.calculateCount) * delta;
    NSInteger needLastFiveDayCount = 0;
    if (self.calculateCount == MAX_COUNT) {
        needMinuteCount = [stockInfo.fiveDayPriceByMinutes count] + [stockInfo.todayPriceByMinutes count];
    }
    float prePrice = 0;
    if (needMinuteCount > [stockInfo.todayPriceByMinutes count]) {
        needLastFiveDayCount = needMinuteCount - [stockInfo.todayPriceByMinutes count];
    }
    NSMutableArray* priceMinute = [[NSMutableArray alloc] init];
    NSMutableArray* volMinute = [[NSMutableArray alloc] init];
    NSInteger start = [stockInfo.fiveDayPriceByMinutes count] - needLastFiveDayCount;
    if (start < 0) {
        start = 0;
    }
    for (NSInteger i = start; i<[stockInfo.fiveDayPriceByMinutes count]; i++) {
        [priceMinute addObject:[stockInfo.fiveDayPriceByMinutes objectAtIndex:i]];
        if ([stockInfo.fiveDayVOLByMinutes count] > i) {
            [volMinute addObject:[stockInfo.fiveDayVOLByMinutes objectAtIndex:i]];
        } else {
            [volMinute addObject:[NSNumber numberWithInteger:0]];
        }
    }
    if (start - 1 >= 0 && [stockInfo.fiveDayPriceByMinutes count] > start - 1) {
        NSNumber* number = [stockInfo.fiveDayPriceByMinutes objectAtIndex:start -1];
        prePrice = [number floatValue];
    } else {
        start = [stockInfo.todayPriceByMinutes count] - needMinuteCount;
        if (start -1 >= 0 && [stockInfo.todayPriceByMinutes count] > start - 1) {
            NSNumber* number = [stockInfo.todayPriceByMinutes objectAtIndex:start -1];
            prePrice = [number floatValue];
        }
    }
    start = [stockInfo.todayPriceByMinutes count] - needMinuteCount;
    if (start < 0) {
        start = 0;
    }
    for (NSInteger i=start; i<[stockInfo.todayPriceByMinutes count]; i++) {
        [priceMinute addObject:[stockInfo.todayPriceByMinutes objectAtIndex:i]];
        if ([stockInfo.todayVOLByMinutes count] > i) {
            [volMinute addObject:[stockInfo.todayVOLByMinutes objectAtIndex:i]];
        } else {
            [volMinute addObject:[NSNumber numberWithInteger:0]];
        }
    }
    if (prePrice == 0) {
        if ([priceMinute count] > 0) {
            NSNumber* number = [priceMinute objectAtIndex:0];
            prePrice = [number floatValue];
        }
    }
    NSMutableArray* needTreatArray = [[NSMutableArray alloc] init];
    self.volValues = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i<[priceMinute count];) {
        float h = -1;
        float c = 0;
        float l = 100000;
        NSInteger j = i;
        NSInteger volCount = 0;
        for (j=i; j<delta+i; j++) {
            if (j<[priceMinute count]) {
                NSNumber* price = [priceMinute objectAtIndex:j];
                NSNumber* vol = [volMinute objectAtIndex:j];
                volCount += [vol integerValue];
                if ([price floatValue] > h) {
                    h = [price floatValue];
                }
                if ([price floatValue] < l) {
                    l = [price floatValue];
                }
                c = [price floatValue];
            }
        }
        if (h > self.highest) {
            self.highest = h;
        }
        if (l < self.lowest) {
            self.lowest = l;
        }

        NSMutableArray* array = [[NSMutableArray alloc] init];
        [array addObject:[NSNumber numberWithFloat:prePrice]];
        [array addObject:[NSNumber numberWithFloat:h]]; // h
        [array addObject:[NSNumber numberWithFloat:c]]; // c
        [array addObject:[NSNumber numberWithFloat:l]]; // l
        [needTreatArray addObject:array];
        
        //VOL
        if (c >= prePrice) {
            [self.volValues addObject:[NSNumber numberWithInteger:volCount]];
        } else {
            [self.volValues addObject:[NSNumber numberWithInteger:-1*volCount]];
        }
        prePrice = c;
        
        i+=delta;
    }
    startIndex = [needTreatArray count] - self.calculateCount;
    if (startIndex < 0) {
        startIndex = 0;
    }
    if (self.calculateCount == MAX_COUNT) {
        startIndex = 0;
    }
    [self calculateKDJ:needTreatArray andStartIndex:startIndex];
    self.priceKValues = needTreatArray;
    self.todayStartIndex = [self.kdj_k count] - ([stockInfo.todayPriceByMinutes count]/delta);
    if (self.todayStartIndex < 0) {
        self.todayStartIndex = 0;
    }
}

-(void) run {
    if (delta == ONE_DAY) {
        [self calculateForDay];
    } else if (delta == ONE_WEEK) {
        [self calculateForWeek];
    } else {
        [self calculate];
    }
    if (self.onCompleteBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.onCompleteBlock(self);
        });
    }
}

@end
