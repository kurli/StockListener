//
//  KLineChartViewController.m
//  StockListener
//
//  Created by Guozhen Li on 1/11/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "KLineViewController.h"
#import "PNLineChartView.h"
#import "StockKDJViewController.h"
#import "PNPlot.h"

@interface KLineViewController() {
    PNLineChartView *kLineChartView;
    UIView* parentView;
}

@end
@implementation KLineViewController

-(id) initWithParentView:(UIView*)view {
    if (self = [super init]) {
        parentView = view;
        kLineChartView = [[PNLineChartView alloc] init];
        [kLineChartView setBackgroundColor:[UIColor whiteColor]];
        [parentView addSubview:kLineChartView];
        [kLineChartView setYAxisPercentage:YES];
    }
    return self;
}

-(void) setPriceMark:(float)priceMark {
    [kLineChartView setMarkY:priceMark];
}

-(void) setPriceMarkColor:(UIColor*)color {
    [kLineChartView setMarkYColor:color];
}

-(void) setPriceInfoStr:(NSString*)str {
    [kLineChartView setInfoStr:str];
}

-(void) setFrame:(CGRect)rect {
    [kLineChartView setFrame: rect];
}

-(void) setSplitX:(NSInteger)x {
    kLineChartView.splitX = x;
}

-(void) clearPlot {
    [kLineChartView clearPlot];
    [kLineChartView setNeedsDisplay];
}

-(void) refresh {
    float l = 100000;
    float h = -1;

    NSMutableArray* cPriceArray = [[NSMutableArray alloc] init];
    NSMutableArray* ma5Array = [[NSMutableArray alloc] init];
    NSMutableArray* ma10Array = [[NSMutableArray alloc] init];
    NSMutableArray* ma20Array = [[NSMutableArray alloc] init];
    for (NSInteger i = self.startIndex; i<[self.priceKValues count]; i++) {
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

    //K line
    kLineChartView.max = h;
    kLineChartView.min = l;
    kLineChartView.horizontalLineInterval = (float)(kLineChartView.frame.size.height-1) / 5.0;
    if (h == l) {
        kLineChartView.interval = 1;
    } else {
        kLineChartView.interval = (h-l)/5.0;
    }
    float delta = (h - l)/5.0;
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
    kLineChartView.pointerInterval = (kLineChartView.frame.size.width - LEFT_PADDING - 1)/(MAX_DISPLAY_COUNT-1);
    kLineChartView.xAxisInterval = (kLineChartView.frame.size.width - LEFT_PADDING-1)/(MAX_DISPLAY_COUNT-1);
    kLineChartView.axisLeftLineWidth = LEFT_PADDING;
    kLineChartView.splitX = self.todayStartIndex;
    
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

@end
