//
//  SearchStockController.m
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "SearchStockController.h"
#import "SearchStockByKeyword.h"
#import "KingdaWorker.h"

@implementation SearchStockController

-(void) search:(NSString*) key {
    if ([key length] == 0) {
        self.searchList = nil;
        return;
    }
    SearchStockByKeyword* task = [[SearchStockByKeyword alloc] initWithKeyword:key];
    task.onStockListGotBlock = ^(NSArray* array) {
        self.searchList = array;
        self.onStockListGotBlock();
    };
    self.searchList = nil;
    [[KingdaWorker getInstance] queue:task];
}

@end
