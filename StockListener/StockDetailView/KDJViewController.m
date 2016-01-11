//
//  KDJViewController.m
//  StockListener
//
//  Created by Guozhen Li on 1/11/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "KDJViewController.h"
#import "PNLineChartView.h"
#import "StockKDJViewController.h"
#import "PNPlot.h"

@interface KDJViewController() {
    PNLineChartView *kdjChartView;
    UIView* parentView;
}

@end

@implementation KDJViewController

-(id) initWithParentView:(UIView*)view {
    if (self = [super init]) {
        parentView = view;
        kdjChartView = [[PNLineChartView alloc] init];
        [kdjChartView setBackgroundColor:[UIColor whiteColor]];
        [parentView addSubview:kdjChartView];
    }
    return self;
}

-(void) setFrame:(CGRect)rect {
    [kdjChartView setFrame: rect];
}

-(void) setSplitX:(NSInteger)x {
    kdjChartView.splitX = x;
}

-(void) clearPlot {
    [kdjChartView clearPlot];
    [kdjChartView setNeedsDisplay];
}

-(void) refresh {
    kdjChartView.max = 100;
    kdjChartView.min = 0;
    kdjChartView.horizontalLineInterval = (kdjChartView.frame.size.height - 5) / 5;
    kdjChartView.interval = 20;
    kdjChartView.yAxisValues = @[@"0", @"20", @"40", @"60", @"80", @"100"];
    kdjChartView.numberOfVerticalElements = 6;
    kdjChartView.pointerInterval = (kdjChartView.frame.size.width - LEFT_PADDING-1)/(MAX_DISPLAY_COUNT-1);
    kdjChartView.xAxisInterval = (kdjChartView.frame.size.width - LEFT_PADDING)-1/(MAX_DISPLAY_COUNT-1);
    kdjChartView.axisLeftLineWidth = LEFT_PADDING;
    kdjChartView.splitX = self.todayStartIndex;
    
    [kdjChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = self.kdj_k;
    plot1.lineColor = [UIColor blackColor];
    plot1.lineWidth = 0.5;
    [kdjChartView addPlot:plot1];
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = self.kdj_d;
    plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
    plot2.lineWidth = 1;
    [kdjChartView  addPlot:plot2];
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = self.kdj_j;
    plot3.lineColor = [UIColor redColor];
    plot3.lineWidth = 1;
    [kdjChartView  addPlot:plot3];
    [kdjChartView setNeedsDisplay];
}

@end
