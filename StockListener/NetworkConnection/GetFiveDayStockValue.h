//
//  GetFiveDayStockValue.h
//  StockListener
//
//  Created by Guozhen Li on 1/5/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "ServerConnectionBase.h"

@interface GetFiveDayStockValue : ServerConnectionBase

-(id) initWithStock:(StockInfo*) info;

@end
