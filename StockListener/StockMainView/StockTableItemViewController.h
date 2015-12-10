//
//  StockTableItemViewController.h
//  StockListener
//
//  Created by Guozhen Li on 12/10/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StockInfo;
@class StockPlayerManager;
@interface StockTableItemViewController : NSObject

@property (nonatomic, strong) NSString* nowPLayingSID;
@property (nonatomic, assign) UITableView* tableView;
@property (nonatomic, strong) StockPlayerManager* player;

-(UITableViewCell*) getTableViewCell:(UITableView*)tableView andInfo:(StockInfo*)info;
@end
