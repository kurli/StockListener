//
//  OrgnizedItem.h
//  StockListener
//
//  Created by Guozhen Li on 6/15/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ORGNIZED_TYPE_KLINE 0
#define ORGNIZED_TYPE_KDJ 1
#define ORGNIZED_TYPE_VOL 2
#define ORGNIZED_TYPE_NONE -1

@class KLineViewController;
@class AVOLChartViewController;
@class KDJViewController;
@class VOLChartViewController;

@interface OrgnizedItem : NSObject <NSCoding>

@property (nonatomic, strong) NSString* sid;
@property (nonatomic, unsafe_unretained) NSInteger type;
@property (nonatomic, unsafe_unretained) NSInteger delta;

@property (nonatomic, strong) KLineViewController* klineViewController;
@property (nonatomic, strong) AVOLChartViewController* aVolController;
@property (nonatomic, strong) KDJViewController* kdjViewController;
@property (nonatomic, strong) VOLChartViewController* volController;
@end
