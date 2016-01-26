//
//  GetFiveDayStockValue.m
//  StockListener
//
//  Created by Guozhen Li on 1/5/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "GetFiveDayStockValue.h"
#import "StockInfo.h"
#import "SBJSON.h"

@interface GetFiveDayStockValue() {
    NSInteger preCount;
    NSInteger preVOL;
}

@end

@implementation GetFiveDayStockValue

-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.neededNewInfo = info;
        NSString* prefix = @"sz";
        if ([info.sid length] == 8) {
            prefix = [info.sid substringToIndex:2];
        }
        self.mURL =  [NSString stringWithFormat:@"http://data.gtimg.cn/flashdata/hushen/4day/%@/%@.js", prefix, info.sid];
    }
    return self;
}

-(void) run {
    [self post];
}

-(NSInteger) parseDataValue:(NSString*) data {
    NSArray* array = [data componentsSeparatedByString:@"^"];
    NSInteger preVol = 0;
    NSInteger retVol = 0;
    float openPrice = 0;
    NSInteger openVOL = 0;
    for (int i=0; i<[array count]; i++) {
        NSString* tmp = [array objectAtIndex:i];
        NSArray* arr2 = [tmp componentsSeparatedByString:@"~"];
        if ([arr2 count] != 4) {
            break;
        }
        NSString* price = [arr2 objectAtIndex:1];
        NSInteger vol = [[arr2 objectAtIndex:2] integerValue];
        float value = [price floatValue];

        if (i == 0 || i == 121) {
            openPrice = value;
            openVOL = vol-preVol;
            retVol = openVOL;
        } else if (i == 1 || i == 122) {
            [self.neededNewInfo.fiveDayPriceByMinutes addObject:[NSNumber numberWithFloat:value]];
            retVol = openVOL+vol-preVol;
            [self.neededNewInfo.fiveDayVOLByMinutes addObject:[NSNumber numberWithInteger:openVOL+vol-preVol]];
        } else {
            [self.neededNewInfo.fiveDayPriceByMinutes addObject:[NSNumber numberWithFloat:value]];
            retVol = vol-preVol;
            [self.neededNewInfo.fiveDayVOLByMinutes addObject:[NSNumber numberWithInteger:vol-preVol]];
        }
        preVol = vol;
    }
    return retVol;
}

-(void) parseData:(NSString*) data {
    if ([data length] < 25) {
        return;
    }
    data = [data substringFromIndex:16];
    data = [data stringByReplacingOccurrencesOfString:@";" withString:@""];
    data = [data stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
    SBJsonParser* jsonParser = [[SBJsonParser alloc] init];
    id jsonObject = [jsonParser objectWithString:data];
    NSInteger vol = 0;
    NSString* date;
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray* jsonArray = (NSArray*) jsonObject;
        if ([jsonArray count] > 0) {
            id firstObj = [jsonObject objectAtIndex:0];
            if (![firstObj isKindOfClass:[NSDictionary class]]) {
                return;
            }
            NSDictionary* dictionary = (NSDictionary*)firstObj;
            date = [dictionary objectForKey:@"date"];
            for (NSInteger i=[jsonArray count]-1; i>=0; i--) {
                NSDictionary* dic = (NSDictionary*)[jsonArray objectAtIndex:i];
                NSString* str1 = [dic objectForKey:@"date"];
                if ([str1 isEqualToString:self.neededNewInfo.todayUpdateDay]) {
                    continue;
                }
                vol = [self parseDataValue:[dic objectForKey:@"data"]];
            }
        }
    }
    if (preCount == [self.neededNewInfo.fiveDayVOLByMinutes count] && preVOL == vol) {
        NSInteger dateInt = [date integerValue];
//        dateInt++;
        self.neededNewInfo.fiveDayLastUpdateDay = [NSString stringWithFormat:@"%ld", dateInt];
    } else {
        self.neededNewInfo.fiveDayLastUpdateDay = date;
    }
}

-(void) onComplete:(NSString *)data {
    if ([self.neededNewInfo.fiveDayVOLByMinutes count] > 0) {
        preVOL = [[self.neededNewInfo.fiveDayVOLByMinutes lastObject] integerValue];
        preCount = [self.neededNewInfo.fiveDayVOLByMinutes count];
    }
    if (self.neededNewInfo.fiveDayPriceByMinutes == nil) {
        self.neededNewInfo.fiveDayPriceByMinutes = [[NSMutableArray alloc] init];
    }
    if (self.neededNewInfo.fiveDayVOLByMinutes == nil) {
        self.neededNewInfo.fiveDayVOLByMinutes = [[NSMutableArray alloc] init];
    }
    [self.neededNewInfo.fiveDayPriceByMinutes removeAllObjects];
    [self.neededNewInfo.fiveDayVOLByMinutes removeAllObjects];
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
