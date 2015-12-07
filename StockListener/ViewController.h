//
//  ViewController.h
//  StockListener
//
//  Created by Guozhen Li on 11/26/15.
//  Copyright (c) 2015 Guangzhen Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StockPlayerManager.h"
@interface ViewController : UIViewController {
    StockPlayerManager* player;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;

@end

