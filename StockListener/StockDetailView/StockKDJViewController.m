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
#import "VOLChartViewController.h"
#import "AVOLChartViewController.h"
#import "FenshiViewController.h"
#import "KDJViewController.h"
#import "KLineViewController.h"
#import "GetWeeksStockValue.h"
#import "BuySellHistoryViewController.h"
#import "CalculateAVOL.h"

#define LEFT_VIEW_WIDTH self.view.frame.size.width/40*34
#define RIGHT_VIEW_WIDTH self.view.frame.size.width/40*6

@interface StockKDJViewController (){
    BuySellChartViewController* buySellController;
    VOLChartViewController* volController;
    AVOLChartViewController* aVolController;
    ZSYPopoverListView* stockListView;
    NSInteger preSegment;

    FenshiViewController* fenshiViewController;
    KDJViewController* kdjViewController;
    KLineViewController* klineViewController;
    BOOL isRegisteredReceiver;
}
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
@property (weak, nonatomic) IBOutlet UIButton *showKDJButton;
@property (weak, nonatomic) IBOutlet UIButton *preKDJButton;
@property (weak, nonatomic) IBOutlet UIButton *nextKDJButton;

@property (nonatomic,strong) NSTimer *kdjTypeHideTimer;
@end

@implementation StockKDJViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isRegisteredReceiver = NO;
    }
    return self;
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:STOCK_VALUE_REFRESHED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:STOCK_PLAYER_STETE_NOTIFICATION object:nil];
    isRegisteredReceiver = NO;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    fenshiViewController = [[FenshiViewController alloc] initWithParentView:self.view];

    klineViewController = [[KLineViewController alloc] initWithParentView:self.view];
    [klineViewController setFiveAPrice:self.fiveAPrice];
    [klineViewController setTenAPrice:self.tenAPrice];
    [klineViewController setTwentyAPrice:self.twentyAPrice];
    [klineViewController setViewController:self];
    
    [klineViewController hideInfoButton];
    [fenshiViewController hideInfoButton];
    
    kdjViewController = [[KDJViewController alloc] initWithParentView:self.view];
    
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

    if (self.view.frame.size.width > self.view.frame.size.height) {
        return;
    }
    if (!isRegisteredReceiver) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onPlayerStatusChanged:)
                                                     name:STOCK_PLAYER_STETE_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onStockValueRefreshed)
                                                     name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                                   object:nil];
        isRegisteredReceiver = YES;
    }
    
    float leftWidth = ((int)(LEFT_VIEW_WIDTH)/(DEFAULT_DISPLAY_COUNT-1))*(DEFAULT_DISPLAY_COUNT-1);

    int offsetY = self.rateLabel.frame.size.height + self.rateLabel.frame.origin.y + 20;
    CGRect fenshiRect = CGRectMake(0, offsetY, leftWidth, 150);
    [fenshiViewController setFrame:fenshiRect];

    if (buySellController == nil) {
        buySellController = [[BuySellChartViewController alloc] initWithParentView:self.view];
        CGRect rect = CGRectMake(leftWidth, offsetY, RIGHT_VIEW_WIDTH, 150);
        [buySellController loadViewVertical:rect];
    }

    CGRect aRect = self.averagePriceView.frame;
    
    // KDJ buttons and segment controller frame:
    CGRect preKDJRect = self.preKDJButton.frame;
    CGRect nextKDJRect = self.nextKDJButton.frame;
    CGRect showkKdjRect = self.showKDJButton.frame;
    
    nextKDJRect.origin.x = leftWidth - nextKDJRect.size.width;
    nextKDJRect.origin.y = fenshiRect.origin.y + fenshiRect.size.height+1;
    [self.nextKDJButton setFrame:nextKDJRect];
    
    showkKdjRect.origin.x = nextKDJRect.origin.x - showkKdjRect.size.width;
    showkKdjRect.origin.y = nextKDJRect.origin.y;
    [self.showKDJButton setFrame:showkKdjRect];
    
    preKDJRect.origin.x = showkKdjRect.origin.x - preKDJRect.size.width;
    preKDJRect.origin.y = nextKDJRect.origin.y;
    [self.preKDJButton setFrame:preKDJRect];

    CGRect rect = self.kdjTypeSegment.frame;
    rect.origin.y = nextKDJRect.origin.y + nextKDJRect.size.height+1;
    rect.origin.x = 1;
    [self.kdjTypeSegment setFrame:rect];
    
    rect.origin.y = fenshiRect.origin.y + fenshiRect.size.height+1;
    // End

    aRect.origin.x = 5;
    aRect.origin.y = fenshiRect.origin.y + fenshiRect.size.height+1;
    [self.averagePriceView setFrame:aRect];

    [klineViewController setFrame:CGRectMake(0, rect.origin.y + rect.size.height+1, leftWidth, KLINE_VIEW_HEIGHT)];
    if (volController == nil) {
        volController = [[VOLChartViewController alloc] initWithParentView:self.view];
        CGRect rect2 = CGRectMake(LEFT_PADDING, rect.origin.y + rect.size.height+1+KLINE_VIEW_HEIGHT, leftWidth-LEFT_PADDING, 45);
        [volController loadView:rect2];
    }

    [kdjViewController setFrame:CGRectMake(0, rect.origin.y + rect.size.height + KLINE_VIEW_HEIGHT + 45 + 1, leftWidth, 75)];

    offsetY = rect.origin.y + 1;
    if (aVolController == nil) {
        aVolController = [[AVOLChartViewController alloc] initWithParentView:self.view];
        CGRect rect = CGRectMake(leftWidth, offsetY, RIGHT_VIEW_WIDTH, KLINE_VIEW_HEIGHT + AVOL_EXPAND);
        [aVolController loadViewVertical:rect];
    }
    
//    self.averagePriceView.layer.borderWidth = 0.5;
//    self.averagePriceView.layer.borderColor = [[UIColor grayColor] CGColor];

    [self refreshData];
}

-(void) refreshData {
    if (self.stockInfo == nil) {
        return;
    }
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
    historyDateValue = 0;
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
    historyDateValue = 0;
    if (historyDateValue == 0 || latest - historyDateValue >= 2) {
        GetDaysStockValue* task5 = [[GetDaysStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task5];
    } else if (latest-historyDateValue == 1 && [self.stockInfo.hundredDaysPrice count] < 100) {
        GetDaysStockValue* task5 = [[GetDaysStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task5];
    }

    historyDateValue = [self.stockInfo.weeklyLastUpdateDay integerValue];
    historyDateValue = 0;
    if (historyDateValue == 0 || latest - historyDateValue >= 2) {
        GetWeeksStockValue* task6 = [[GetWeeksStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task6];
    } else if (latest-historyDateValue == 1 && [self.stockInfo.hundredDaysPrice count] < 100) {
        GetWeeksStockValue* task5 = [[GetWeeksStockValue alloc] initWithStock:self.stockInfo];
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

-(void) refreshTopLabels {
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
}

- (void)onStockValueRefreshed {
    [self refreshTopLabels];

    if (self.stockInfo == nil) {
        return;
    }
    
    [buySellController setStockInfo:self.stockInfo];
    [buySellController reload];

    [fenshiViewController refresh:self.stockInfo];
    [self onKDJTypeChanged:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) refreshAVOLAsync:(float)l andHighest:(float)h{
    CalculateAVOL* task = [[CalculateAVOL alloc] initWithStockInfo:self.stockInfo];
    task.onCompleteBlock = ^() {
        [self refreshAVOL:l andHighest:h];
    };
    [[KingdaWorker getInstance] queue:task];
}

-(void) refreshAVOL:(float)l andHighest:(float)h{
    // Average VOL
    float delta = 0.01;
    if (l < 3) {
        delta = 0.001;
    }
    if (l > 1000) {
        delta = 1;
    }
    [aVolController setStockInfo:self.stockInfo];
    int ll = l/delta;
    int hh = h/delta;
    
    if (ll == hh) {
        [aVolController setMin:0];
        [aVolController setMax:0];
        [aVolController reload];
        return;
    }
    
    float valuePerPixel = (float)(hh - ll)/(float)KLINE_VIEW_HEIGHT ;
    float extend = valuePerPixel * (AVOL_EXPAND / 2);
    [aVolController setMin:ll-extend];
    [aVolController setMax:hh+extend];
    [aVolController reload];
}

-(void) refreshVOL:(NSInteger) startIndex andVolValues:(NSArray*)volValues andMaxCount:(NSInteger)maxCount {
    //VOL
    volController.volValues = [[NSMutableArray alloc] init];
    for (NSInteger i=startIndex; i<[volValues count]; i++) {
        NSNumber* vol = [volValues objectAtIndex:i];
        [volController.volValues addObject:vol];
    }
    // Insert zero for remaining
    NSInteger count = [volController.volValues count] - maxCount;
    for (NSInteger i=0; i<count; i++) {
        [volController.volValues addObject:[NSNumber numberWithInteger:0]];
    }
    [volController reload];
}

-(void) drawMarks {
    ////
    // Draw mark
    float price = 0;
    float isBuy = YES;
    NSInteger dealCount = 0;
    if ([self.stockInfo.buySellHistory count] > 0) {
        NSString* data = [self.stockInfo.buySellHistory lastObject];
        NSArray* array = [data componentsSeparatedByString:@":"];
        if ([array count] == 2) {
            price = [[array objectAtIndex:0] floatValue];
            dealCount = [[array objectAtIndex:1] integerValue];
            if (price == PRE_EARN_FLAG) {
                price = 0;
            } else {
                if (dealCount > 0) {
                    isBuy = YES;
                } else {
                    isBuy = NO;
                }
            }
        }
    }
    if (price > 0) {
        if (isBuy) {
            float tax = [self.stockInfo getTaxForBuy:price andDealCount:dealCount];
            tax += [self.stockInfo getTaxForSell:self.stockInfo.price andDealCount:dealCount];
            price = tax/(float)dealCount + price;
            [klineViewController setPriceMarkColor:[UIColor redColor]];
            [fenshiViewController setPriceMarkColor:[UIColor redColor]];
        } else {
            [klineViewController setPriceMarkColor:[UIColor greenColor]];
            [fenshiViewController setPriceMarkColor:[UIColor greenColor]];
        }
        [klineViewController setPriceMark:price];
        float rate = (self.stockInfo.price-price)/price;
        [klineViewController setPriceInfoStr:[NSString stringWithFormat:@"  %.2f%%", rate*100]];
        // Set fen shi
        rate = (price-self.stockInfo.lastDayPrice)/self.stockInfo.lastDayPrice;
        [fenshiViewController setPriceMark:rate*100];
        rate = (self.stockInfo.price-price)/price;
        [fenshiViewController setPriceInfoStr:[NSString stringWithFormat:@"  %.2f%%", rate*100]];
    } else {
        [klineViewController setPriceMark:-10];
        [fenshiViewController setPriceMark:-10];
    }
    ////
}

- (IBAction)onKDJTypeChanged:(id)sender {
    int delta = 1;
    NSString* str = @"1分";
    UISegmentedControl* control = self.kdjTypeSegment;
    int maxCount = 10;
    BOOL drawKLine = YES;
    switch (control.selectedSegmentIndex) {
        case 0:
            delta = ONE_MINUTE;
            str = @"1分";
            drawKLine = NO;
            maxCount = 30;
            break;
        case 1:
            delta = FIVE_MINUTES;
            str = @"5分";
            maxCount = 24;
            break;
        case 2:
            delta = FIFTEEN_MINUTES;
            str = @"15分";
            maxCount = 16;
            break;
        case 3:
            delta = THIRTY_MINUTES;
            str = @"30分";
            maxCount = 16;
            break;
        case 4:
            delta = ONE_HOUR;
            str = @"60分";
            maxCount = 20;
            break;
        case 5:
            str = @"日";
            delta = ONE_DAY;
            maxCount = 20;
            break;
        case 6:
            str = @"周";
            delta = ONE_WEEK;
            maxCount = 20;
            break;
        case 7:
            [self moreClicked];
            [control setSelectedSegmentIndex:preSegment];
            return;
        default:
            break;
    }
    preSegment = control.selectedSegmentIndex;
    CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:self.stockInfo andDelta:delta andCount:maxCount];
    task.onCompleteBlock = ^(CalculateKDJ* _self) { 
        kdjViewController.kdj_d = _self.kdj_d;
        kdjViewController.kdj_j = _self.kdj_j;
        kdjViewController.kdj_k = _self.kdj_k;
        kdjViewController.todayStartIndex = _self.todayStartIndex;

        klineViewController.todayStartIndex = _self.todayStartIndex;
        [klineViewController setSplitX:_self.todayStartIndex];
        klineViewController.priceKValues = _self.priceKValues;
        [klineViewController setStockInfo:self.stockInfo];

        NSInteger startIndex = [_self.priceKValues count] - [_self.kdj_d count];
        if (startIndex < 0) {
            startIndex = 0;
        }
        klineViewController.startIndex = startIndex;

        [self refreshAVOLAsync:_self.lowest andHighest:_self.highest];
        [self refreshVOL:startIndex andVolValues:_self.volValues andMaxCount:maxCount];

        [kdjViewController refresh:delta andStock:self.stockInfo];
        [klineViewController refresh:_self.lowest andHighest:_self.highest andDrawKLine:drawKLine];
        if (_self.todayStartIndex == 0) {
            NSInteger splitX = [self.stockInfo.todayPriceByMinutes count] - delta * [_self.kdj_d count];
            [fenshiViewController setSplitX:splitX];
        } else {
            [fenshiViewController setSplitX:0];
        }
        [fenshiViewController refresh:self.stockInfo];
        
        [self drawMarks];
    };

//    [self clearCharts];

    [[KingdaWorker getInstance] queue:task];
    
    if (sender != nil) {
        [self onHideKDJTypeFired];
    }
    [self.showKDJButton setTitle:str forState:UIControlStateNormal];
}

-(void) clearCharts {
    [klineViewController clearPlot];
    [kdjViewController clearPlot];
    
    self.fiveAPrice.text = @"-";
    self.tenAPrice.text = @"-";
    self.twentyAPrice.text = @"-";
}

- (IBAction)moreClicked {
    StockDetailViewController* controller = [[StockDetailViewController alloc] init];
    [controller setStockInfo:self.stockInfo];
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)nextKDJClicked:(id)sender {
    NSInteger selected = self.kdjTypeSegment.selectedSegmentIndex;
    selected ++;
    if (selected >= 7) {
        selected = 0;
    }
    [self.kdjTypeSegment setSelectedSegmentIndex:selected];
    [self onKDJTypeChanged:nil];
}

- (IBAction)preKDJClicked:(id)sender {
    NSInteger selected = self.kdjTypeSegment.selectedSegmentIndex;
    selected --;
    if (selected < 0) {
        selected = 6;
    }
    [self.kdjTypeSegment setSelectedSegmentIndex:selected];
    [self onKDJTypeChanged:nil];
}

-(void)onHideKDJTypeFired {
    [self.kdjTypeSegment setHidden:YES];
    [self.kdjTypeHideTimer invalidate];
    [self setKdjTypeHideTimer:nil];
}

- (IBAction)showKDJClicked:(id)sender {
    if ([self.kdjTypeSegment isHidden]) {
        [self.kdjTypeSegment setHidden:NO];
        [self.view bringSubviewToFront:self.kdjTypeSegment];
        self.kdjTypeHideTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(onHideKDJTypeFired) userInfo:nil repeats:NO];
    } else {
        [self onHideKDJTypeFired];
    }
    
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

@end
