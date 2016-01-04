//
//  SyncPoint.m
//  StockListener
//
//  Created by Guozhen Li on 1/4/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "SyncPoint.h"

@implementation SyncPoint

-(void) run {
    if (self.delegate) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate onStockValuesRefreshed];
        });
    }
    if (self.onCompleteBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.onCompleteBlock(nil);
        });
    }
}

@end
