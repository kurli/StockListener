//
//  CalculateAVOL.h
//  StockListener
//
//  Created by Guozhen Li on 1/18/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "KingdaTask.h"

typedef NS_ENUM(NSInteger, CalculateAVOLType) {
    CalculateAVOLTypeToday,
    CalculateAVOLTypeHistory
};

@class StockInfo;
@interface CalculateAVOL : KingdaTask

-(id) initWithStockInfo:(StockInfo*)info;
@property (copy) void (^onCompleteBlock)(NSMutableDictionary* dic);

@property (assign, nonatomic) CalculateAVOLType sourceType;
@property (atomic, strong) NSMutableDictionary* averageVolDic;
@property (assign, nonatomic) NSInteger endIndex;
@property (assign, nonatomic) NSInteger calType;
@property (strong, nonatomic) NSArray* fiveDayPrice;
@property (strong, nonatomic) NSArray* fiveDayVOL;
@end
