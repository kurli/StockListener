//
//  BuySellHistoryViewController.m
//  StockListener
//
//  Created by Guozhen Li on 1/13/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "BuySellHistoryViewController.h"
#import "ADTickerLabel.h"
#import "StockInfo.h"
#import "StockRefresher.h"
#import "DatabaseHelper.h"
#import "StockPlayerManager.h"

#define PRICE_TYPE_WITHOUT_TAX 0
#define PRICE_TYPE_WITH_TAX 1

#define REALTIME 0
#define MANUAL 1

#define TAG_PRICE 4
#define TAG_DEAL_COUNT 1
#define TAG_EARN 2
#define TAG_TAX 3
#define TAG_RATE 5
#define TAG_DEAL_PRICE 6

#define PRE_EARN_FLAG -12321

#define TYPE_BUY 0
#define TYPE_SELL 1

@interface BuySellHistoryViewController ()<UITableViewDelegate,UITableViewDataSource> {
    ZSYPopoverListView* stockListView;
    float stockBaseValue;
}
@property (nonatomic, strong) StockInfo* stockInfo;

@property (nonatomic, strong) ADTickerLabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UIButton *stockNameButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *priceType;
@property (weak, nonatomic) IBOutlet UITextField *price;
@property (weak, nonatomic) IBOutlet UITextField *dealCount;
@property (weak, nonatomic) IBOutlet UILabel *totalStockCount;
@property (weak, nonatomic) IBOutlet UILabel *totalStockPrice;
@property (weak, nonatomic) IBOutlet UILabel *profit;
@property (weak, nonatomic) IBOutlet UITextField *simulatePrice;
@property (weak, nonatomic) IBOutlet UITextField *simulateRate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *realtimeSegment;
@property (weak, nonatomic) IBOutlet UIView *simulateView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *buySellTypeSegment;
@property (weak, nonatomic) IBOutlet UILabel *buySellInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *buySellInfo2Label;
@property (weak, nonatomic) IBOutlet UIButton *buySellButton;
@end

@implementation BuySellHistoryViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    float appWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
    UIToolbar *accessoryView = [[UIToolbar alloc]
                                initWithFrame:CGRectMake(0, 0, appWidth, 0.1 * appWidth)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                              target:nil
                              action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(selectDoneButton)];
    accessoryView.items = @[space, done];
    self.price.inputAccessoryView = accessoryView;
    self.dealCount.inputAccessoryView = accessoryView;
    self.simulatePrice.inputAccessoryView = accessoryView;
    self.simulateRate.inputAccessoryView = accessoryView;
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = view;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStockValueRefreshed)
                                                 name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                               object:nil];
//    self.edgesForExtendedLayout = UIRectEdgeAll;
//    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0f);
}

- (void)selectDoneButton {
    [self.price resignFirstResponder];
    [self.dealCount resignFirstResponder];
    [self.simulateRate resignFirstResponder];
    [self.simulatePrice resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.stockInfo == nil) {
        StockInfo* info = [[StockPlayerManager getInstance] getCurrentPlayingInfo];
        if (info == nil) {
            if ([[DatabaseHelper getInstance].stockList count] > 0) {
                info = [[DatabaseHelper getInstance].stockList objectAtIndex:0];
            }
        }
        self.stockInfo = info;
    }
    [self.stockNameButton setTitle:self.stockInfo.name forState:UIControlStateNormal];
    
    [self onStockValueRefreshed];
    UIFont *font = [UIFont boldSystemFontOfSize: 20];
    
    if (self.priceLabel == nil) {
        self.priceLabel = [[ADTickerLabel alloc] initWithFrame: CGRectMake(0, 32, 0, font.lineHeight)];
        self.priceLabel.font = font;
        self.priceLabel.characterWidth = 22;
        self.priceLabel.changeTextAnimationDuration = 0.5;
        [self.view addSubview: self.priceLabel];
    }
    
    if ([self.simulatePrice.text floatValue] == 0) {
        [self updateSimulateView];
        [self updatePriceViews];
    }
    
    [self updatePriceIfNull];

    [self.tableView reloadData];
}

-(void) dealloc {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:STOCK_VALUE_REFRESHED_NOTIFICATION object:nil];
}

- (IBAction)onStockButtonClicked:(id)sender {
    stockListView = [[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 250, 350)];
    stockListView.datasource = self;
    stockListView.titleName.text = @"请选择";
    stockListView.delegate = self;
    [stockListView show];
}

-(void) updatePriceIfNull {
    if ([self.price.text floatValue] == 0) {
        NSString* price = @"";
        if (self.stockInfo.price > 3) {
            price = [NSString stringWithFormat:@"%.2f", self.stockInfo.price];
        } else {
            price = [NSString stringWithFormat:@"%.3f", self.stockInfo.price];
        }
        self.price.text = price;
    }
}

-(void) updateSimulateView {
//    CGRect rect = self.tableView.frame;
//    float segmentBaseline = self.realtimeSegment.frame.origin.y+ self.realtimeSegment.frame.size.height + 5;
//    float manualViewBaseline = segmentBaseline + 50;
    if (self.realtimeSegment.selectedSegmentIndex == REALTIME) {
//        [self.simulateView setHidden:YES];
//        rect.origin.y = segmentBaseline;
//        rect.size.height = self.view.frame.size.height - segmentBaseline - 55;
//        [self.tableView setFrame:rect];
        
        NSString* price = @"";
        if (self.stockInfo.price > 3) {
            price = [NSString stringWithFormat:@"%.2f", self.stockInfo.price];
        } else {
            price = [NSString stringWithFormat:@"%.3f", self.stockInfo.price];
        }
        [self.simulatePrice setText:price];
        stockBaseValue = self.stockInfo.lastDayPrice;
        NSString* rate;
        if (self.stockInfo.changeRate < 0) {
            rate = [NSString stringWithFormat:@"%.2f", self.stockInfo.changeRate * 100];
        } else {
            rate = [NSString stringWithFormat:@"%.2f", self.stockInfo.changeRate * 100];
        }
        self.simulateRate.text = rate;
        
        [self.simulateRate setEnabled:NO];
        [self.simulatePrice setEnabled:NO];
        [self.simulateRate setBackgroundColor:[UIColor lightGrayColor]];
        [self.simulatePrice setBackgroundColor:[UIColor lightGrayColor]];
    } else {
//        [self.simulateView setHidden:NO];
//        rect.origin.y = manualViewBaseline;
//        rect.size.height = self.view.frame.size.height - manualViewBaseline - 55;
//        [self.tableView setFrame:rect];
        [self.simulateRate setEnabled:YES];
        [self.simulatePrice setEnabled:YES];
        [self.simulateRate setBackgroundColor:[UIColor whiteColor]];
        [self.simulatePrice setBackgroundColor:[UIColor whiteColor]];
    }
}

-(void) updatePriceViews {
    NSString* price = @"";
    if (self.stockInfo.price > 3) {
        price = [NSString stringWithFormat:@"%.2f", self.stockInfo.price];
    } else {
        price = [NSString stringWithFormat:@"%.3f", self.stockInfo.price];
    }
    [self.price setText:price];
}

- (IBAction)stockPriceSub:(id)sender {
    NSString* priceStr = self.price.text;
    float price = [priceStr floatValue];
    float delta = 0.01;
    if (price < 3) {
        delta = 0.001;
    }
    price-=delta;
    if (price <= 0) {
        return;
    }
    if (price < 3) {
        self.price.text = [NSString stringWithFormat:@"%.3f", price];
    } else {
        self.price.text = [NSString stringWithFormat:@"%.2f", price];
    }
    [self onBuySellTypeChanged:nil];
}

- (IBAction)stockPriceAdd:(id)sender {
    NSString* priceStr = self.price.text;
    float price = [priceStr floatValue];
    float delta = 0.01;
    if (price < 3) {
        delta = 0.001;
    }
    price+=delta;
    if (price < 3) {
        self.price.text = [NSString stringWithFormat:@"%.3f", price];
    } else {
        self.price.text = [NSString stringWithFormat:@"%.2f", price];
    }
    [self onBuySellTypeChanged:nil];
}

- (IBAction)dealCountSub:(id)sender {
    NSString* dealCountStr = self.dealCount.text;
    NSInteger dealCount = [dealCountStr integerValue];
    dealCount = dealCount/100 * 100;
    dealCount -= 100;
    if (dealCount < 0) {
        return;
    }
    self.dealCount.text = [NSString stringWithFormat:@"%ld", dealCount];
    [self onBuySellTypeChanged:nil];
}

- (IBAction)dealCountAdd:(id)sender {
    NSString* dealCountStr = self.dealCount.text;
    NSInteger dealCount = [dealCountStr integerValue];
    dealCount = dealCount/100 * 100;
    dealCount += 100;
    if (dealCount < 0) {
        return;
    }
    self.dealCount.text = [NSString stringWithFormat:@"%ld", dealCount];
    [self onBuySellTypeChanged:nil];
}

- (IBAction)simulatePriceSub:(id)sender {
    if (self.realtimeSegment.selectedSegmentIndex == REALTIME) {
        return;
    }
    NSString* priceStr = self.simulatePrice.text;
    float price = [priceStr floatValue];
    float delta = 0.01;
    if (price < 3) {
        delta = 0.001;
    }
    price-=delta;
    if (price <= 0) {
        return;
    }
    if (price < 3) {
        self.simulatePrice.text = [NSString stringWithFormat:@"%.3f", price];
    } else {
        self.simulatePrice.text = [NSString stringWithFormat:@"%.2f", price];
    }
    // Update rate
    if (stockBaseValue > 0) {
        float newRate = (price - stockBaseValue)/stockBaseValue;
        self.simulateRate.text = [NSString stringWithFormat:@"%.2f", newRate*100];
    }
    [self showTotalLabels];
    [self.tableView reloadData];
}

- (IBAction)simulatePriceAdd:(id)sender {
    if (self.realtimeSegment.selectedSegmentIndex == REALTIME) {
        return;
    }
    NSString* priceStr = self.simulatePrice.text;
    float price = [priceStr floatValue];
    float delta = 0.01;
    if (price < 3) {
        delta = 0.001;
    }
    price+=delta;
    if (price < 3) {
        self.simulatePrice.text = [NSString stringWithFormat:@"%.3f", price];
    } else {
        self.simulatePrice.text = [NSString stringWithFormat:@"%.2f", price];
    }
    // Update rate
    if (stockBaseValue > 0) {
        float newRate = (price - stockBaseValue)/stockBaseValue;
        self.simulateRate.text = [NSString stringWithFormat:@"%.2f", newRate*100];
    }
    [self showTotalLabels];
    [self.tableView reloadData];
}

- (IBAction)simulateRateSub:(id)sender {
    if (self.realtimeSegment.selectedSegmentIndex == REALTIME) {
        return;
    }
    NSString* priceStr = self.simulateRate.text;
    float rate = [priceStr floatValue];
    rate-=0.01;
    self.simulateRate.text = [NSString stringWithFormat:@"%.2f", rate];
    // Update price
    if (stockBaseValue > 0) {
        float newPrice = rate*stockBaseValue/100 + stockBaseValue;
        if (newPrice < 3) {
            self.simulatePrice.text = [NSString stringWithFormat:@"%.3f", newPrice];
        } else {
            self.simulatePrice.text = [NSString stringWithFormat:@"%.2f", newPrice];
        }
    }
    [self showTotalLabels];
    [self.tableView reloadData];
}

- (IBAction)simulateRateAdd:(id)sender {
    if (self.realtimeSegment.selectedSegmentIndex == REALTIME) {
        return;
    }
    NSString* priceStr = self.simulateRate.text;
    float rate = [priceStr floatValue];
    rate+=0.01;
    self.simulateRate.text = [NSString stringWithFormat:@"%.2f", rate];
    // Update price
    if (stockBaseValue > 0) {
        float newPrice = rate/100*stockBaseValue + stockBaseValue;
        if (newPrice < 3) {
            self.simulatePrice.text = [NSString stringWithFormat:@"%.3f", newPrice];
        } else {
            self.simulatePrice.text = [NSString stringWithFormat:@"%.2f", newPrice];
        }
    }
    [self showTotalLabels];
    [self.tableView reloadData];
}

- (IBAction)simulatePriceEndEditing:(id)sender {
    if (self.realtimeSegment.selectedSegmentIndex == REALTIME) {
        return;
    }
    NSString* priceStr = self.simulatePrice.text;
    float price = [priceStr floatValue];
    if (price <= 0) {
        self.simulateRate.text = @"0";
    }
    // Update rate
    if (stockBaseValue > 0) {
        float newRate = (price - stockBaseValue)/stockBaseValue;
        self.simulateRate.text = [NSString stringWithFormat:@"%.2f", newRate*100];
    }
    [self showTotalLabels];
    [self.tableView reloadData];
}

- (IBAction)simulateRateEndEditing:(id)sender {
    if (self.realtimeSegment.selectedSegmentIndex == REALTIME) {
        return;
    }
    NSString* priceStr = self.simulateRate.text;
    float rate = [priceStr floatValue];
    // Update price
    if (stockBaseValue > 0) {
        float newPrice = rate/100*stockBaseValue + stockBaseValue;
        if (newPrice < 3) {
            self.simulatePrice.text = [NSString stringWithFormat:@"%.3f", newPrice];
        } else {
            self.simulatePrice.text = [NSString stringWithFormat:@"%.2f", newPrice];
        }
    }
    [self showTotalLabels];
    [self.tableView reloadData];
}

- (IBAction)buyPriceEndEditing:(id)sender {
    [self onBuySellTypeChanged:nil];
}

- (IBAction)dealCountEndEditing:(id)sender {
    NSInteger dealCount = [self.dealCount.text integerValue];
    dealCount = dealCount/100 * 100;
    self.dealCount.text = [NSString stringWithFormat:@"%ld", dealCount];
    
    [self onBuySellTypeChanged:nil];
}

- (IBAction)realtimeChanged:(id)sender {
    [self updateSimulateView];
    [self showTotalLabels];
    [self.tableView reloadData];
}

- (void)onStockValueRefreshed {
    if (self.stockInfo == nil) {
        return;
    }
    
    NSString* price = @"";
    if (self.stockInfo.price > 3) {
        price = [NSString stringWithFormat:@"%.2f", self.stockInfo.price];
    } else {
        price = [NSString stringWithFormat:@"%.3f", self.stockInfo.price];
    }
    self.priceLabel.text = price;
    CGRect rect = self.priceLabel.frame;
    rect.origin.x = self.view.frame.size.width/2 - (rect.size.width/2);
    [self.priceLabel setCenter:CGPointMake(self.view.frame.size.width/2, self.stockNameButton.frame.origin.y + self.stockNameButton.frame.size.height/2)];
    
    NSString* rate;
    if (self.stockInfo.changeRate < 0) {
        [self.rateLabel setTextColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:1]];
        [self.priceLabel setTextColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:1]];
        rate = [NSString stringWithFormat:@"%.2f%%", self.stockInfo.changeRate * 100];
    } else {
        [self.rateLabel setTextColor:[UIColor whiteColor]];
        [self.priceLabel setTextColor:[UIColor whiteColor]];
        rate = [NSString stringWithFormat:@"+%.2f%%", self.stockInfo.changeRate * 100];
    }
    self.rateLabel.text = rate;
    
    // Will check realtime flag inside
    [self updateSimulateView];
    
    [self showTotalLabels];
    [self.tableView reloadData];
}

#pragma mark -

- (NSInteger)popoverListView:(ZSYPopoverListView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[DatabaseHelper getInstance].stockList count];
}

- (UITableViewCell *)popoverListView:(ZSYPopoverListView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"identifier";
    UITableViewCell *cell = [tableView dequeueReusablePopoverCellWithIdentifier:identifier];
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:indexPath.row];
    if ([info.sid isEqualToString:self.stockInfo.sid])
    {
        cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"selection_normal.png"];
    }
    cell.textLabel.text = info.name;
    return cell;
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView popoverCellForRowAtIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
    StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:indexPath.row];
    self.stockInfo = info;
    [self.stockNameButton setTitle:info.name forState:UIControlStateNormal];
    [self onStockValueRefreshed];
    [stockListView dismiss];
    
    [self updatePriceViews];
    [self updateSimulateView];
    [self.tableView reloadData];
}

#pragma mark -

-(void) showTotalLabels {
    if ([self.stockInfo.buySellHistory count] == 0) {
        self.totalStockCount.text = @"-";
        self.totalStockPrice.text = @"-";
        self.profit.text = @"-";
        return;
    }
    NSInteger totalDealCount = 0;
    float buyTotalPrice = 0;
    float curPrice = [self.simulatePrice.text floatValue];
    float totalBuyTax = 0;
    float preEarn = 0;
    for (int i=0; i<[self.stockInfo.buySellHistory count]; i++) {
        NSString* data = [self.stockInfo.buySellHistory objectAtIndex:i];
        NSArray* array = [data componentsSeparatedByString:@":"];
        if ([array count] == 2) {
            float price = [[array objectAtIndex:0] floatValue];
            float dealCount = [[array objectAtIndex:1] integerValue];
            if (dealCount < 0) {
                continue;
            }
            if (price == PRE_EARN_FLAG) {
                float dealCount = [[array objectAtIndex:1] floatValue];
                preEarn += dealCount;
                continue;
            }
            totalDealCount += dealCount;
            buyTotalPrice += (price*dealCount);
            float tax = [self.stockInfo getTaxForBuy:price andDealCount:dealCount];
            totalBuyTax += tax;
        }
    }
    float tax = 0;
    if (totalDealCount != 0) {
        tax = [self.stockInfo getTaxForSell:curPrice andDealCount:totalDealCount];
    }
    float sellTotalPrice = 0;
    sellTotalPrice += (totalDealCount * curPrice - tax - totalBuyTax);
    self.totalStockCount.text = [NSString stringWithFormat:@"%ld", totalDealCount];
    self.totalStockPrice.text = [NSString stringWithFormat:@"%.2f", sellTotalPrice];
    if (buyTotalPrice != 0) {
        self.profit.text = [NSString stringWithFormat:@"%.2f %.2f%%", sellTotalPrice-buyTotalPrice + preEarn, (sellTotalPrice-buyTotalPrice+preEarn)/buyTotalPrice];
    } else {
        self.profit.text = [NSString stringWithFormat:@"%.2f", sellTotalPrice-buyTotalPrice + preEarn];
    }
}

-(void) removeLastSellItem {
    if ([self.stockInfo.buySellHistory count] > 0) {
        NSString* str = [self.stockInfo.buySellHistory lastObject];
        NSArray* array = [str componentsSeparatedByString:@":"];
        if ([array count] == 2) {
            float price = [[array objectAtIndex:0] floatValue];
            if (price > 0) {
                NSInteger dealCount = [[array objectAtIndex:1] integerValue];
                if (dealCount < 0) {
                    [self.stockInfo.buySellHistory removeLastObject];
                }
            }
        }
    }
}

- (void)showBuyForBSI2 {
    float price = [self.price.text floatValue];
    NSInteger dealCount = [self.dealCount.text integerValue];
    if (price == 0 || dealCount == 0 || [self.stockInfo.sid length] < 3) {
        self.buySellInfo2Label.text = @"";
        return;
    }
    float curPrice = [self.simulatePrice.text floatValue];
    
    float tax = [self.stockInfo getTaxForBuy:price andDealCount:dealCount];
    self.buySellInfoLabel.text = [NSString stringWithFormat:@"金额:%.2f", price*dealCount+tax];
    tax += [self.stockInfo getTaxForSell:curPrice andDealCount:dealCount];
    price = tax/(float)dealCount + price;

    if (price < 3) {
        self.buySellInfo2Label.text = [NSString stringWithFormat:@"保本价:%.3f", price];
    } else {
        self.buySellInfo2Label.text = [NSString stringWithFormat:@"保本价:%.2f", price];
    }
}

- (void)showSellForBSI2 {
    float price = [self.price.text floatValue];
    NSInteger dealCount = [self.dealCount.text integerValue];
    if (price == 0 || dealCount == 0 || [self.stockInfo.sid length] < 3) {
        self.buySellInfo2Label.text = @"";
        return;
    }
    float tax = [self.stockInfo getTaxForSell:price andDealCount:dealCount];
    self.buySellInfoLabel.text = [NSString stringWithFormat:@"金额:%.2f", price*dealCount+tax];
    self.buySellInfo2Label.text = [NSString stringWithFormat:@"税:%.2f", tax];
}

- (IBAction)onBuySellTypeChanged:(id)sender {
    if (self.buySellTypeSegment.selectedSegmentIndex == TYPE_BUY) {
        [self showBuyForBSI2];
        [self.buySellButton setTitle:@"买入了" forState:UIControlStateNormal];
    } else {
        [self showSellForBSI2];
        [self.buySellButton setTitle:@"卖出了" forState:UIControlStateNormal];
    }
}

- (IBAction)onBuySellConfirmClicked:(id)sender {
    if (self.buySellTypeSegment.selectedSegmentIndex == TYPE_BUY) {
        [self buyClicked:nil];
    } else {
        [self sellClicked:nil];
    }
    [self showTotalLabels];
}

- (IBAction)buyClicked:(id)sender {
    float price = [self.price.text floatValue];
    if (price <= 0) {
        return;
    }
    NSInteger dealCount = [self.dealCount.text integerValue];
    if (dealCount == 0 || dealCount%100 != 0) {
        return;
    }
    if (self.stockInfo == nil) {
        return;
    }
    
    [self removeLastSellItem];
    
    NSString* storeData = [NSString stringWithFormat:@"%f:%ld", price, dealCount];
    [self.stockInfo.buySellHistory addObject:storeData];
    [self.tableView reloadData];
    self.dealCount.text = @"";
}

- (IBAction)sellClicked:(id)sender {
    float price = [self.price.text floatValue];
    if (price <= 0) {
        return;
    }
    NSInteger dealCount = [self.dealCount.text integerValue];
    if (dealCount == 0 || dealCount%100 != 0) {
        return;
    }
    if (self.stockInfo == nil) {
        return;
    }
    
    // Check whether can sell
    NSInteger totalStockDealCount = 0;
    for (int i=0; i<[self.stockInfo.buySellHistory count]; i++) {
        NSString* str = [self.stockInfo.buySellHistory objectAtIndex:i];
        NSArray* array = [str componentsSeparatedByString:@":"];
        if ([array count] == 2) {
            float price = [[array objectAtIndex:0] floatValue];
            if (price != PRE_EARN_FLAG) {
                NSInteger dealCount = [[array objectAtIndex:1] integerValue];
                if (dealCount > 0) {
                    totalStockDealCount += dealCount;
                }
            }
        }
    }
    if (dealCount > totalStockDealCount) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"没有这么多可卖的股票" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
        // optional - add more buttons:
        [alert show];
        return;
    }
    // Check ended

    // Remove last sell item
    [self removeLastSellItem];

    BOOL _continue = YES;
    float prePrice = 0;
    NSInteger needDealCount = dealCount;
    float preEarn = 0;
    while (_continue) {
        if ([self.stockInfo.buySellHistory count] == 0) {
            break;
        }
        NSString* preData = [self.stockInfo.buySellHistory lastObject];
        if (preData != nil) {
            NSArray* array = [preData componentsSeparatedByString:@":"];
            if ([array count] == 2) {
                //Valid data
                prePrice = [[array objectAtIndex:0] floatValue];
                NSInteger preDealCount = [[array objectAtIndex:1] integerValue];
                if (prePrice == PRE_EARN_FLAG) {
                    // It's final, break
                    _continue = NO;
                    continue;
                }
                if (needDealCount == 0) {
                    // Sold, calculate this item
                    float delta = preEarn / preDealCount;
                    prePrice -= delta;
                    [self.stockInfo.buySellHistory removeLastObject];
                    
                    NSString* data = @"";
                    if (price > 3) {
                        data = [NSString stringWithFormat:@"%.2f:%ld", prePrice, preDealCount];
                    } else {
                        data = [NSString stringWithFormat:@"%.3f:%ld", prePrice, preDealCount];
                    }
                    [self.stockInfo.buySellHistory addObject:data];
                    preEarn = 0;
                    _continue = NO;
                    break;
                }
                if (preDealCount > 0) {
                    //Pre data is buy
                    NSInteger remaining = needDealCount - preDealCount;
                    if (remaining >= 0) {
                        // Sell this one, and continue sell
                        float tax = [self.stockInfo getTaxForSell:price andDealCount:preDealCount];
                        tax += [self.stockInfo getTaxForBuy:prePrice andDealCount:preDealCount];
                        preEarn += ((price - prePrice) * preDealCount);
                        preEarn -= tax;
                        [self.stockInfo.buySellHistory removeLastObject];
                        needDealCount = needDealCount - preDealCount;
                        _continue = YES;
                        continue;
                    } else {
                        // Sell part of this one
                        float tax = [self.stockInfo getTaxForSell:price andDealCount:needDealCount];
                        tax += ([self.stockInfo getTaxForBuy:prePrice andDealCount:preDealCount] * needDealCount/preDealCount);
                        preEarn += (price - prePrice) * needDealCount;
                        preEarn -= tax;
                        preDealCount = preDealCount - needDealCount;

                        float delta = preEarn / preDealCount;
                        prePrice -= delta;
                        [self.stockInfo.buySellHistory removeLastObject];
                        
                        NSString* data = @"";
                        if (price > 3) {
                            data = [NSString stringWithFormat:@"%.2f:%ld", prePrice, preDealCount];
                        } else {
                            data = [NSString stringWithFormat:@"%.3f:%ld", prePrice, preDealCount];
                        }
                        [self.stockInfo.buySellHistory addObject:data];
                        preEarn = 0;
                        _continue = NO;
                        continue;
                    }
                } else if (preDealCount < 0) {
                    // Pre data is sell, remove this one, and continue
                    [self.stockInfo.buySellHistory removeLastObject];
                    _continue = YES;
                    continue;
                } else {
                    // Invalid data remove
                    [self.stockInfo.buySellHistory removeLastObject];
                    _continue = YES;
                    continue;
                }
            } else {
                //Invalid data, remove this and continue
                [self.stockInfo.buySellHistory removeLastObject];
                _continue = YES;
                continue;
            }
        } else {
            _continue = NO;
            continue;
        }
    }
    
    NSString* storeData = [NSString stringWithFormat:@"%f:%ld", price,  -1*dealCount];
    [self.stockInfo.buySellHistory addObject:storeData];
    
    if (preEarn != 0) {
        // FLAG for pre earn
        float earn = 0;
        if ([self.stockInfo.buySellHistory count] > 0) {
            NSString* lastStr = [self.stockInfo.buySellHistory objectAtIndex:0];
            NSArray* array = [lastStr componentsSeparatedByString:@":"];
            if ([array count] == 2) {
                float p = [[array objectAtIndex:0] floatValue];
                float e = [[array objectAtIndex:1] floatValue];
                if (p == PRE_EARN_FLAG) {
                    earn = e;
                }
            }
        }
        ////
        NSLog(@"====");
        for (int i=0; i<[self.stockInfo.buySellHistory count]; i++) {
            NSLog(@"%@", [self.stockInfo.buySellHistory objectAtIndex:i]);
        }
        NSLog(@"====");
        ////
        [self.stockInfo.buySellHistory removeAllObjects];
        NSString* storeData = [NSString stringWithFormat:@"%d:%f", PRE_EARN_FLAG, preEarn + earn];
        [self.stockInfo.buySellHistory addObject:storeData];
        [self.tableView reloadData];
        self.dealCount.text = @"";
        return;
    }
    [self.tableView reloadData];
    self.dealCount.text = @"";
}

#pragma mark -
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.stockInfo.buySellHistory count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *flag=@"BuySellItemFlag";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:flag];
    //    BuySellChartViewController* buySellController = nil;
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BuySellItemView" owner:self options:nil] lastObject];
        [cell setValue:flag forKey:@"reuseIdentifier"];
    }
    UILabel* priceLabel = [cell viewWithTag:TAG_PRICE];
    UILabel* dealCountLabel = [cell viewWithTag:TAG_DEAL_COUNT];
    UILabel* earnLabel = [cell viewWithTag:TAG_EARN];
    UILabel* taxLabel = [cell viewWithTag:TAG_TAX];
    UILabel* rateLabel = [cell viewWithTag:TAG_RATE];
    UILabel* dealPriceLabel = [cell viewWithTag:TAG_DEAL_PRICE];
    
    NSInteger count = [self.stockInfo.buySellHistory count];
    NSString* str = [self.stockInfo.buySellHistory objectAtIndex:count-1-indexPath.row];
    NSArray* array = [str componentsSeparatedByString:@":"];
    float price = 0;
    NSInteger dealCount = 0;
    if ([array count] == 2) {
        price = [[array objectAtIndex:0] floatValue];
        dealCount = [[array objectAtIndex:1] integerValue];
        // Treat last earn flag
        if (price == PRE_EARN_FLAG) {
            float earn = [[array objectAtIndex:1] floatValue];
            priceLabel.text = @"前期利润:";
            dealPriceLabel.text = [NSString stringWithFormat:@"%.2f", earn];
            dealCountLabel.text = @"-";
            earnLabel.text = @"-";
            rateLabel.text = @"-";
            taxLabel.text = @"-";
            return cell;
        }
    }

    float tax = 0;
    float calPrice = [self.simulatePrice.text floatValue];
    if ([self.stockInfo.sid length] > 3 && dealCount > 0) {
        tax = [self.stockInfo getTaxForBuy:price andDealCount:dealCount];
        taxLabel.text = [NSString stringWithFormat:@"约%.2f", tax];
        tax += [self.stockInfo getTaxForSell:calPrice andDealCount:dealCount];

        price = tax/(float)dealCount + price;
    } else {
        taxLabel.text = @"-";
    }

    if (price > 3) {
        priceLabel.text = [NSString stringWithFormat:@"%.2f", price];
    } else {
        priceLabel.text = [NSString stringWithFormat:@"%.3f", price];
    }
    dealCountLabel.text = [NSString stringWithFormat:@"%ld", dealCount];
    
    if (dealCount < 0) {
        tax = [self.stockInfo getTaxForSell:calPrice andDealCount:-1*dealCount];
        taxLabel.text = [NSString stringWithFormat:@"约%.2f", tax];
        earnLabel.text = @"-";
        rateLabel.text = @"-";
        dealPriceLabel.text = @"-";
        return cell;
    }
    
    float earn = 0;
    float rate = 0;
    if (calPrice != 0) {
        earn = (calPrice - price) * dealCount;
        rate = earn / (price * dealCount);
    }
    
    earnLabel.text = [NSString stringWithFormat:@"%.2f", earn];
    if (price > 0) {
        rateLabel.text = [NSString stringWithFormat:@"%.2f%%", rate*100];
    } else {
        rateLabel.text = @"-";
    }
    if (earn > 0) {
        [earnLabel setTextColor:[UIColor redColor]];
        [rateLabel setTextColor:[UIColor redColor]];
    } else {
        [earnLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
        [rateLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    }
    dealPriceLabel.text = [NSString stringWithFormat:@"%.2f", calPrice*dealCount-tax];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        NSInteger index = indexPath.row;
        index = [self.stockInfo.buySellHistory count] - index - 1;
        if (index >= 0 && index < [self.stockInfo.buySellHistory count]) {
            [self.stockInfo.buySellHistory removeObjectAtIndex:index];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}
@end
