//
//  CalculateAVOL.m
//  StockListener
//
//  Created by Guozhen Li on 1/18/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "CalculateAVOL.h"
#import "StockInfo.h"

@implementation CalculateAVOL{
    StockInfo* neededNewInfo;
}

-(id) initWithStockInfo:(StockInfo*)info{
    if ((self = [super init]) != nil) {
        neededNewInfo = info;
    }
    return self;
}

-(void) calculateAP {
    if ([neededNewInfo.hundredDaysVOL count] != [neededNewInfo.hundredDaysPrice count]) {
        return;
    }
    
    float lowest = 100000;
    float delta = 0.01;
    for (int i=0; i<[neededNewInfo.hundredDaysPrice count]; i++) {
        NSArray* array = [neededNewInfo.hundredDaysPrice objectAtIndex:i];
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
    [neededNewInfo.averageVolDic removeAllObjects];
    for (int i=0; i<[neededNewInfo.hundredDaysPrice count]; i++) {
        NSArray* array = [neededNewInfo.hundredDaysPrice objectAtIndex:i];
        //        NSArray* preArr = [neededNewInfo.hundredDaysPrice objectAtIndex:i-1];
        if ([array count] != 3) {
            continue;
        }
        NSInteger h = [[array objectAtIndex:0] floatValue] / delta;
        NSInteger l = [[array objectAtIndex:2] floatValue] / delta;
        NSInteger vol = [[neededNewInfo.hundredDaysVOL objectAtIndex:i] integerValue];
        
        //        NSInteger c = [[array objectAtIndex:1] floatValue] / delta;
        //        NSInteger pc = [[preArr objectAtIndex:1] floatValue] / delta;
        //        if (c < pc) {
        //            vol = -1*vol;
        //        }
        
        NSInteger count = h - l;
        if (count == 0) {
            NSString* key = [NSString stringWithFormat:@"%ld", h];
            NSInteger preVol = [[neededNewInfo.averageVolDic objectForKey:key] integerValue];
            [neededNewInfo.averageVolDic setValue:[NSNumber numberWithInteger:preVol+vol] forKey:key];
        } else {
            NSInteger average = vol/count;
            for (NSInteger j=0; j<count; j++) {
                NSString* key = [NSString stringWithFormat:@"%ld", l+j];
                NSInteger preVol = [[neededNewInfo.averageVolDic objectForKey:key] integerValue];
                [neededNewInfo.averageVolDic setValue:[NSNumber numberWithInteger:preVol+average] forKey:key];
            }
        }
    }
}

-(void) run {
    [self calculateAP];
    if (self.onCompleteBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.onCompleteBlock();
        });
    }
}

@end
