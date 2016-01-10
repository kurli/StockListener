//
//  CalculateKDJ.h
//  StockListener
//
//  Created by Guozhen Li on 1/6/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "KingdaTask.h"

@class StockInfo;
@interface CalculateKDJ : KingdaTask

-(id) initWithStockInfo:(StockInfo*)info andDelta:(int)delta;
@property (nonatomic, strong) NSMutableArray* kdj_k;
@property (nonatomic, strong) NSMutableArray* kdj_d;
@property (nonatomic, strong) NSMutableArray* kdj_j;
@property (nonatomic, strong) NSMutableArray* priceKValues;
@property (nonatomic, strong) NSMutableArray* volValues;
@property (nonatomic, unsafe_unretained) NSInteger todayStartIndex;
@property (copy) void (^onCompleteBlock)(CalculateKDJ* _self);
@end
