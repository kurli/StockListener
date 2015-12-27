//
//  DatabaseHelper.h
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SH_STOCK @"s_sh000001"
#define SZ_STOCK @"s_sz399001"
#define CY_STOCK @"s_sz399006"

@protocol OnStockListChangedDelegate <NSObject>
-(void)onStockListChanged;
@end

@class StockInfo;

@interface DatabaseHelper : NSObject

@property (nonatomic, assign) id <OnStockListChangedDelegate> delegate;

@property (atomic, strong) NSMutableArray* stockList;
@property (atomic, strong) NSMutableArray* dapanList;

-(void) reloadStockList;

-(void) addStockBySID:(NSString*)sid;
-(void) removeStockBySID:(NSString*)sid;
-(void) startRefreshStock;
-(void) stopRefreshStock;

-(StockInfo*)getInfoById:(NSString*)sid;
-(StockInfo*)getDapanInfoById:(NSString*)sid;

+(DatabaseHelper*) getInstance;

-(void) saveToDB;

-(void) clearStoredPriceData;

@end
