//
//  GetDaysStockValue.m
//  StockListener
//
//  Created by Guozhen Li on 1/10/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "GetDaysStockValue.h"
#import "StockInfo.h"

@interface GetDaysStockValue() {
    NSInteger preCount;
    NSInteger preVOL;
}

@end

@implementation GetDaysStockValue
-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.neededNewInfo = info;
        self.mURL =  [NSString stringWithFormat:@"http://data.gtimg.cn/flashdata/hushen/latest/daily/%@.js", info.sid];
    }
    return self;
}

-(void) run {
    [self post];
}

-(void) parseData:(NSString*) data {
    NSArray* tmpArray = [data componentsSeparatedByString:@"\\n\\"];
    //160108 83.99 88.32 88.32 80.00 191607
    NSArray* array;
    NSString* date;
    float lowest;
    float highest;
    NSInteger vol = 0;
    float price;
    for (int i=2; i<[tmpArray count]; i++) {
        NSString* tmp = [tmpArray objectAtIndex:i];
        tmp = [tmp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        array = [tmp componentsSeparatedByString:@" "];
        if ([array count] < 6) {
            continue;
        }
        date = [array objectAtIndex:0];
        price = [[array objectAtIndex:2] floatValue];
        highest = [[array objectAtIndex:3] floatValue];
        lowest = [[array objectAtIndex:4] floatValue];
        vol = [[array objectAtIndex:5] integerValue];
        NSMutableArray* a = [[NSMutableArray alloc] init];
        [a addObject:[NSNumber numberWithFloat:highest]];
        [a addObject:[NSNumber numberWithFloat:price]];
        [a addObject:[NSNumber numberWithFloat:lowest]];
        [self.neededNewInfo.hundredDaysPrice addObject:a];
        [self.neededNewInfo.hundredDaysVOL addObject:[NSNumber numberWithInteger:vol]];
    }
    if (preCount == [self.neededNewInfo.hundredDaysVOL count] && preVOL == vol) {
        NSInteger dateInt = [date integerValue];
        dateInt++;
        self.neededNewInfo.hundredDayLastUpdateDay = [NSString stringWithFormat:@"%ld", dateInt];
    } else {
        self.neededNewInfo.hundredDayLastUpdateDay = date;
    }
    [self calculateAP];
}

//Calculate average price
//

-(void) calculateAP {
    if ([self.neededNewInfo.hundredDaysVOL count] != [self.neededNewInfo.hundredDaysPrice count]) {
        return;
    }
    
    float lowest = 100000;
    float delta = 0.01;
    for (int i=0; i<[self.neededNewInfo.hundredDaysPrice count]; i++) {
        NSArray* array = [self.neededNewInfo.hundredDaysPrice objectAtIndex:i];
        if ([array count] != 3) {
            continue;
        }
        float l = [[array objectAtIndex:2] floatValue];
        if (l < lowest) {
            lowest = l;
        }
    }
    if (lowest < 3) {
        delta = 0.001;
    }
    [self.neededNewInfo.averageVolDic removeAllObjects];
    for (int i=0; i<[self.neededNewInfo.hundredDaysPrice count]; i++) {
        NSArray* array = [self.neededNewInfo.hundredDaysPrice objectAtIndex:i];
//        NSArray* preArr = [self.neededNewInfo.hundredDaysPrice objectAtIndex:i-1];
        if ([array count] != 3) {
            continue;
        }
        NSInteger h = [[array objectAtIndex:0] floatValue] / delta;
        NSInteger l = [[array objectAtIndex:2] floatValue] / delta;
        NSInteger vol = [[self.neededNewInfo.hundredDaysVOL objectAtIndex:i] integerValue];

//        NSInteger c = [[array objectAtIndex:1] floatValue] / delta;
//        NSInteger pc = [[preArr objectAtIndex:1] floatValue] / delta;
//        if (c < pc) {
//            vol = -1*vol;
//        }

        NSInteger count = h - l;
        if (count == 0) {
            NSString* key = [NSString stringWithFormat:@"%ld", h];
            NSInteger preVol = [[self.neededNewInfo.averageVolDic objectForKey:key] integerValue];
            [self.neededNewInfo.averageVolDic setValue:[NSNumber numberWithInteger:preVol+vol] forKey:key];
        } else {
            NSInteger average = vol/count;
            for (NSInteger j=0; j<count; j++) {
                NSString* key = [NSString stringWithFormat:@"%ld", l+j];
                NSInteger preVol = [[self.neededNewInfo.averageVolDic objectForKey:key] integerValue];
                [self.neededNewInfo.averageVolDic setValue:[NSNumber numberWithInteger:preVol+average] forKey:key];
            }
        }
    }
}

-(void) onComplete:(NSString *)data {
    if ([self.neededNewInfo.hundredDaysVOL count] > 0) {
        preVOL = [[self.neededNewInfo.hundredDaysVOL lastObject] integerValue];
        preCount = [self.neededNewInfo.hundredDaysVOL count];
    }
    if (self.neededNewInfo.hundredDaysPrice == nil) {
        self.neededNewInfo.hundredDaysPrice = [[NSMutableArray alloc] init];
    }
    [self.neededNewInfo.hundredDaysPrice removeAllObjects];
    if (self.neededNewInfo.hundredDaysVOL == nil) {
        self.neededNewInfo.hundredDaysVOL = [[NSMutableArray alloc] init];
    }
    [self.neededNewInfo.hundredDaysVOL removeAllObjects];
    [self parseData:data];
    if (self.delegate) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate onStockValuesRefreshed];
        });
    }
    if (self.onCompleteBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.onCompleteBlock(self.neededNewInfo);
        });
    }
}

@end
