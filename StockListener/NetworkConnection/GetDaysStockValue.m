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
    float open;
    for (int i=2; i<[tmpArray count]; i++) {
        NSString* tmp = [tmpArray objectAtIndex:i];
        tmp = [tmp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        array = [tmp componentsSeparatedByString:@" "];
        if ([array count] < 6) {
            continue;
        }
        date = [array objectAtIndex:0];
        open = [[array objectAtIndex:1] floatValue];
        price = [[array objectAtIndex:2] floatValue];
        highest = [[array objectAtIndex:3] floatValue];
        lowest = [[array objectAtIndex:4] floatValue];
        vol = [[array objectAtIndex:5] integerValue];
        NSMutableArray* a = [[NSMutableArray alloc] init];
        [a addObject:[NSNumber numberWithFloat:open]];
        [a addObject:[NSNumber numberWithFloat:highest]];
        [a addObject:[NSNumber numberWithFloat:price]];
        [a addObject:[NSNumber numberWithFloat:lowest]];
        [self.neededNewInfo.hundredDaysPrice addObject:a];
        [self.neededNewInfo.hundredDaysVOL addObject:[NSNumber numberWithInteger:vol]];
    }
    if (preCount == [self.neededNewInfo.hundredDaysVOL count] && preVOL == vol) {
        NSInteger dateInt = [date integerValue];
//        dateInt++;
        self.neededNewInfo.hundredDayLastUpdateDay = [NSString stringWithFormat:@"%ld", dateInt];
    } else {
        self.neededNewInfo.hundredDayLastUpdateDay = date;
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
