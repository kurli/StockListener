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

@interface DatabaseHelper : NSObject

@property (nonatomic, assign) id <OnStockListChangedDelegate> delegate;

@property (nonatomic, strong) NSMutableArray* stockList;

-(void) reloadStockList;

-(void) addStockBySID:(NSString*)sid;
-(void) removeStockBySID:(NSString*)sid;
- (void) startRefreshStock;
- (void) stopRefreshStock;

@end
