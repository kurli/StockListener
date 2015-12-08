//
//  SearchStockController.m
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "SearchStockController.h"

@implementation SearchStockController

-(void) search:(NSString*) key {
    if (self.searchList != nil) {
        [self.searchList removeAllObjects];
    } else {
        self.searchList = [[NSMutableArray alloc] init];
    }
    
    [self.searchList addObject:[NSString stringWithFormat:@"sz%@", key]];
    [self.searchList addObject:[NSString stringWithFormat:@"sh%@", key]];
}

@end
