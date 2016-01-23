//
//  GetDaysStockValue.m
//  StockListener
//
//  Created by Guozhen Li on 1/10/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "GetWeeksStockValue.h"
#import "StockInfo.h"

@interface GetWeeksStockValue() {
    NSInteger preCount;
    NSInteger preVOL;
}

@end

@implementation GetWeeksStockValue
-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.neededNewInfo = info;
        self.mURL =  [NSString stringWithFormat:@"http://data.gtimg.cn/flashdata/hushen/latest/weekly/%@.js", info.sid];
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
    float open;
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
        [self.neededNewInfo.weeklyPrice addObject:a];
        [self.neededNewInfo.weeklyVOL addObject:[NSNumber numberWithInteger:vol]];
    }
    if (preCount == [self.neededNewInfo.weeklyVOL count] && preVOL == vol) {
        NSInteger dateInt = [date integerValue];
        dateInt++;
        self.neededNewInfo.weeklyLastUpdateDay = [NSString stringWithFormat:@"%ld", dateInt];
    } else {
        self.neededNewInfo.weeklyLastUpdateDay = date;
    }
}

-(void) onComplete:(NSString *)data {
    if ([self.neededNewInfo.weeklyVOL count] > 0) {
        preVOL = [[self.neededNewInfo.weeklyVOL lastObject] integerValue];
        preCount = [self.neededNewInfo.weeklyVOL count];
    }
    if (self.neededNewInfo.weeklyPrice == nil) {
        self.neededNewInfo.weeklyPrice = [[NSMutableArray alloc] init];
    }
    [self.neededNewInfo.weeklyPrice removeAllObjects];
    if (self.neededNewInfo.weeklyVOL == nil) {
        self.neededNewInfo.weeklyVOL = [[NSMutableArray alloc] init];
    }
    [self.neededNewInfo.weeklyVOL removeAllObjects];
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
