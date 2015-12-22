//
//  StockDetailViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/16/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockDetailViewController.h"
#import "DatabaseHelper.h"
#import "StockInfo.h"

@interface StockDetailViewController ()

@end

@implementation StockDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) deleteClicked:(id)b {
    [[DatabaseHelper getInstance] removeStockBySID:self.stockInfo.sid];
//    [_buySellViewDictionary removeObjectForKey:info.sid];
}

@end
