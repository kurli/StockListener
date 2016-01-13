//
//  SearchStockByKeyword.h
//  StockListener
//
//  Created by Guozhen Li on 1/13/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "ServerConnectionBase.h"

@interface SearchStockByKeyword : ServerConnectionBase

-(id) initWithKeyword:(NSString*) keyword;

@property (copy) void (^onStockListGotBlock)(NSArray*);

@end
