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

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation StockDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *path = [NSString stringWithFormat:@"http://stocks.sina.cn/sh/?code=%@&vt=4", self.stockInfo.sid];
    NSURL* url = [NSURL URLWithString:path];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
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

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeLeft;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL) shouldAutorotate {
    return NO;
}

@end
