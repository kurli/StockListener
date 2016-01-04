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

@interface StockTableItemViewController : NSObject

@property (nonatomic, strong) NSString* nowPLayingSID;
@property (nonatomic, assign) UITableView* tableView;
@property (nonatomic, strong) UIViewController* viewController;

-(UITableViewCell*) getTableViewCell:(UITableView*)tableView andInfo:(StockInfo*)info andSelected:(BOOL)selected;
@end
