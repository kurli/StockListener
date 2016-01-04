//
//  UserLoginTask.h
//  SmartHome
//
//  Created by LiGuozhen on 15-2-4.
//  Copyright (c) 2015年 LiGuozhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerConnectionBase.h"

@class StockInfo;

@interface GetStockValueTask : ServerConnectionBase {
}

-(id) initWithStocks:(NSArray*) infos;
-(id) initWithStock:(StockInfo*) info;

@end
