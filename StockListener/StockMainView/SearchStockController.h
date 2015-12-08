//
//  SearchStockController.h
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchStockController : NSObject

@property(nonatomic, strong) NSMutableArray* searchList;

-(void) search:(NSString*) key;
@end
