//
//  StockInfo.h
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StockInfo : NSObject <NSCopying, NSCoding>

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* sid;
@property (atomic, unsafe_unretained) float currentPrice;
@property (atomic, strong) NSString* updateTime;
@property (atomic, unsafe_unretained) float lastChangeRate;
@property (atomic, unsafe_unretained) int lastStep;
@property (atomic, unsafe_unretained) float changeRate;
@end