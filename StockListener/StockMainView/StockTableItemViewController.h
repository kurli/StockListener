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
@class DatabaseHelper;

@interface StockTableItemViewController : NSObject

@property (nonatomic, strong) NSString* nowPLayingSID;
@property (nonatomic, assign) UITableView* tableView;
@property (nonatomic, strong) StockPlayerManager* player;
@property (nonatomic, strong) DatabaseHelper* dbHelper;
@property (nonatomic, strong) UIViewController* viewController;

-(UITableViewCell*) getTableViewCell:(UITableView*)tableView andInfo:(StockInfo*)info andSelected:(BOOL)selected;
@end
