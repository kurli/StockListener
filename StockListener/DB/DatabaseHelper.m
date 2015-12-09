//
//  DatabaseHelper.m
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "DatabaseHelper.h"
#import "GetStockValueTask.h"
#import "StockPlayerManager.h"
#import "KingdaWorker.h"
#import "StockInfo.h"
#import "StockRefresher.h"

#define STOCK_LIST @"stock_list"

@interface DatabaseHelper() {
    
}
@property (nonatomic, strong) StockRefresher* stockRefresher;
@end

@implementation DatabaseHelper

-(id) init {
    if (self = [super init]) {
        [self reloadStockList];
        self.stockRefresher = [[StockRefresher alloc] init];
        [self.stockRefresher startRefresh:self];
    }
    return self;
}

-(void) reloadStockList {
    NSMutableArray* stockDBList = [[NSUserDefaults standardUserDefaults] objectForKey:STOCK_LIST];
    self.stockList = [[NSMutableArray alloc] init];
    for (NSData* data in stockDBList) {
        StockInfo* info = (StockInfo*)[NSKeyedUnarchiver unarchiveObjectWithData:data];
        [self.stockList addObject:info];
    }
}

-(void) addStockBySID:(NSString*)sid {
    for (int i=0; i<[self.stockList count]; i++) {
        StockInfo* info = [self.stockList objectAtIndex:i];
        if ([info.sid isEqualToString:sid]) {
            return;
        }
    }
    StockInfo* info = [[StockInfo alloc] init];
    info.sid = sid;
    GetStockValueTask* task = [[GetStockValueTask alloc] initWithStock:info];
    task.onCompleteBlock = ^(StockInfo* info) {
        [self.stockList addObject:info];

        [self saveToDB];
        if (self.delegate) {
            [self.delegate onStockListChanged];
        }
    };
    [[KingdaWorker getInstance] queue: task];
}

-(NSMutableArray*) stockListToDBList {
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (StockInfo* info in self.stockList) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:info];
        [array addObject:data];
    }
    return array;
}

-(void) saveToDB {
    NSMutableArray* array = [self stockListToDBList];
    [[NSUserDefaults standardUserDefaults] setObject:array forKey:STOCK_LIST];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void) removeStockBySID:(NSString*)sid {
    int i = 0;
    if ([self.stockList count] == 0) {
        return;
    }
    for (i=0; i<[self.stockList count]; i++) {
        StockInfo* info = [self.stockList objectAtIndex:i];
        if ([info.sid isEqualToString:sid]) {
            break;
        }
    }
    if (i != [self.stockList count]) {
        [self.stockList removeObjectAtIndex:i];
    }
    [self saveToDB];
    
    if (self.delegate) {
        [self.delegate onStockListChanged];
    }
}


@end
