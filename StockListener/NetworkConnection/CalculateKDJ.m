//
//  CalculateKDJ.m
//  StockListener
//
//  Created by Guozhen Li on 1/6/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "CalculateKDJ.h"
#import "StockInfo.h"

@interface CalculateKDJ() {
    StockInfo* stockInfo;
    int delta;
}
@end

@implementation CalculateKDJ

-(id) initWithStockInfo:(StockInfo*)info andDelta:(int)_delta{
    if ((self = [super init]) != nil) {
        stockInfo = info;
        delta = _delta;
        self.kdj_k = [[NSMutableArray alloc] init];
        self.kdj_d = [[NSMutableArray alloc] init];
        self.kdj_j = [[NSMutableArray alloc] init];
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
        float h  = [[[data objectAtIndex:i] objectAtIndex:0] floatValue];
        float l = [[[data objectAtIndex:i] objectAtIndex:2] floatValue];
        float c = [[[data objectAtIndex:i] objectAtIndex:1] floatValue];
        if (i > 10) {
            for(NSInteger j=i;j>i-10;j--){
                if([[[data objectAtIndex:j] objectAtIndex:0] floatValue] > h){
                    h = [[[data objectAtIndex:j] objectAtIndex:0] floatValue];
                }
                
                if([[[data objectAtIndex:j] objectAtIndex:2] floatValue] < l){
                    l = [[[data objectAtIndex:j] objectAtIndex:2] floatValue];
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

-(void) calculateForDay {
    if ([stockInfo.hundredDaysPrice count] == 0) {
        return;
    }
    NSInteger startIndex = 20;
    NSInteger needMinuteCount = (20 + 35);
    NSMutableArray* needTreatArray = [[NSMutableArray alloc] init];
    NSInteger start = [stockInfo.hundredDaysPrice count]-needMinuteCount;
    if (start < 0) {
        start = 0;
    }
    for (NSInteger i=start; i<[stockInfo.hundredDaysPrice count]; i++) {
        NSMutableArray* array = [stockInfo.hundredDaysPrice objectAtIndex:i];
        [needTreatArray addObject:array];
    }
    startIndex = [needTreatArray count] - 35;
    if (startIndex < 0) {
        startIndex = 0;
    }
    [self calculateKDJ:needTreatArray andStartIndex:startIndex];
    self.priceKValues = needTreatArray;
    self.todayStartIndex = [self.kdj_k count]-2;
    if (self.todayStartIndex < 0) {
        self.todayStartIndex = 0;
    }
}

-(void) calculate {
    if ([stockInfo.fiveDayPriceByMinutes count] == 0) {
        return;
    }
    NSInteger startIndex = 20;
    NSInteger needMinuteCount = (20 + 35) * delta;
    NSInteger needLastFiveDayCount = 0;
    if (needMinuteCount > [stockInfo.todayPriceByMinutes count]) {
        needLastFiveDayCount = needMinuteCount - [stockInfo.todayPriceByMinutes count];
    }
    NSMutableArray* priceMinute = [[NSMutableArray alloc] init];
    NSInteger start = [stockInfo.fiveDayPriceByMinutes count] - needLastFiveDayCount;
    if (start < 0) {
        start = 0;
    }
    for (NSInteger i = start; i<[stockInfo.fiveDayPriceByMinutes count]; i++) {
        [priceMinute addObject:[stockInfo.fiveDayPriceByMinutes objectAtIndex:i]];
    }
    start = [stockInfo.todayPriceByMinutes count] - needMinuteCount;
    if (start < 0) {
        start = 0;
    }
    for (NSInteger i=start; i<[stockInfo.todayPriceByMinutes count]; i++) {
        [priceMinute addObject:[stockInfo.todayPriceByMinutes objectAtIndex:i]];
    }
    NSMutableArray* needTreatArray = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i<[priceMinute count];) {
        float h = -1;
        float c = 0;
        float l = 100000;
        NSInteger j = i;
        for (j=i; j<delta+i; j++) {
            if (j<[priceMinute count]) {
                NSNumber* price = [priceMinute objectAtIndex:j];
                if ([price floatValue] > h) {
                    h = [price floatValue];
                }
                if ([price floatValue] < l) {
                    l = [price floatValue];
                }
                c = [price floatValue];
            }
        }

        NSMutableArray* array = [[NSMutableArray alloc] init];
        [array addObject:[NSNumber numberWithFloat:h]]; // h
        [array addObject:[NSNumber numberWithFloat:c]]; // c
        [array addObject:[NSNumber numberWithFloat:l]]; // l
        [needTreatArray addObject:array];
        i+=delta;
    }
    startIndex = [needTreatArray count] - 35;
    if (startIndex < 0) {
        startIndex = 0;
    }
    [self calculateKDJ:needTreatArray andStartIndex:startIndex];
    self.priceKValues = needTreatArray;
    self.todayStartIndex = [self.kdj_k count] - ([stockInfo.todayPriceByMinutes count]/delta)-1;
    if (self.todayStartIndex < 0) {
        self.todayStartIndex = 0;
    }
}

-(void) run {
    if (delta == 240) {
        [self calculateForDay];
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
