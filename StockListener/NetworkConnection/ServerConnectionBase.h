//
//  ServerConnectionBase.h
//  SmartHome
//
//  Created by Guozhen Li on 2/4/15.
//  Copyright (c) 2015 LiGuozhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KingdaTask.h"

@class StockInfo;
@protocol GetStockValueDoneDelegate <NSObject>
-(void)onStockValuesRefreshed;
@end

@interface ServerConnectionBase : KingdaTask

@property (nonatomic, strong) NSString* mURL;
@property (nonatomic, assign) id <GetStockValueDoneDelegate> delegate;
@property (copy) void (^onCompleteBlock)(StockInfo*);
@property (nonatomic, strong) StockInfo* neededNewInfo;

-(void) post;

-(void) onComplete:(NSString*) data;

@end
