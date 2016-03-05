//
//  FenshiViewController.m
//  StockListener
//
//  Created by Guozhen Li on 1/11/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "FenshiViewController.h"
#import "PNLineChartView.h"
#import "StockInfo.h"
#import "DatabaseHelper.h"
#import "StockKDJViewController.h"
#import "PNPlot.h"

@interface FenshiViewController() {
    PNLineChartView *priceChartView;
    UIView* parentView;
    UIButton* infoButton;
}

@end

@implementation FenshiViewController

-(id) initWithParentView:(UIView*)view {
    if (self = [super init]) {
        parentView = view;
        priceChartView = [[PNLineChartView alloc] init];
        [priceChartView setBackgroundColor:[UIColor whiteColor]];
        [parentView addSubview:priceChartView];
        [priceChartView setHandleLongClick:NO];
//        infoButton = [[UIButton alloc] init];
        infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoButton addTarget:self action:@selector(infoClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [infoButton setImage:[UIImage imageNamed:@"setting_small"] forState:UIControlStateNormal];
        [parentView addSubview:infoButton];
    }
    return self;
}

-(void) infoClicked:(id)btn {
    NSLog(@"TODO");
}

-(void) setPriceMark:(float)priceMark {
    [priceChartView setMarkY:priceMark];
}

-(void) setPriceMarkColor:(UIColor*)color {
    [priceChartView setMarkYColor:color];
}

-(void) setPriceInfoStr:(NSString*)str {
    [priceChartView setInfoStr:str];
}

-(void) setFrame:(CGRect)rect {
    [priceChartView setFrame: rect];
    CGRect rectInfo = infoButton.frame;
    rectInfo.origin.x = rect.origin.x+20;
    rectInfo.origin.y = rect.origin.y;
//    rectInfo.size.width = 20;
//    rectInfo.size.height = 20;
    [infoButton setFrame:rectInfo];
}

-(void) setSplitX:(NSInteger)x {
    priceChartView.splitX = x;
}

-(void) hideInfoButton {
    [infoButton setHidden:YES];
}

-(void) refresh:(StockInfo*)stockInfo {
    float highest = -100;
    float lowest = 100;
    
    StockInfo* shInfo = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    StockInfo* szInfo = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    StockInfo* cyInfo = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    
    float width = priceChartView.frame.size.width - LEFT_PADDING-1;
    float pointerInterval = width/240;
    float xAsisInterval = width/4;
    
    NSInteger index = 0;
    
    if (true) {
        float h = (stockInfo.todayHighestPrice-stockInfo.lastDayPrice)/stockInfo.lastDayPrice * 100;
        float l = (stockInfo.todayLoestPrice-stockInfo.lastDayPrice)/stockInfo.lastDayPrice * 100;
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
    
    self.highestRate = tmp + 0.05;
    self.lowestRate = -1*tmp - 0.05;
    
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
    
    [priceChartView setNeedsDisplay];

    // Current stock
    {
        NSMutableArray* array = [[NSMutableArray alloc] init];
        NSMutableArray* averageArray = [[NSMutableArray alloc] init];
        float average = 0;
        for (index = 0; index < [stockInfo.todayPriceByMinutes count]; index++) {
            NSNumber* price = [stockInfo.todayPriceByMinutes objectAtIndex:index];
            float changeRate = ([price floatValue]-stockInfo.lastDayPrice) / stockInfo.lastDayPrice * 100;
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
}

@end
