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
    if ([neededNewInfo.weeklyVOL count] != [neededNewInfo.weeklyPrice count] || [neededNewInfo.weeklyPrice count] == 0) {
        return;
    }
    
    float lowest = 100000;
    float delta = 0.01;
    for (int i=0; i<[neededNewInfo.weeklyPrice count]; i++) {
        NSArray* array = [neededNewInfo.weeklyPrice objectAtIndex:i];
        if ([array count] != 4) {
            continue;
        }
        float l = [[array objectAtIndex:3] floatValue];
        if (l < lowest) {
            lowest = l;
        }
    }
    if (lowest < 3) {
        delta = 0.001;
    }
    if (lowest > 1000) {
        delta = 1;
    }
    [neededNewInfo.averageVolDic removeAllObjects];
    for (int i=0; i<[neededNewInfo.weeklyPrice count]; i++) {
        NSArray* array = [neededNewInfo.weeklyPrice objectAtIndex:i];
        //        NSArray* preArr = [neededNewInfo.hundredDaysPrice objectAtIndex:i-1];
        if ([array count] != 4) {
            continue;
        }
        NSInteger h = [[array objectAtIndex:1] floatValue] / delta;
        NSInteger l = [[array objectAtIndex:3] floatValue] / delta;
        NSInteger vol = [[neededNewInfo.weeklyVOL objectAtIndex:i] integerValue];
        
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
