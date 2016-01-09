//
//  StockKDJViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/22/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockKDJViewController.h"
#import "StockInfo.h"
#import "PNLineChartView.h"
#import "StockRefresher.h"
#import "PNPlot.h"
#import "ADTickerLabel.h"
#import "StockDetailViewController.h"
#import "BuySellChartViewController.h"
#import "ZSYPopoverListView.h"
#import "DatabaseHelper.h"
#import "StockPlayerManager.h"
#import "GetTodayStockValue.h"
#import "KingdaWorker.h"
#import "SyncPoint.h"
#import "GetFiveDayStockValue.h"
#import "CalculateKDJ.h"
#import "KingdaWorker.h"
#import "GetDaysStockValue.h"

#define MAX_SHOW_HALF_MINUTE 30
#define MAX_SHOW_ONE_MINUTE 30
#define MAX_SHOW_FIVE_MINUTE 24
#define LEFT_PADDING 20

#define MAX_

@interface StockKDJViewController (){
    PNLineChartView *kdjChartView;
    PNLineChartView *kLineChartView;
    PNLineChartView *priceChartView;
    BuySellChartViewController* buySellController;
    ZSYPopoverListView* stockListView;
    NSInteger preSegment;
    NSInteger todayStartIndex;
}
@property (nonatomic, strong) NSMutableArray* kdj_k;
@property (nonatomic, strong) NSMutableArray* kdj_d;
@property (nonatomic, strong) NSMutableArray* kdj_j;
@property (nonatomic, strong) NSMutableArray* priceKValues;
@property (nonatomic, strong) ADTickerLabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UIButton *stockNameButton;
@property (weak, nonatomic) IBOutlet UILabel *shValue;
@property (weak, nonatomic) IBOutlet UILabel *szValue;
@property (weak, nonatomic) IBOutlet UILabel *chuangValue;
@property (weak, nonatomic) IBOutlet UISegmentedControl *kdjTypeSegment;
@property (weak, nonatomic) IBOutlet UIView *averagePriceView;
@property (weak, nonatomic) IBOutlet UILabel *fiveAPrice;
@property (weak, nonatomic) IBOutlet UILabel *tenAPrice;
@property (weak, nonatomic) IBOutlet UILabel *twentyAPrice;
@end

@implementation StockKDJViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.kdj_k = [[NSMutableArray alloc] init];
        self.kdj_d = [[NSMutableArray alloc] init];
        self.kdj_j = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:STOCK_VALUE_REFRESHED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:STOCK_PLAYER_STETE_NOTIFICATION object:nil];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    UIFont *font = [UIFont boldSystemFontOfSize: 20];
    
    if (self.priceLabel == nil) {
        self.priceLabel = [[ADTickerLabel alloc] initWithFrame: CGRectMake(0, 32, 0, font.lineHeight)];
        self.priceLabel.font = font;
        self.priceLabel.characterWidth = 22;
        self.priceLabel.changeTextAnimationDuration = 0.5;
        [self.view addSubview: self.priceLabel];
    }

    priceChartView = [[PNLineChartView alloc] init];
    [priceChartView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:priceChartView];
    
    kLineChartView = [[PNLineChartView alloc] init];
    [kLineChartView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:kLineChartView];
    
    kdjChartView = [[PNLineChartView alloc] init];
    [kdjChartView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:kdjChartView];
    
    self.averagePriceView.layer.borderWidth = 0.5;
    self.averagePriceView.layer.borderColor = [[UIColor grayColor] CGColor];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPlayerStatusChanged:)
                                                 name:STOCK_PLAYER_STETE_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStockValueRefreshed)
                                                 name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                               object:nil];

    if (self.stockInfo == nil) {
        StockInfo* info = [[StockPlayerManager getInstance] getCurrentPlayingInfo];
        if (info == nil) {
            if ([[DatabaseHelper getInstance].stockList count] > 0) {
                info = [[DatabaseHelper getInstance].stockList objectAtIndex:0];
            }
        }
        self.stockInfo = info;
        [self.stockNameButton setTitle:info.name forState:UIControlStateNormal];
    }
    [self.stockNameButton setTitle:self.stockInfo.name forState:UIControlStateNormal];
    
    [self onStockValueRefreshed];
    
    if (self.view.frame.size.width > self.view.frame.size.height) {
        return;
    }
    
    int offsetY = self.rateLabel.frame.size.height + self.rateLabel.frame.origin.y + 20;
    [priceChartView setFrame:CGRectMake(0, offsetY, self.view.frame.size.width/7*6, 150)];
    
    if (buySellController == nil) {
        buySellController = [[BuySellChartViewController alloc] initWithParentView:self.view];
        CGRect rect = CGRectMake(self.view.frame.size.width/7*6, offsetY, self.view.frame.size.width/7, 150);
        [buySellController loadViewVertical:rect];
    }

    CGRect aRect = self.averagePriceView.frame;
    
    CGRect rect = self.kdjTypeSegment.frame;
    rect.origin.y = priceChartView.frame.origin.y + priceChartView.frame.size.height+1;
    rect.origin.x = 1;
    rect.size.width = self.view.frame.size.width - aRect.size.width;
    [self.kdjTypeSegment setFrame:rect];

    aRect.origin.x = rect.origin.x + rect.size.width;
    aRect.origin.y = priceChartView.frame.origin.y + priceChartView.frame.size.height+1;
    [self.averagePriceView setFrame:aRect];

    [kLineChartView setFrame:CGRectMake(0, rect.origin.y + rect.size.height+1, self.view.frame.size.width/7*6, 130)];
    [kdjChartView setFrame:CGRectMake(0, rect.origin.y + rect.size.height + 131, self.view.frame.size.width/7*6, 100)];

    [self refreshData];
}

-(void) refreshData {
    BOOL needSync = YES;
    StockInfo* shInfo = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    StockInfo* szInfo = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    StockInfo* cyInfo = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    if ([shInfo.todayPriceByMinutes count] < 3 || [self.stockInfo.todayPriceByMinutes count] < 3
        || [shInfo.todayPriceByMinutes count] - [self.stockInfo.todayPriceByMinutes count] > 2) {
        GetTodayStockValue* task = [[GetTodayStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task];
        GetTodayStockValue* task2 = [[GetTodayStockValue alloc] initWithStock:shInfo];
        GetTodayStockValue* task3 = [[GetTodayStockValue alloc] initWithStock:szInfo];
        GetTodayStockValue* task4 = [[GetTodayStockValue alloc] initWithStock:cyInfo];
        [[KingdaWorker getInstance] queue:task2];
        [[KingdaWorker getInstance] queue:task3];
        [[KingdaWorker getInstance] queue:task4];
        needSync = YES;
    }
    
//    NSDate* date = [NSDate date];
//    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
//    [dateformatter setDateFormat:@"YYMMdd"];
//    NSString* dateStr =[dateformatter stringFromDate:date];
//    NSInteger intValue = [dateStr integerValue];
    NSString* str = [self.stockInfo.updateDay stringByReplacingOccurrencesOfString:@"-" withString:@""];
    str = [str substringFromIndex:2];
    NSInteger latest = [str integerValue];
    
    NSInteger historyDateValue = [self.stockInfo.fiveDayLastUpdateDay integerValue];
    if (historyDateValue == 0 || latest - historyDateValue >= 2) {
        GetFiveDayStockValue* task = [[GetFiveDayStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task];
        needSync = YES;
    } else if (latest-historyDateValue == 1 && [self.stockInfo.fiveDayPriceByMinutes count] < 1200) {
        GetFiveDayStockValue* task = [[GetFiveDayStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task];
        needSync = YES;
    }

    historyDateValue = [self.stockInfo.hundredDayLastUpdateDay integerValue];
    if (historyDateValue == 0 || latest - historyDateValue >= 2) {
        GetDaysStockValue* task5 = [[GetDaysStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task5];
    } else if (latest-historyDateValue == 1 && [self.stockInfo.hundredDaysPrice count] < 100) {
        GetDaysStockValue* task5 = [[GetDaysStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task5];
    }
    
    if (needSync) {
        SyncPoint* sync = [[SyncPoint alloc] init];
        sync.onCompleteBlock = ^(StockInfo* info) {
            [self onStockValueRefreshed];
            [self onKDJTypeChanged:nil];
        };
        [[KingdaWorker getInstance] queue:sync];
    }
}

-(void)onPlayerStatusChanged:(NSNotification*)notification {
    StockInfo* info = [notification object];
    if (info != nil) {
        self.stockInfo = info;
        [self.stockNameButton setTitle:info.name forState:UIControlStateNormal];
        [self onStockValueRefreshed];
        [self refreshData];
        [self clearCharts];
    }
}

- (IBAction)onStockButtonClicked:(id)sender {
    stockListView = [[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 250, 350)];
    stockListView.datasource = self;
    stockListView.titleName.text = @"请选择";
    stockListView.delegate = self;
    [stockListView show];
}

- (void)onStockValueRefreshed {
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
    
    [buySellController setStockInfo:self.stockInfo];
    [buySellController reload];

    [self refreshFenShi];
//    [self refreshData];

    //Da pan
    StockInfo* info = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    NSMutableString* str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.shValue setText:str];
    if (info.changeRate < 0) {
        [self.shValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.shValue setTextColor:[UIColor redColor]];
    }
    
    info = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.szValue setText:str];
    if (info.changeRate < 0) {
        [self.szValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.szValue setTextColor:[UIColor redColor]];
    }
    
    info = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.chuangValue setText:str];
    if (info.changeRate < 0) {
        [self.chuangValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.chuangValue setTextColor:[UIColor redColor]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) refreshKline {
    float l = 100000;
    float h = -1;
    NSInteger startIndex = [self.priceKValues count] - [self.kdj_d count];
    if (startIndex < 0) {
        startIndex = 0;
    }
    
//    if ([self.kdj_d count] < 35) {
//        startIndex = 10;
//    }
    NSMutableArray* cPriceArray = [[NSMutableArray alloc] init];
    NSMutableArray* ma5Array = [[NSMutableArray alloc] init];
    NSMutableArray* ma10Array = [[NSMutableArray alloc] init];
    NSMutableArray* ma20Array = [[NSMutableArray alloc] init];
    for (NSInteger i = startIndex; i<[self.priceKValues count]; i++) {
        NSArray* array = [self.priceKValues objectAtIndex:i];
        if ([array count] != 3) {
            continue;
        }
        NSNumber* p = [array objectAtIndex:1];
        if ([p floatValue] > h) {
            h = [p floatValue];
        }
        if ([p floatValue] < l) {
            l = [p floatValue];
        }
        [cPriceArray addObject:p];
        
        //MA5
        if (i-5 >= 0) {
            float average = 0;
            for (int j=0; j<5; j++) {
                NSArray* array = [self.priceKValues objectAtIndex:i-5+j];
                if ([array count] != 3) {
                    continue;
                }
                NSNumber* p = [array objectAtIndex:1];
                average += [p floatValue];
            }
            [ma5Array addObject:[NSNumber numberWithFloat:average/5]];
        } else {
            [ma5Array addObject:@"No"];
        }
        //MA10
        if (i-10 >= 0) {
            float average = 0;
            for (int j=0; j<10; j++) {
                NSArray* array = [self.priceKValues objectAtIndex:i-10+j];
                if ([array count] != 3) {
                    continue;
                }
                NSNumber* p = [array objectAtIndex:1];
                average += [p floatValue];
            }
            [ma10Array addObject:[NSNumber numberWithFloat:average/10]];
        } else {
            [ma10Array addObject:@"No"];
        }
        //MA20
        if (i-20 >= 0) {
            float average = 0;
            for (int j=0; j<20; j++) {
                NSArray* array = [self.priceKValues objectAtIndex:i-20+j];
                if ([array count] != 3) {
                    continue;
                }
                NSNumber* p = [array objectAtIndex:1];
                average += [p floatValue];
            }
            [ma20Array addObject:[NSNumber numberWithFloat:average/20]];
        } else {
            [ma20Array addObject:@"No"];
        }
    }

    kLineChartView.max = h;
    kLineChartView.min = l;
    kLineChartView.horizontalLineInterval = (kLineChartView.frame.size.height - 5) / 5;
    if (h == l) {
        kLineChartView.interval = 1;
    } else {
        kLineChartView.interval = (h-l)/5;
    }
    float delta = (h - l)/6;
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (int i=0; i<6; i++) {
        [array addObject:[NSNumber numberWithFloat:l+delta*i]];
    }
    if (l > 3) {
        kLineChartView.floatNumberFormatterString = @"%.2f";
    } else {
        kLineChartView.floatNumberFormatterString = @"%.3f";
    }
    kLineChartView.yAxisValues = array;
    kLineChartView.numberOfVerticalElements = 6;
    kLineChartView.pointerInterval = (kLineChartView.frame.size.width - LEFT_PADDING)/35;
    kLineChartView.xAxisInterval = (kLineChartView.frame.size.width - LEFT_PADDING)/35;
    kLineChartView.axisLeftLineWidth = LEFT_PADDING;
    kLineChartView.splitX = todayStartIndex;
    
    [kLineChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [cPriceArray mutableCopy];
    plot1.lineColor = [UIColor redColor];
    plot1.lineWidth = 2;
    [kLineChartView addPlot:plot1];
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [ma5Array mutableCopy];
    plot2.lineColor = [UIColor blackColor];
    plot2.lineWidth = 1;
    [kLineChartView addPlot:plot2];
    float price = 0;
    if ([ma5Array count] != 0) {
        price = [[ma5Array lastObject] floatValue];
        if (price >= 3) {
            self.fiveAPrice.text = [NSString stringWithFormat:@"%.2f", price];
        } else {
            self.fiveAPrice.text = [NSString stringWithFormat:@"%.3f", price];
        }
    }
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [ma10Array mutableCopy];
    plot3.lineColor = [UIColor blueColor];
    plot3.lineWidth = 1;
    [kLineChartView addPlot:plot3];
    if ([ma10Array count] != 0) {
        price = [[ma10Array lastObject] floatValue];
        if (price >= 3) {
            self.tenAPrice.text = [NSString stringWithFormat:@"%.2f", price];
        } else {
            self.tenAPrice.text = [NSString stringWithFormat:@"%.3f", price];
        }
    }
    
    PNPlot *plot4 = [[PNPlot alloc] init];
    plot4.plottingValues = [ma20Array mutableCopy];
    plot4.lineColor = [UIColor orangeColor];
    plot4.lineWidth = 1;
    [kLineChartView addPlot:plot4];
    if ([ma20Array count] != 0) {
        price = [[ma20Array lastObject] floatValue];
        if (price >= 3) {
            self.twentyAPrice.text = [NSString stringWithFormat:@"%.2f", price];
        } else {
            self.twentyAPrice.text = [NSString stringWithFormat:@"%.3f", price];
        }
    }
    
    [kLineChartView setNeedsDisplay];
}

- (void) refreshKDJ {
    kdjChartView.max = 100;
    kdjChartView.min = 0;
    kdjChartView.horizontalLineInterval = (kdjChartView.frame.size.height - 5) / 5;
    kdjChartView.interval = 20;
    kdjChartView.yAxisValues = @[@"0", @"20", @"40", @"60", @"80", @"100"];
    kdjChartView.numberOfVerticalElements = 6;
    kdjChartView.pointerInterval = (kdjChartView.frame.size.width - LEFT_PADDING)/35;
    kdjChartView.xAxisInterval = (kdjChartView.frame.size.width - LEFT_PADDING)/35;
    kdjChartView.axisLeftLineWidth = LEFT_PADDING;
    kdjChartView.splitX = todayStartIndex;

    [kdjChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [self.kdj_k mutableCopy];
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    [kdjChartView addPlot:plot1];
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [self.kdj_d mutableCopy];
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    [kdjChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [self.kdj_j mutableCopy];
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    [kdjChartView  addPlot:plot3];
    [kdjChartView setNeedsDisplay];
    
    [self refreshKline];
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
    NSString* rateStr = [NSString stringWithFormat:@"%.2f%%", info.changeRate * 100];
    cell.textLabel.text = [NSString stringWithFormat:@"%@  %@",info.name, rateStr];
    return cell;
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    UITableViewCell *cell = [tableView popoverCellForRowAtIndexPath:indexPath];
//    cell.imageView.image = [UIImage imageNamed:@"selection_normal.png"];
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
    [self refreshData];
    [self clearCharts];
    
    // Player set
    if ([[StockPlayerManager getInstance] isPlaying]) {
        for (int i=0; i<[[DatabaseHelper getInstance].stockList count]; i++) {
            StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:i];
            if ([info.sid isEqualToString:self.stockInfo.sid]) {
                [[StockPlayerManager getInstance] playByIndex:i];
                break;
            }
        }
    }
}

-(void) refreshFenShi {
    float highest = -100;
    float lowest = 100;
    
    StockInfo* shInfo = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    StockInfo* szInfo = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    StockInfo* cyInfo = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    
    float width = priceChartView.frame.size.width - LEFT_PADDING;
    float pointerInterval = width/240;
    float xAsisInterval = width/4;
    
    NSInteger index = 0;
    
    if (true) {
        float h = (self.stockInfo.todayHighestPrice-self.stockInfo.lastDayPrice)/self.stockInfo.lastDayPrice * 100;
        float l = (self.stockInfo.todayLoestPrice-self.stockInfo.lastDayPrice)/self.stockInfo.lastDayPrice * 100;
        if (h > highest) {
            highest = h;
        }
        if (l < lowest) {
            lowest = l;
        }
    }
    if (shInfo.changeRate*100 > highest) {
        highest = shInfo.changeRate*100;
    }
    if (szInfo.changeRate*100 > highest) {
        highest = szInfo.changeRate*100;
    }
    if (cyInfo.changeRate*100 > highest) {
        highest = cyInfo.changeRate*100;
    }
    if (shInfo.changeRate*100 < lowest) {
        lowest = shInfo.changeRate*100;
    }
    if (szInfo.changeRate*100 < lowest) {
        lowest = szInfo.changeRate*100;
    }
    if (cyInfo.changeRate*100 < lowest) {
        lowest = cyInfo.changeRate*100;
    }
    
    float tmph = highest >0 ? highest : -1*highest;
    float tmpl = lowest >0 ? lowest : -1*lowest;
    float tmp = tmph;
    if (tmpl > tmph) {
        tmp = tmpl;
    }
    if (tmp > 10) {
        tmp = 10-0.05;
    }
    
    priceChartView.max = tmp + 0.05;
    priceChartView.min = -1*tmp - 0.05;
    priceChartView.interval = (priceChartView.max - priceChartView.min)/4;
    priceChartView.numberOfVerticalElements = 5;
    priceChartView.pointerInterval = pointerInterval;
    priceChartView.horizontalLineInterval = 150/4;
    priceChartView.floatNumberFormatterString = @"%.2f";
    priceChartView.axisLeftLineWidth = LEFT_PADDING;
    priceChartView.xAxisInterval = xAsisInterval;
    NSMutableArray* yAxisValues = [[NSMutableArray alloc] init];
    for (int i=0; i<5; i++) {
        float value = priceChartView.min + i*priceChartView.interval;
        [yAxisValues  addObject:[NSNumber numberWithFloat:value]];
    }
    priceChartView.yAxisValues = yAxisValues;
    
    [priceChartView clearPlot];

    //Shanghai
    for (int i=0; i<3; i++) {
        StockInfo* info = nil;
        PNPlot *plot = [[PNPlot alloc] init];
        switch (i) {
            case 0:
                info = shInfo;
                plot.lineColor = [UIColor blackColor];
                break;
            case 1:
                info = szInfo;
                plot.lineColor = [UIColor brownColor];
                break;
            case 2:
                info = cyInfo;
                plot.lineColor = [UIColor blueColor];
                break;
        }
        NSMutableArray* array = [[NSMutableArray alloc] init];
        float lastDayPrice = info.price * (1-info.changeRate);
        
        for (index = 0; index < [info.todayPriceByMinutes count]; index++) {
            NSNumber* price = [info.todayPriceByMinutes objectAtIndex:index];
            float changeRate = ([price floatValue]-lastDayPrice) / lastDayPrice * 100;
            [array addObject:[NSNumber numberWithFloat:changeRate]];
        }
        plot.plottingValues = array;
        plot.lineWidth = 1;
        [priceChartView addPlot:plot];
    }

    // Current stock
    {
        NSMutableArray* array = [[NSMutableArray alloc] init];
        NSMutableArray* averageArray = [[NSMutableArray alloc] init];
        float average = 0;
        for (index = 0; index < [self.stockInfo.todayPriceByMinutes count]; index++) {
            NSNumber* price = [self.stockInfo.todayPriceByMinutes objectAtIndex:index];
            float changeRate = ([price floatValue]-self.stockInfo.lastDayPrice) / self.stockInfo.lastDayPrice * 100;
            [array addObject:[NSNumber numberWithFloat:changeRate]];
            average *= index;
            average += changeRate;
            average /= (index+1);
            [averageArray addObject:[NSNumber numberWithFloat:average]];
        }
        
        PNPlot *plot2 = [[PNPlot alloc] init];
        plot2.plottingValues = averageArray;
        plot2.lineColor = [UIColor yellowColor];
        plot2.lineWidth = 2;
        [priceChartView addPlot:plot2];
        
        PNPlot *plot = [[PNPlot alloc] init];
        plot.plottingValues = array;
        plot.lineColor = [UIColor redColor];
        plot.lineWidth = 2;
        [priceChartView addPlot:plot];
    }

    [priceChartView setNeedsDisplay];
}

- (IBAction)onKDJTypeChanged:(id)sender {
    int delta = 1;
        UISegmentedControl* control = self.kdjTypeSegment;
        switch (control.selectedSegmentIndex) {
            case 0:
                delta = 1;
                break;
            case 1:
                delta = 5;
                break;
            case 2:
                delta = 15;
                break;
            case 3:
                delta = 30;
                break;
            case 4:
                delta = 60;
                break;
            case 5:
                delta = 240;
                break;
            case 6:
                [self moreClicked];
                [control setSelectedSegmentIndex:preSegment];
                return;
            default:
                break;
        }
    preSegment = control.selectedSegmentIndex;
    CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:self.stockInfo andDelta:delta];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        self.kdj_d = _self.kdj_d;
        self.kdj_j = _self.kdj_j;
        self.kdj_k = _self.kdj_k;
        self.priceKValues = _self.priceKValues;
        todayStartIndex = _self.todayStartIndex;
        [self refreshKDJ];
    };
    
    [self clearCharts];

    [[KingdaWorker getInstance] queue:task];
}

-(void) clearCharts {
    [kdjChartView clearPlot];
    [kdjChartView setNeedsDisplay];
    [kLineChartView clearPlot];
    [kLineChartView setNeedsDisplay];
    
    self.fiveAPrice.text = @"-";
    self.tenAPrice.text = @"-";
    self.twentyAPrice.text = @"-";
}

- (IBAction)moreClicked {
    StockDetailViewController* controller = [[StockDetailViewController alloc] init];
    [controller setStockInfo:self.stockInfo];
    [self presentViewController:controller animated:YES completion:nil];
}
@end
