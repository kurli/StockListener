//
//  UserLoginTask.m
//  SmartHome
//
//  Created by LiGuozhen on 15-2-4.
//  Copyright (c) 2015年 LiGuozhen. All rights reserved.
//

#import "GetStockValueTask.h"
#import <CommonCrypto/CommonDigest.h>
#import "StockPlayerManager.h"
#import "StockInfo.h"

//#define ENABLE_TEST 

@interface GetStockValueTask()

@property (nonatomic, strong) NSMutableString* ids;
#ifdef ENABLE_TEST
@property (nonatomic, strong) NSArray* arrayTest;
#endif
@end

@implementation GetStockValueTask

-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.ids = [[NSMutableString alloc] init];
        [self.ids appendString:info.name];
#ifdef ENABLE_TEST
        self.arrayTest = [[NSArray alloc] initWithObjects:@"27.47", @"27.1", @"27.96", @"28.23", @"28.38", @"28.5", @"28.45", @"28.15", @"27.66", @"27.95", @"27.22", @"26.84", @"26", @"25.75", @"24.76", nil];
#endif
    }
    return self;
}

-(id) initWithStocks:(NSArray*) infos {
    if ((self = [super init]) != nil) {
        self.ids = [[NSMutableString alloc] init];
        for (StockInfo* info in infos) {
            [self.ids appendFormat:@"%@,", info.sid];
        }
        #ifdef ENABLE_TEST
        self.arrayTest = [[NSArray alloc] initWithObjects:@"27.47", @"27.1", @"27.96", @"28.23", @"28.38", @"28.5", @"28.45", @"28.15", @"27.66", @"27.95", @"27.22", @"26.84", @"26", @"25.75", @"24.76", nil];
        #endif
    }
    return self;
}

-(void) run {
    [self post:self.ids];
}

-(StockInfo*) parseValueForSina:(NSString*)str {
    if (str == nil) {
        return nil;
    }

    NSRange range = [str rangeOfString:@"var hq_str_"];
    if (range.location == NSNotFound) {
        return nil;
    }
    NSRange equalRange = [str rangeOfString:@"="];
    if (equalRange.location == NSNotFound) {
        return nil;
    }
    NSRange sIDRange = NSMakeRange(range.location + range.length, equalRange.location - range.length - range.location);
    
    NSString* sid = [str substringWithRange:sIDRange];
    
    range.location = sIDRange.location + sIDRange.length + 2;
    NSString* subStr = [str substringFromIndex:range.location];
    NSArray* array = [subStr componentsSeparatedByString:@","];
    if ([array count] < 32) {
        return nil;
    }
    StockInfo* info = [[StockInfo alloc] init];
    info.sid = sid;
    NSString* price = [array objectAtIndex:3];
    info.currentPrice = [price floatValue];
    float lastDayValue = [[array objectAtIndex:2] floatValue];
    info.changeRate = (info.currentPrice - lastDayValue) / lastDayValue;
    #ifdef ENABLE_TEST
    static int count =0;
    count = count % [self.arrayTest count];
    info.currentPrice = [[self.arrayTest objectAtIndex:count] floatValue];
    count++;
    info.changeRate = (info.currentPrice - 28) / 27.51;
    #endif
    NSString* updateTime = [array objectAtIndex:31];
    info.updateTime = updateTime;
    info.name = [array objectAtIndex:0];
    return info;
}

-(void) onComplete:(NSString *)data {
    NSArray* array = [data componentsSeparatedByString:@";"];
    if ([array count] == 0) {
        return;
    }
    NSMutableArray* stockArray = [[NSMutableArray alloc] init];
    for (NSString* str in array) {
        StockInfo* info = [self parseValueForSina:str];
        if (info != nil) {
            [stockArray addObject:info];
        }
    }

    if (self.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            StockInfo* info = nil;
            if ([stockArray count] != 0) {
                info = [stockArray objectAtIndex:0];
            }
            [self.delegate onStockValueGot:info andError:nil];
            [self.delegate onStockValuesRefreshed:stockArray];
        });
    }
    if (self.onCompleteBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            StockInfo* info = nil;
            if ([stockArray count] != 0) {
                info = [stockArray objectAtIndex:0];
            }
            self.onCompleteBlock(info);
        });
    }
}

@end
