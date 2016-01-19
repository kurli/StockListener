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

+(DatabaseHelper*) getInstance {
    static DatabaseHelper* shelper;
    if (shelper == nil) {
        shelper = [[DatabaseHelper alloc] init];
    }
    return shelper;
}

-(id) init {
    if (self = [super init]) {
        [self reloadStockList];
        self.stockRefresher = [[StockRefresher alloc] init];
        [self.stockRefresher startRefresh:self];
        
        StockInfo* info = nil;
        self.dapanList = [[NSMutableArray alloc] init];
        info = [[StockInfo alloc] init];
        info.sid = SH_STOCK;
        [self.dapanList addObject:info];
        info = [[StockInfo alloc] init];
        info.sid = SZ_STOCK;
        [self.dapanList addObject:info];
        info = [[StockInfo alloc] init];
        info.sid = CY_STOCK;
        [self.dapanList addObject:info];
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
    [self getNameASync:info];
}

-(void) getNameASync:(StockInfo*)info {
    GetStockValueTask* task = [[GetStockValueTask alloc] initWithStock:info];
    task.onCompleteBlock = ^(StockInfo* info) {
        if ([info.updateDay length] == 0) {
            if ([info.name length] == 1) {
                info.name = @" - ";
                if ([info.sid containsString:@"sz"]) {
                    info.sid = [info.sid stringByReplacingOccurrencesOfString:@"sz" withString:@"sh"];
                } else {
                    info.sid = [info.sid stringByReplacingOccurrencesOfString:@"sh" withString:@"sz"];
                }
                [self getNameASync:info];
                return;
            }
            return;
        }
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

- (void) startRefreshStock {
    [self.stockRefresher startRefresh:self];
}

- (void) stopRefreshStock {
    [self.stockRefresher stopRefreshStock];
}

-(StockInfo*)getInfoById:(NSString*)sid {
    for (int i=0; i<[self.stockList count]; i++) {
        StockInfo* info = [self.stockList objectAtIndex:i];
        if ([info.sid isEqualToString:sid]) {
            return info;
        }
    }
    return nil;
}

-(StockInfo*)getDapanInfoById:(NSString*)sid {
    StockInfo* dapanInfo = [self getInfoById:sid];
    if (dapanInfo != nil) {
        return dapanInfo;
    }
    for (int i=0; i<[self.dapanList count]; i++) {
        StockInfo* info = [self.dapanList objectAtIndex:i];
        if ([info.sid isEqualToString:sid]) {
            return info;
        }
    }
    return nil;
}

-(void) clearStoredPriceData {
//    for (StockInfo* info in self.stockList) {
//        [info.changeRateArray removeAllObjects];
//    }
//    for (StockInfo* info in self.dapanList) {
//        [info.changeRateArray removeAllObjects];
//    }
    for (StockInfo* info in self.stockList) {
        [info.todayPriceByMinutes removeAllObjects];
    }
    for (StockInfo* info in self.dapanList) {
        [info.todayPriceByMinutes removeAllObjects];
    }
}

@end
