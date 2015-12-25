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

@interface StockKDJViewController ()
@property (weak, nonatomic) IBOutlet PNLineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet PNLineChartView *oneMKDJChartView;
@property (weak, nonatomic) IBOutlet PNLineChartView *fiveMKDJChartView;
@property (nonatomic, strong) NSMutableArray* kdj_k;
@property (nonatomic, strong) NSMutableArray* kdj_d;
@property (nonatomic, strong) NSMutableArray* kdj_j;
@property (nonatomic, strong) ADTickerLabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIFont *font = [UIFont boldSystemFontOfSize: 30];
    
    self.priceLabel = [[ADTickerLabel alloc] initWithFrame: CGRectMake(self.view.frame.size.width/2 + 10, 50, 0, font.lineHeight)];
    self.priceLabel.font = font;
    self.priceLabel.characterWidth = 22;
    self.priceLabel.changeTextAnimationDuration = 0.5;
    [self.view addSubview: self.priceLabel];

    [self onStockValueRefreshed];
}

- (void)onStockValueRefreshed {
    NSString* price = @"";
    if (self.stockInfo.price > 3) {
        price = [NSString stringWithFormat:@"%.2f", self.stockInfo.price];
    } else {
        price = [NSString stringWithFormat:@"%.3f", self.stockInfo.price];
    }
    self.priceLabel.text = price;
    NSString* rate = [NSString stringWithFormat:@"%.2f%%", self.stockInfo.changeRate * 100];
    self.rateLabel.text = rate;
    if (self.stockInfo.changeRate < 0) {
        [self.rateLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
        [self.priceLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else {
        [self.rateLabel setTextColor:[UIColor redColor]];
        [self.priceLabel setTextColor:[UIColor redColor]];
    }
    
    [self refreshHalfMinuteKDJ];
    [self refreshOneMinuteKDJ];
    [self refreshFiveMinuteKDJ];
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
    [self calculateKDJ:array];
    
    self.lineChartView.max = 100;
    self.lineChartView.min = 0;
    self.lineChartView.interval = 50;
    self.lineChartView.yAxisValues = @[@"0", @"50", @"100"];
    
    NSMutableArray* xAxisValues = [@[] mutableCopy];
    for (int i=0; i<[array count]; i++) {
        [xAxisValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    self.lineChartView.xAxisValues = xAxisValues;
    
    [self.lineChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [self.kdj_k mutableCopy];
    
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    
    [self.lineChartView addPlot:plot1];
    
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [self.kdj_d mutableCopy];
    
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    
    [self.lineChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [self.kdj_j mutableCopy];
    
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    
    [self.lineChartView  addPlot:plot3];
    [self.lineChartView setNeedsDisplay];
}

- (void) refreshPrice {
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
    [self calculateKDJ:array];

    self.lineChartView.max = 100;
    self.lineChartView.min = 0;
    self.lineChartView.interval = 50;
    self.lineChartView.yAxisValues = @[@"0", @"50", @"100"];
    
    NSMutableArray* xAxisValues = [@[] mutableCopy];
    for (int i=0; i<[array count]; i++) {
        [xAxisValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    self.lineChartView.xAxisValues = xAxisValues;
    
    [self.lineChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [self.kdj_k mutableCopy];
    
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    
    [self.lineChartView addPlot:plot1];
    
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [self.kdj_d mutableCopy];
    
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    
    [self.lineChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [self.kdj_j mutableCopy];
    
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    
    [self.lineChartView  addPlot:plot3];
    [self.lineChartView setNeedsDisplay];
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
    [self calculateKDJ:array];
    
    self.oneMKDJChartView.max = 100;
    self.oneMKDJChartView.min = 0;
    self.oneMKDJChartView.interval = 50;
    self.oneMKDJChartView.yAxisValues = @[@"0", @"50", @"100"];
    
    NSMutableArray* xAxisValues = [@[] mutableCopy];
    for (int i=0; i<[array count]; i++) {
        [xAxisValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    self.oneMKDJChartView.xAxisValues = xAxisValues;
    
    [self.oneMKDJChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [self.kdj_k mutableCopy];
    
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    
    [self.oneMKDJChartView addPlot:plot1];
    
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [self.kdj_d mutableCopy];
    
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    
    [self.oneMKDJChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [self.kdj_j mutableCopy];
    
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    
    [self.oneMKDJChartView  addPlot:plot3];
    [self.oneMKDJChartView setNeedsDisplay];
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
    [self calculateKDJ:array];
    
    self.fiveMKDJChartView.max = 100;
    self.fiveMKDJChartView.min = 0;
    self.fiveMKDJChartView.interval = 50;
    self.fiveMKDJChartView.yAxisValues = @[@"0", @"50", @"100"];
    
    NSMutableArray* xAxisValues = [@[] mutableCopy];
    for (int i=0; i<[array count]; i++) {
        [xAxisValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    self.fiveMKDJChartView.xAxisValues = xAxisValues;
    
    [self.fiveMKDJChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [self.kdj_k mutableCopy];
    
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    
    [self.fiveMKDJChartView addPlot:plot1];
    
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [self.kdj_d mutableCopy];
    
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    
    [self.fiveMKDJChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [self.kdj_j mutableCopy];
    
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    
    [self.fiveMKDJChartView  addPlot:plot3];
    [self.fiveMKDJChartView setNeedsDisplay];
}

- (void) calculateKDJ:(NSArray *)data {
    float prev_k = 50;
    float prev_d = 50;
    float rsv = 0;
    int index = 0;
    if ([data count] > 35) {
        index = [data count] - 35;
    }
    [self.kdj_d removeAllObjects];
    [self.kdj_j removeAllObjects];
    [self.kdj_k removeAllObjects];
    for(int i = index;i < data.count;i++){
        float h  = [[[data objectAtIndex:i] objectAtIndex:0] floatValue];
        float l = [[[data objectAtIndex:i] objectAtIndex:2] floatValue];
        float c = [[[data objectAtIndex:i] objectAtIndex:1] floatValue];
        if (i > 10) {
            for(int j=i;j>i-10;j--){
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
