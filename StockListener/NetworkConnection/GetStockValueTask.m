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

@property (nonatomic, strong) StockInfo* info;
#ifdef ENABLE_TEST
@property (nonatomic, strong) NSArray* arrayTest;
#endif
@end

@implementation GetStockValueTask

-(id) initWithStock:(StockInfo*) info {
    if ((self = [super init]) != nil) {
        self.info = [info copy];
        #ifdef ENABLE_TEST
        self.arrayTest = [[NSArray alloc] initWithObjects:@"27.47", @"27.1", @"27.96", @"28.23", @"28.38", @"28.5", @"28.45", @"28.15", @"27.66", @"27.95", @"27.22", @"26.84", @"26", @"25.75", @"24.76", nil];
        #endif
    }
    return self;
}

-(void) run {
    [self post:self.info];
}

-(BOOL) parseValueForSina:(NSString*)str {
    if (str == nil) {
        return NO;
    }
    if (self.info == nil) {
        return NO;
    }
    NSString* flag = [NSString stringWithFormat:@"var hq_str_%@=", self.info.sid];
    NSRange range = [str rangeOfString:flag];
    if (range.location == NSNotFound) {
        return NO;
    }
    range.location = range.length + 1;
    range.length = [str length] - (range.length + 1) - 1;
    NSString* subStr = [str substringWithRange:range];
    NSArray* array = [subStr componentsSeparatedByString:@","];
    if ([array count] < 32) {
        return NO;
    }
    NSString* price = [array objectAtIndex:3];
    self.info.currentPrice = [price floatValue];
    float lastDayValue = [[array objectAtIndex:2] floatValue];
    self.info.changeRate = (self.info.currentPrice - lastDayValue) / lastDayValue;
    #ifdef ENABLE_TEST
    static int count =0;
    count = count % [self.arrayTest count];
    self.info.currentPrice = [[self.arrayTest objectAtIndex:count] floatValue];
    count++;
    self.info.changeRate = (self.info.currentPrice - 28) / 27.51;
    #endif
    NSString* updateTime = [array objectAtIndex:31];
    self.info.updateTime = updateTime;
    self.info.name = [array objectAtIndex:0];
    return YES;
}

-(void) onComplete:(NSString *)data {
    BOOL succeed = [self parseValueForSina:data];
    NSString* error = nil;
    if (!succeed) {
        error = @"网络错误";
    }
    if (self.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onStockValueGot:self.info andError:error];
        });
    } else if (self.onCompleteBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onCompleteBlock(self.info);
        });
    }
}

@end
