//
//  GetTodayStockValue.m
//  StockListener
//
//  Created by Guozhen Li on 1/4/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "GetTodayStockValue.h"
#import "StockInfo.h"

@implementation GetTodayStockValue

-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.neededNewInfo = info;
        self.mURL =  [NSString stringWithFormat:@"http://data.gtimg.cn/flashdata/hushen/minute/%@.js", info.sid];
    }
    return self;
}

-(void) run {
    [self post];
}

-(void) parseData:(NSString*) data {
    NSArray* array = [data componentsSeparatedByString:@"\\n\\"];
    if ([array count] < 2) {
        return;
    }
    NSString* str = [array objectAtIndex:1];
    if ([str length] < 11) {
        return;
    }
    NSString* str2 = [str substringWithRange:NSMakeRange(6, 6)];
    self.neededNewInfo.todayUpdateDay = str2;
    NSInteger preVol = 0;
    float openPrice = 0;
    NSInteger openVOL = 0;
    for (int i=2; i<[array count]; i++) {
        NSString* tmp = [array objectAtIndex:i];
        tmp = [tmp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSArray* tmpArray = [tmp componentsSeparatedByString:@" "];
        if ([tmpArray count] != 3) {
            return;
        }
        NSString* valueStr = [tmpArray objectAtIndex:1];
        NSInteger vol = [[tmpArray objectAtIndex:2] integerValue];
        float value = [valueStr floatValue];
        if (i == 2 || i == 123) {
            openPrice = value;
            openVOL = vol-preVol;
        } else if (i == 3 || i == 124) {
            [self.neededNewInfo.todayPriceByMinutes addObject:[NSNumber numberWithFloat:value]];
            [self.neededNewInfo.todayVOLByMinutes addObject:[NSNumber numberWithInteger:openVOL+vol-preVol]];
        } else {
            [self.neededNewInfo.todayPriceByMinutes addObject:[NSNumber numberWithFloat:value]];
            [self.neededNewInfo.todayVOLByMinutes addObject:[NSNumber numberWithInteger:vol-preVol]];
        }
        preVol = vol;
    }
}

-(void) onComplete:(NSString *)data {
    if (self.neededNewInfo.todayPriceByMinutes == nil) {
        self.neededNewInfo.todayPriceByMinutes = [[NSMutableArray alloc] init];
    }
    if (self.neededNewInfo.todayVOLByMinutes == nil) {
        self.neededNewInfo.todayVOLByMinutes = [[NSMutableArray alloc] init];
    }
    [self.neededNewInfo.todayPriceByMinutes removeAllObjects];
    [self.neededNewInfo.todayVOLByMinutes removeAllObjects];
    [self parseData:data];
    if (self.delegate) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate onStockValuesRefreshed];
        });
    }
    if (self.onCompleteBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            //            StockInfo* info = [[DatabaseHelper getInstance] getInfoById:self.ids];
            //            if (info == nil) {
            //                info = _neededNewInfo;
            //            }
            self.onCompleteBlock(self.neededNewInfo);
        });
    }
}
@end
