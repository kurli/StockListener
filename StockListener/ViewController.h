//
//  ViewController.h
//  StockListener
//
//  Created by Guozhen Li on 11/26/15.
//  Copyright (c) 2015 Guangzhen Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StockPlayerManager.h"
#import "DatabaseHelper.h"

@interface ViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UISearchResultsUpdating, OnStockListChangedDelegate, StockPlayerDelegate> {
    StockPlayerManager* player;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;

@end

