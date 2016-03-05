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
    CalculateAVOLTypeWeeks
};

@class StockInfo;
@interface CalculateAVOL : KingdaTask

-(id) initWithStockInfo:(StockInfo*)info;
@property (copy) void (^onCompleteBlock)(NSMutableDictionary* dic);

@property (assign, nonatomic) CalculateAVOLType sourceType;
@property (atomic, strong) NSMutableDictionary* averageVolDic;
@end
