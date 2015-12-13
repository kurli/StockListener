//
//  DatabaseHelper.h
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OnStockListChangedDelegate <NSObject>
-(void)onStockListChanged;
@end

@class StockInfo;

@interface DatabaseHelper : NSObject

@property (nonatomic, assign) id <OnStockListChangedDelegate> delegate;

@property (atomic, strong) NSMutableArray* stockList;

-(void) reloadStockList;

-(void) addStockBySID:(NSString*)sid;
-(void) removeStockBySID:(NSString*)sid;
-(void) startRefreshStock;
-(void) stopRefreshStock;

-(StockInfo*)getInfoById:(NSString*)sid;

+(DatabaseHelper*) getInstance;

@end
