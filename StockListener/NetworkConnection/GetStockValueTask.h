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
@protocol GetStockValueDoneDelegate <NSObject>
-(void)onStockValuesRefreshed;
@end

@interface GetStockValueTask : ServerConnectionBase {
}

@property (copy) void (^onCompleteBlock)(StockInfo*);
@property (nonatomic, assign) id <GetStockValueDoneDelegate> delegate;

-(id) initWithStocks:(NSArray*) infos;
-(id) initWithStock:(StockInfo*) info;

@end
