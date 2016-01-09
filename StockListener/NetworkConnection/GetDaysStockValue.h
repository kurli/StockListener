//
//  GetDaysStockValue.h
//  StockListener
//
//  Created by Guozhen Li on 1/10/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "ServerConnectionBase.h"

@interface GetDaysStockValue : ServerConnectionBase

-(id) initWithStock:(StockInfo*) info;

@end
