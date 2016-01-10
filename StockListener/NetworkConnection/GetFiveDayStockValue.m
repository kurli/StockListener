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

@implementation GetFiveDayStockValue

-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.neededNewInfo = info;
        self.mURL =  [NSString stringWithFormat:@"http://data.gtimg.cn/flashdata/hushen/4day/sz/%@.js", info.sid];
    }
    return self;
}

-(void) run {
    [self post];
}

-(void) parseDataValue:(NSString*) data {
    NSArray* array = [data componentsSeparatedByString:@"^"];
    NSInteger preVol = 0;
    for (int i=0; i<[array count]; i++) {
        NSString* tmp = [array objectAtIndex:i];
        NSArray* arr2 = [tmp componentsSeparatedByString:@"~"];
        if ([arr2 count] != 4) {
            break;
        }
        NSString* price = [arr2 objectAtIndex:1];
        NSInteger vol = [[arr2 objectAtIndex:2] integerValue];
        float value = [price floatValue];
        [self.neededNewInfo.fiveDayPriceByMinutes addObject:[NSNumber numberWithFloat:value]];
        [self.neededNewInfo.fiveDayVOLByMinutes addObject:[NSNumber numberWithInteger:vol-preVol]];
        preVol = vol;
    }
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
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray* jsonArray = (NSArray*) jsonObject;
        if ([jsonArray count] > 0) {
            id firstObj = [jsonObject objectAtIndex:0];
            if (![firstObj isKindOfClass:[NSDictionary class]]) {
                return;
            }
            NSDictionary* dictionary = (NSDictionary*)firstObj;
            self.neededNewInfo.fiveDayLastUpdateDay = [dictionary objectForKey:@"date"];
            for (NSInteger i=[jsonArray count]-1; i>=0; i--) {
                NSDictionary* dic = (NSDictionary*)[jsonArray objectAtIndex:i];
                NSString* str1 = [dic objectForKey:@"date"];
//                NSLog(@"%@ %@", str1, self.neededNewInfo.todayUpdateDay);
                if ([str1 isEqualToString:self.neededNewInfo.todayUpdateDay]) {
                    continue;
                }
                [self parseDataValue:[dic objectForKey:@"data"]];
            }
        }
    }
}

-(void) onComplete:(NSString *)data {
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
