//
//  KLineSettingViewController.h
//  StockListener
//
//  Created by Guozhen Li on 1/19/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZSYPopoverListView.h"

@class StockInfo;
@interface KLineSettingViewController : UIViewController <ZSYPopoverListDatasource, ZSYPopoverListDelegate>

@property (nonatomic, strong) StockInfo* stockInfo;

@end
