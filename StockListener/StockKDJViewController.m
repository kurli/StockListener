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

#define MAX_SHOW_HALF_MINUTE 30
#define MAX_SHOW_ONE_MINUTE 30
#define MAX_SHOW_FIVE_MINUTE 24
#define LEFT_PADDING 20

@interface StockKDJViewController (){
    UIScrollView *scrollView;
    UIPageControl *pageControl;
    PNLineChartView *lineChartView;
    PNLineChartView *oneMKDJChartView;
    PNLineChartView *fiveMKDJChartView;
    PNLineChartView *priceChartView;
    BuySellChartViewController* buySellController;
    ZSYPopoverListView* stockListView;
    BOOL currentStockSelected;
    BOOL shSelected;
    BOOL szSelected;
    BOOL cySelected;
}
@property (nonatomic, strong) NSMutableArray* kdj_k;
@property (nonatomic, strong) NSMutableArray* kdj_d;
@property (nonatomic, strong) NSMutableArray* kdj_j;
@property (nonatomic, strong) ADTickerLabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UILabel *kdjLabel;
@property (weak, nonatomic) IBOutlet UIView *stockSelectionView;
@property (weak, nonatomic) IBOutlet UIButton *stockNameButton;
@property (weak, nonatomic) IBOutlet UIButton *currentStockSelection;
@property (weak, nonatomic) IBOutlet UIButton *shSelection;
@property (weak, nonatomic) IBOutlet UIButton *szSelection;
@property (weak, nonatomic) IBOutlet UIButton *cySelection;
@property (weak, nonatomic) IBOutlet UILabel *currentStockName;
@end

@implementation StockKDJViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onStockValueRefreshed)
                                                     name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                                   object:nil];
        self.kdj_k = [[NSMutableArray alloc] init];
        self.kdj_d = [[NSMutableArray alloc] init];
        self.kdj_j = [[NSMutableArray alloc] init];
        
        currentStockSelected = YES;
        shSelected = NO;
        szSelected = NO;
        cySelected = NO;
    }
    return self;
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
    
    int offsetY = self.rateLabel.frame.size.height + self.rateLabel.frame.origin.y + 10;
    if (buySellController == nil) {
        buySellController = [[BuySellChartViewController alloc] initWithParentView:self.view];
        [buySellController loadView:offsetY];
    }
    
    if (scrollView == nil) {
        scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(5, self.kdjLabel.frame.origin.y + self.kdjLabel.frame.size.height + 5, self.view.frame.size.width-10, 102)];
        scrollView.delegate = self;
        [self.view addSubview:scrollView];
    }
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width*3, scrollView.frame.size.height);
    
    if (lineChartView == nil) {
        lineChartView = [[PNLineChartView alloc] initWithFrame:CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height)];
        [lineChartView setBackgroundColor:[UIColor whiteColor]];
        oneMKDJChartView = [[PNLineChartView alloc] initWithFrame:CGRectMake(scrollView.frame.size.width, 0, scrollView.frame.size.width, scrollView.frame.size.height)];
        [oneMKDJChartView setBackgroundColor:[UIColor whiteColor]];
        fiveMKDJChartView = [[PNLineChartView alloc] initWithFrame:CGRectMake(scrollView.frame.size.width*2, 0, scrollView.frame.size.width, scrollView.frame.size.height)];
        [fiveMKDJChartView setBackgroundColor:[UIColor whiteColor]];
        [scrollView addSubview:lineChartView];
        [scrollView addSubview:oneMKDJChartView];
        [scrollView addSubview:fiveMKDJChartView];
        [scrollView setPagingEnabled:YES];
        pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0.0f, scrollView.frame.origin.y + scrollView.frame.size.height+5, self.view.frame.size.width, 10.0f)];
        [pageControl setNumberOfPages:3];
        [pageControl setCurrentPage:0];
        [pageControl setPageIndicatorTintColor:[UIColor lightGrayColor]];
        [pageControl setCurrentPageIndicatorTintColor:[UIColor blackColor]];
        [pageControl setUserInteractionEnabled:NO];
        [self.view addSubview:pageControl];
    }
    
    priceChartView = [[PNLineChartView alloc] initWithFrame:CGRectMake(0, self.stockSelectionView.frame.origin.y + self.stockSelectionView.frame.size.height + 5, scrollView.frame.size.width, 150)];
    [priceChartView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:priceChartView];

    [self onStockValueRefreshed];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateButtons];
    [self.stockNameButton setTitle:self.stockInfo.name forState:UIControlStateNormal];
    [self.currentStockName setText:self.stockInfo.name];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView1
{
    CGPoint offsetofScrollView = scrollView1.contentOffset;
    int index = offsetofScrollView.x / scrollView.frame.size.width;
    [pageControl setCurrentPage:index];
    switch (index) {
        case 0:
            self.kdjLabel.text = @"30秒KDJ:";
            break;
        case 1:
            self.kdjLabel.text = @"1分钟KDJ:";
            break;
        case 2:
            self.kdjLabel.text = @"5分钟KDJ:";
            break;
            
        default:
            break;
    }
    [self refreshFenShi];
}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView1 willDecelerate:(BOOL)decelerate{
//    CGPoint offsetofScrollView = scrollView1.contentOffset;
//    [pageControl setCurrentPage:offsetofScrollView.x / scrollView.frame.size.width];
//}

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
    [self.priceLabel setFrame:rect];
    
    NSString* rate = [NSString stringWithFormat:@"%.2f%%", self.stockInfo.changeRate * 100];
    self.rateLabel.text = rate;
    if (self.stockInfo.changeRate < 0) {
        [self.rateLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
        [self.priceLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else {
        [self.rateLabel setTextColor:[UIColor redColor]];
        [self.priceLabel setTextColor:[UIColor redColor]];
    }
    
    [buySellController setStockInfo:self.stockInfo];
    [buySellController reload];

    [self refreshHalfMinuteKDJ];
    [self refreshOneMinuteKDJ];
    [self refreshFiveMinuteKDJ];
    [self refreshFenShi];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) refreshHalfMinuteKDJ {
    NSMutableArray* array = [[NSMutableArray alloc] init];
    int count = 4*60*60/30;
    for (int i =0; i<count; i++) {
        NSString* data = [self.stockInfo.priceHistoryHalfMinute valueForKey:[NSString stringWithFormat:@"%d", i]];
        if (data == nil) {
            continue;
        }
        NSArray* array2 = [data componentsSeparatedByString:@" "];
        [array addObject:array2];
    }
    [self calculateKDJ:array andMaxCount:MAX_SHOW_HALF_MINUTE];
    
    lineChartView.max = 100;
    lineChartView.min = 0;
    lineChartView.interval = 50;
    lineChartView.numberOfVerticalElements = 3;
    lineChartView.yAxisValues = @[@"0", @"50", @"100"];
    lineChartView.pointerInterval = 320/MAX_SHOW_HALF_MINUTE;
    lineChartView.axisLeftLineWidth = LEFT_PADDING;
    lineChartView.xAxisInterval = 320/MAX_SHOW_HALF_MINUTE;
    [lineChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [self.kdj_k mutableCopy];
    
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    
    [lineChartView addPlot:plot1];
    
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [self.kdj_d mutableCopy];
    
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    
    [lineChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [self.kdj_j mutableCopy];
    
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    
    [lineChartView  addPlot:plot3];
    [lineChartView setNeedsDisplay];
}

- (void) refreshOneMinuteKDJ {
    NSMutableArray* array = [[NSMutableArray alloc] init];
    int count = 4*60*60/60;
    for (int i =0; i<count; i++) {
        NSString* data = [self.stockInfo.priceHistoryOneMinutes valueForKey:[NSString stringWithFormat:@"%d", i]];
        if (data == nil) {
            continue;
        }
        NSArray* array2 = [data componentsSeparatedByString:@" "];
        [array addObject:array2];
    }
    [self calculateKDJ:array andMaxCount:MAX_SHOW_ONE_MINUTE];
    
    oneMKDJChartView.max = 100;
    oneMKDJChartView.min = 0;
    oneMKDJChartView.interval = 50;
    oneMKDJChartView.yAxisValues = @[@"0", @"50", @"100"];
    oneMKDJChartView.numberOfVerticalElements = 3;
    oneMKDJChartView.pointerInterval = 320/MAX_SHOW_ONE_MINUTE;
    oneMKDJChartView.xAxisInterval = 320/MAX_SHOW_ONE_MINUTE;
    oneMKDJChartView.axisLeftLineWidth = LEFT_PADDING;
    [oneMKDJChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [self.kdj_k mutableCopy];
    
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    
    [oneMKDJChartView addPlot:plot1];
    
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [self.kdj_d mutableCopy];
    
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    
    [oneMKDJChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [self.kdj_j mutableCopy];
    
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    
    [oneMKDJChartView  addPlot:plot3];
    [oneMKDJChartView setNeedsDisplay];
}

- (void) refreshFiveMinuteKDJ {
    NSMutableArray* array = [[NSMutableArray alloc] init];
    int count = 28;
    for (int i =0; i<count; i++) {
        NSString* data = [self.stockInfo.priceHistoryFiveMinutes valueForKey:[NSString stringWithFormat:@"%d", i]];
        if (data == nil) {
            continue;
        }
        NSArray* array2 = [data componentsSeparatedByString:@" "];
        [array addObject:array2];
    }
    [self calculateKDJ:array andMaxCount:MAX_SHOW_FIVE_MINUTE];
    
    fiveMKDJChartView.max = 100;
    fiveMKDJChartView.min = 0;
    fiveMKDJChartView.interval = 50;
    fiveMKDJChartView.yAxisValues = @[@"0", @"50", @"100"];
    fiveMKDJChartView.numberOfVerticalElements = 3;
    fiveMKDJChartView.pointerInterval = 320/MAX_SHOW_FIVE_MINUTE;
    fiveMKDJChartView.xAxisInterval = 320/MAX_SHOW_FIVE_MINUTE;
    fiveMKDJChartView.axisLeftLineWidth = LEFT_PADDING;

//    NSMutableArray* xAxisValues = [@[] mutableCopy];
//    for (int i=0; i<[array count]; i++) {
//        [xAxisValues addObject:[NSString stringWithFormat:@"%d", i]];
//    }
//    fiveMKDJChartView.xAxisValues = xAxisValues;
    
    [fiveMKDJChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [self.kdj_k mutableCopy];
    
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    
    [fiveMKDJChartView addPlot:plot1];
    
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [self.kdj_d mutableCopy];
    
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    
    [fiveMKDJChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [self.kdj_j mutableCopy];
    
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    
    [fiveMKDJChartView  addPlot:plot3];
    [fiveMKDJChartView setNeedsDisplay];
}

- (void) calculateKDJ:(NSArray *)data andMaxCount:(int)maxCount {
    float prev_k = 50;
    float prev_d = 50;
    float rsv = 0;
    NSInteger index = 0;
    if ([data count] > maxCount) {
        index = [data count] - maxCount;
    }
    [self.kdj_d removeAllObjects];
    [self.kdj_j removeAllObjects];
    [self.kdj_k removeAllObjects];
    for(NSInteger i = index;i < (data.count);i++){
        float h  = [[[data objectAtIndex:i] objectAtIndex:0] floatValue];
        float l = [[[data objectAtIndex:i] objectAtIndex:2] floatValue];
        float c = [[[data objectAtIndex:i] objectAtIndex:1] floatValue];
        if (i > 10) {
            for(NSInteger j=i;j>i-10;j--){
                if([[[data objectAtIndex:j] objectAtIndex:0] floatValue] > h){
                    h = [[[data objectAtIndex:j] objectAtIndex:0] floatValue];
                }
                
                if([[[data objectAtIndex:j] objectAtIndex:2] floatValue] < l){
                    l = [[[data objectAtIndex:j] objectAtIndex:2] floatValue];
                }
            }
        }
        
        if(h!=l)
            rsv = (c-l)/(h-l)*100;
        float k = 2*prev_k/3+1*rsv/3;
        float d = 2*prev_d/3+1*k/3;
//        float j = d+2*(d-k);
        float j = 3*k - 2*d;
        
        prev_k = k;
        prev_d = d;
        if (k<0) k=0;
        if (d<0) d=0;
        if (j<0) j=0;
        if (k>100) k = 100;
        if (d>100) d = 100;
        if (j>100) j = 100;

        [self.kdj_k addObject:[NSNumber numberWithFloat:k]];
        [self.kdj_d addObject:[NSNumber numberWithFloat:d]];
        [self.kdj_j addObject:[NSNumber numberWithFloat:j]];
    }
}

- (IBAction)kButtonClicked:(id)sender {
    StockDetailViewController* controller = [[StockDetailViewController alloc] init];
    [controller setStockInfo:self.stockInfo];
    [self presentViewController:controller animated:YES completion:nil];
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
    [self.currentStockName setText:info.name];
    [self onStockValueRefreshed];
    [stockListView dismiss];
}

-(void) updateButtons {
    if (currentStockSelected) {
        [self.currentStockSelection setImage:[UIImage imageNamed:@"selection_selected.png"] forState:UIControlStateNormal];
    } else {
        [self.currentStockSelection setImage:[UIImage imageNamed:@"selection_normal.png"] forState:UIControlStateNormal];
    }
    if (shSelected) {
        [self.shSelection setImage:[UIImage imageNamed:@"selection_selected.png"] forState:UIControlStateNormal];
    } else {
        [self.shSelection setImage:[UIImage imageNamed:@"selection_normal.png"] forState:UIControlStateNormal];
    }
    if (szSelected) {
        [self.szSelection setImage:[UIImage imageNamed:@"selection_selected.png"] forState:UIControlStateNormal];
    } else {
        [self.szSelection setImage:[UIImage imageNamed:@"selection_normal.png"] forState:UIControlStateNormal];
    }
    if (cySelected) {
        [self.cySelection setImage:[UIImage imageNamed:@"selection_selected.png"] forState:UIControlStateNormal];
    } else {
        [self.cySelection setImage:[UIImage imageNamed:@"selection_normal.png"] forState:UIControlStateNormal];
    }
    [self refreshFenShi];
}

- (IBAction)currentStockClicked:(id)sender {
    currentStockSelected = ! currentStockSelected;
    [self updateButtons];
}

- (IBAction)shSelected:(id)sender {
    shSelected = !shSelected;
    [self updateButtons];
}

- (IBAction)szSelected:(id)sender {
    szSelected = !szSelected;
    [self updateButtons];
}

- (IBAction)cySelected:(id)sender {
    cySelected = !cySelected;
    [self updateButtons];
}

-(void) refreshFenShi {
    float highest = -100;
    float lowest = 100;
    
    StockInfo* shInfo = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    StockInfo* szInfo = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    StockInfo* cyInfo = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    
    float pointerInterval = 320.0/(MAX_SHOW_HALF_MINUTE*30/6);
    float xAsisInterval = 320.0/MAX_SHOW_HALF_MINUTE;
    if (pageControl.currentPage == 1) {
        pointerInterval = 320.0/(MAX_SHOW_ONE_MINUTE*60/6);
        xAsisInterval = 320.0/MAX_SHOW_ONE_MINUTE;
    } else if (pageControl.currentPage == 2) {
        pointerInterval = 320.0/(MAX_SHOW_FIVE_MINUTE*60);
        xAsisInterval = 320.0/MAX_SHOW_FIVE_MINUTE;
    }
    int count = 320/pointerInterval;
    
    NSInteger index = 0;
    
    if (currentStockSelected) {
        index = 0;
        if ([self.stockInfo.changeRateArray count] > count) {
            index = [self.stockInfo.changeRateArray count] - count;
        }
        for (; index < [self.stockInfo.changeRateArray count]; index++) {
            NSNumber* number = [self.stockInfo.changeRateArray objectAtIndex:index];
            if ([number floatValue] > highest) {
                highest = [number floatValue];
            }
            if ([number floatValue] < lowest) {
                lowest = [number floatValue];
            }
        }
    }

    if (shSelected) {
        index = 0;
        if ([shInfo.changeRateArray count] > count) {
            index = [shInfo.changeRateArray count] - count;
        }
        for (; index < [shInfo.changeRateArray count]; index++) {
            NSNumber* number = [shInfo.changeRateArray objectAtIndex:index];
            if ([number floatValue] > highest) {
                highest = [number floatValue];
            }
            if ([number floatValue] < lowest) {
                lowest = [number floatValue];
            }
        }
    }

    if (szSelected) {
        index = 0;
        if ([szInfo.changeRateArray count] > count) {
            index = [szInfo.changeRateArray count] - count;
        }
        for (; index < [szInfo.changeRateArray count]; index++) {
            NSNumber* number = [szInfo.changeRateArray objectAtIndex:index];
            if ([number floatValue] > highest) {
                highest = [number floatValue];
            }
            if ([number floatValue] < lowest) {
                lowest = [number floatValue];
            }
        }
    }

    if (cySelected) {
        index = 0;
        if ([cyInfo.changeRateArray count] > count) {
            index = [cyInfo.changeRateArray count] - count;
        }
        for (; index < [cyInfo.changeRateArray count]; index++) {
            NSNumber* number = [cyInfo.changeRateArray objectAtIndex:index];
            if ([number floatValue] > highest) {
                highest = [number floatValue];
            }
            if ([number floatValue] < lowest) {
                lowest = [number floatValue];
            }
        }
    }

    if (!currentStockSelected && !shSelected && !szSelected && !cySelected) {
        [priceChartView clearPlot];
        [priceChartView setNeedsDisplay];
        return;
    }
    
    priceChartView.max = highest + 1;
    priceChartView.min = lowest - 1;
    priceChartView.interval = (highest-lowest + 2)/4;
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

    if (currentStockSelected) {
        PNPlot *plot = [[PNPlot alloc] init];
        NSMutableArray* array = [[NSMutableArray alloc] init];
        NSInteger index = 0;
        if ([self.stockInfo.changeRateArray count] > count) {
            index = [self.stockInfo.changeRateArray count] - count;
        }
        for (; index < [self.stockInfo.changeRateArray count]; index++) {
            [array addObject:[self.stockInfo.changeRateArray objectAtIndex:index]];
        }
        plot.plottingValues = array;

        plot.lineColor = [UIColor redColor];
        plot.lineWidth = 1;

        [priceChartView addPlot:plot];
    }
    
    if (shSelected) {
        PNPlot *plot = [[PNPlot alloc] init];
        NSMutableArray* array = [[NSMutableArray alloc] init];
        NSInteger index = 0;
        if ([shInfo.changeRateArray count] > count) {
            index = [shInfo.changeRateArray count] - count;
        }
        for (; index < [shInfo.changeRateArray count]; index++) {
            [array addObject:[shInfo.changeRateArray objectAtIndex:index]];
        }

        plot.plottingValues = array;
        
        plot.lineColor = [UIColor blackColor];
        plot.lineWidth = 0.5;
        
        [priceChartView addPlot:plot];
    }

    if (szSelected) {
        PNPlot *plot = [[PNPlot alloc] init];
        NSMutableArray* array = [[NSMutableArray alloc] init];
        NSInteger index = 0;
        if ([szInfo.changeRateArray count] > count) {
            index = [szInfo.changeRateArray count] - count;
        }
        for (; index < [szInfo.changeRateArray count]; index++) {
            [array addObject:[szInfo.changeRateArray objectAtIndex:index]];
        }

        plot.plottingValues = array;

        plot.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
        plot.lineWidth = 0.5;

        [priceChartView addPlot:plot];
    }
    
    if (cySelected) {
        PNPlot *plot = [[PNPlot alloc] init];
        NSMutableArray* array = [[NSMutableArray alloc] init];
        NSInteger index = 0;
        if ([cyInfo.changeRateArray count] > count) {
            index = [cyInfo.changeRateArray count] - count;
        }
        for (; index < [cyInfo.changeRateArray count]; index++) {
            [array addObject:[cyInfo.changeRateArray objectAtIndex:index]];
        }

        plot.plottingValues = array;
        
        plot.lineColor = [UIColor blueColor];
        plot.lineWidth = 0.5;

        [priceChartView addPlot:plot];
    }

    [priceChartView setNeedsDisplay];
}

@end
