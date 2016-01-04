//
//  GetTodayStockValue.h
//  StockListener
//
//  Created by Guozhen Li on 1/4/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "ServerConnectionBase.h"

@interface GetTodayStockValue : ServerConnectionBase

-(id) initWithStock:(StockInfo*) info;

@end
