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
#import "StockKDJViewController.h"
#import "CalculateKDJ.h"
#import "StockInfo.h"
#import "KingdaWorker.h"

@interface KDJViewController() {
    PNLineChartView *kdjChartView;
    PNLineChartView* kdjChartView2;
    PNLineChartView* kdjChartView3;
    PNLineChartView* kdjChartView4;
    
    UILabel* label2;
    UILabel* label3;
    UILabel* label4;
    
    UIView* parentView;
    
    NSInteger delta1;
    NSInteger delta2;
    NSInteger delta3;
}

@end

@implementation KDJViewController

-(id) initWithParentView:(UIView*)view {
    if (self = [super init]) {
        parentView = view;
        kdjChartView = [[PNLineChartView alloc] init];
        [kdjChartView setBackgroundColor:[UIColor whiteColor]];
        [parentView addSubview:kdjChartView];
        
        kdjChartView2 = [[PNLineChartView alloc] init];
        [kdjChartView2 setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
        [parentView addSubview:kdjChartView2];
        
        kdjChartView3 = [[PNLineChartView alloc] init];
        [kdjChartView3 setBackgroundColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1]];
        [parentView addSubview:kdjChartView3];
        
        kdjChartView4 = [[PNLineChartView alloc] init];
        [kdjChartView4 setBackgroundColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1]];
        [parentView addSubview:kdjChartView4];
        
        UIFont *font = [UIFont fontWithName:@"Arial" size:10.0f];
        label2 = [[UILabel alloc] init];
        [label2 setFont:font];
        label2.layer.borderWidth = 0.5;
        label2.layer.borderColor = [[UIColor grayColor] CGColor];
        [parentView addSubview:label2];
        label3 = [[UILabel alloc] init];
        [label3 setFont:font];
        label3.layer.borderWidth = 0.5;
        label3.layer.borderColor = [[UIColor grayColor] CGColor];
        [parentView addSubview:label3];
        label4 = [[UILabel alloc] init];
        [label4 setFont:font];
        label4.layer.borderWidth = 0.5;
        label4.layer.borderColor = [[UIColor grayColor] CGColor];
        [parentView addSubview:label4];
        
        self.isShowSnapshot = YES;
    }
    return self;
}

-(void) setFrame:(CGRect)rect {
    if (!self.isShowSnapshot) {
        kdjChartView2 = nil;
        kdjChartView3 = nil;
        kdjChartView4 = nil;
        [label2 setHidden:YES];
        [label3 setHidden:YES];
        [label4 setHidden:YES];
    }
    
    CGRect labelRect;
    //1
    [kdjChartView setFrame: rect];
    kdjChartView.max = 100;
    kdjChartView.min = 0;
    kdjChartView.horizontalLineInterval = (kdjChartView.frame.size.height - 5) / 5;
    kdjChartView.interval = 20;
    kdjChartView.yAxisValues = @[@"0", @"20", @"40", @"60", @"80", @"100"];
    kdjChartView.numberOfVerticalElements = 6;
//    kdjChartView.pointerInterval = (kdjChartView.frame.size.width - LEFT_PADDING-1)/(MAX_DISPLAY_COUNT-1);
//    kdjChartView.xAxisInterval = (kdjChartView.frame.size.width - LEFT_PADDING)-1/(MAX_DISPLAY_COUNT-1);
    kdjChartView.axisLeftLineWidth = LEFT_PADDING;
    //2
    rect.origin.x = rect.origin.x + rect.size.width + 5;
    rect.size.width = (parentView.frame.size.width - rect.size.width - 2)/3;
    kdjChartView2.max = 100;
    kdjChartView2.min = 0;
    kdjChartView2.horizontalLineInterval = (kdjChartView2.frame.size.height - 5) / 5;
    kdjChartView2.interval = 20;
    kdjChartView2.numberOfVerticalElements = 0;
    kdjChartView2.pointerInterval = (kdjChartView2.frame.size.width - 0-1)/(2-1);
    kdjChartView2.xAxisInterval = (kdjChartView2.frame.size.width - 0)-1/(2-1);
    kdjChartView2.axisLeftLineWidth = 0;
    labelRect.origin.x = rect.origin.x;
    labelRect.origin.y = rect.origin.y - 10;
    labelRect.size.width = rect.size.width;
    labelRect.size.height = 10;
    [label2 setFrame:labelRect];
    [kdjChartView2 setFrame:rect];
    //3
    rect.origin.x = rect.origin.x + rect.size.width;
    [kdjChartView3 setFrame:rect];
    kdjChartView3.max = 100;
    kdjChartView3.min = 0;
    kdjChartView3.horizontalLineInterval = (kdjChartView3.frame.size.height - 5) / 5;
    kdjChartView3.interval = 20;
    kdjChartView3.numberOfVerticalElements = 0;
    kdjChartView3.pointerInterval = (kdjChartView3.frame.size.width - 0-1)/(2-1);
    kdjChartView3.xAxisInterval = (kdjChartView3.frame.size.width - 0)-1/(2-1);
    kdjChartView3.axisLeftLineWidth = 0;
    labelRect.origin.x = rect.origin.x;
    labelRect.origin.y = rect.origin.y - 10;
    [label3 setFrame:labelRect];
    //4
    rect.origin.x = rect.origin.x + rect.size.width;
    [kdjChartView4 setFrame:rect];
    kdjChartView4.max = 100;
    kdjChartView4.min = 0;
    kdjChartView4.horizontalLineInterval = (kdjChartView4.frame.size.height - 5) / 5;
    kdjChartView4.interval = 20;
    kdjChartView4.numberOfVerticalElements = 0;
    kdjChartView4.pointerInterval = (kdjChartView4.frame.size.width - 0-1)/(2-1);
    kdjChartView4.xAxisInterval = (kdjChartView4.frame.size.width - 0)-1/(2-1);
    kdjChartView4.axisLeftLineWidth = 0;
    labelRect.origin.x = rect.origin.x;
    labelRect.origin.y = rect.origin.y - 10;
    [label4 setFrame:labelRect];
}

-(void) setSplitX:(NSInteger)x {
    kdjChartView.splitX = x;
}

-(void) clearPlot {
    [kdjChartView clearPlot];
    [kdjChartView setNeedsDisplay];
}

-(void) refresh:(NSInteger)type andStock:(StockInfo *)info {
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
    NSInteger maxCount = [self.kdj_d count] + 1;
    kdjChartView.pointerInterval = (kdjChartView.frame.size.width - 20 - 1)/(maxCount-1);
    kdjChartView.xAxisInterval = (kdjChartView.frame.size.width - 20-1)/(maxCount-1);
    
    if (type == ONE_MINUTE) {
        delta1 = FIVE_MINUTES;
        delta2 = FIFTEEN_MINUTES;
        delta3 = THIRTY_MINUTES;
        label2.text = @"5";
        label3.text = @"15";
        label4.text = @"30";
    } else if (type == FIVE_MINUTES) {
        delta1 = FIFTEEN_MINUTES;
        delta2 = THIRTY_MINUTES;
        delta3 = ONE_HOUR;
        label2.text = @"15";
        label3.text = @"30";
        label4.text = @"60";
    } else if (type == FIFTEEN_MINUTES) {
        delta1 = THIRTY_MINUTES;
        delta2 = ONE_HOUR;
        delta3 = ONE_DAY;
        label2.text = @"30";
        label3.text = @"60";
        label4.text = @"日";
    } else if (type == THIRTY_MINUTES) {
        delta1 = ONE_HOUR;
        delta2 = ONE_DAY;
        delta3 = ONE_WEEK;
        label2.text = @"60";
        label3.text = @"日";
        label4.text = @"周";
    } else if (type == ONE_HOUR) {
        delta1 = ONE_DAY;
        delta2 = ONE_WEEK;
        delta3 = 0;
        label2.text = @"日";
        label3.text = @"周";
        label4.text = @"";
    } else if (type == ONE_DAY) {
        delta1 = ONE_WEEK;
        delta2 = delta3 = 0;
        label2.text = @"周";
        label3.text = @"";
        label4.text = @"";
    } else {
        delta1 = 0;
        delta2 = 0;
        delta3 = 0;
        label2.text = @"";
        label3.text = @"";
        label4.text = @"";
    }
    if (self.isShowSnapshot) {
        [self refreshSnapshot:info];
    } else {
        [kdjChartView2 setHidden:YES];
        [kdjChartView3 setHidden:YES];
        [kdjChartView4 setHidden:YES];
    }
    [self refreshLabel:info];

}

#define UIColorFromHex(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:1.0]

-(void) updateLabel:(UILabel*)label andJ:(NSArray*)j {
    if ([j count] < 2) {
        return;
    }
    float lastValue = [[j lastObject] floatValue];
    float lastTwoValue = [[j objectAtIndex:[j count]-2] floatValue];
    float delta = lastValue - lastTwoValue;
    float absoluteDelta = delta>0? delta : -1*delta;
    UIColor* color = [UIColor blackColor];
    float alpha = 1.0;
    if (absoluteDelta < 5) {
        if (lastValue < 50) {
            color = [UIColor redColor];
            alpha = 1-0.01*lastValue;
        } else {
            color = UIColorFromHex(0x34b234);
            alpha = 0.01*lastValue;
        }
    } else {
        if (delta > 0) {
            color = [UIColor redColor];
            if (lastValue < 50) {
                alpha = 0.01*lastValue;
            } else {
                alpha = 1-0.01*lastValue;
            }
        } else {
            color = UIColorFromHex(0x34b234);
            if (lastValue < 50) {
                alpha = 0.01*lastValue;
            } else {
                alpha = 1-0.01*lastValue;
            }
        }

    }
    if (alpha <= 0.3) {
        alpha = 0.3;
    }
    [label setTextColor:color];
    [label setAlpha:alpha];
}

-(void) refreshLabel:(StockInfo*)info {
    CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:ONE_MINUTE andCount:10];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        [self updateLabel:self.kdjInfo1 andJ:_self.kdj_j];
    };
    [[KingdaWorker getInstance] queue:task];
    task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:FIVE_MINUTES andCount:10];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        [self updateLabel:self.kdjInfo5 andJ:_self.kdj_j];
    };
    [[KingdaWorker getInstance] queue:task];
    task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:FIFTEEN_MINUTES andCount:10];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        [self updateLabel:self.kdjInfo15 andJ:_self.kdj_j];
    };
    [[KingdaWorker getInstance] queue:task];
    task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:THIRTY_MINUTES andCount:10];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        [self updateLabel:self.kdjInfo30 andJ:_self.kdj_j];
    };
    [[KingdaWorker getInstance] queue:task];
    task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:ONE_HOUR andCount:10];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        [self updateLabel:self.kdjInfo60 andJ:_self.kdj_j];
    };
    [[KingdaWorker getInstance] queue:task];
    task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:ONE_DAY andCount:10];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        [self updateLabel:self.kdjInfoDay andJ:_self.kdj_j];
    };
    [[KingdaWorker getInstance] queue:task];
    task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:ONE_WEEK andCount:10];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        [self updateLabel:self.kdjInfoWeek andJ:_self.kdj_j];
    };
    [[KingdaWorker getInstance] queue:task];
}

-(void) refreshSnapshot:(StockInfo*)info {
    if (delta1 > 0) {
        [kdjChartView2 setHidden:NO];
        CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:delta1 andCount:10];
        task.onCompleteBlock = ^(CalculateKDJ* _self) {
            [kdjChartView2 clearPlot];
            
            if ([_self.kdj_d count] >= 2) {
                kdjChartView2.startIndex = [_self.kdj_d count] -2;
            }
            
            PNPlot *plot1 = [[PNPlot alloc] init];
            plot1.plottingValues = _self.kdj_k;
            plot1.lineColor = [UIColor blackColor];
            plot1.lineWidth = 0.5;
            [kdjChartView2 addPlot:plot1];
            
            PNPlot *plot2 = [[PNPlot alloc] init];
            plot2.plottingValues = _self.kdj_d;
            plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
            plot2.lineWidth = 0.5;
            [kdjChartView2 addPlot:plot2];
            
            PNPlot *plot3 = [[PNPlot alloc] init];
            plot3.plottingValues = _self.kdj_j;
            plot3.lineColor = [UIColor redColor];
            plot3.lineWidth = 0.5;
            [kdjChartView2 addPlot:plot3];
            [kdjChartView2 setNeedsDisplay];
        };
        [[KingdaWorker getInstance] queue:task];
    } else {
        [kdjChartView2 setHidden:YES];
    }
    
    if (delta2 > 0) {
        [kdjChartView3 setHidden:NO];
        CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:delta2 andCount:10];
        task.onCompleteBlock = ^(CalculateKDJ* _self) {
            [kdjChartView3 clearPlot];
            
            if ([_self.kdj_d count] >= 2) {
                kdjChartView3.startIndex = [_self.kdj_d count] -2;
            }

            PNPlot *plot1 = [[PNPlot alloc] init];
            plot1.plottingValues = _self.kdj_k;
            plot1.lineColor = [UIColor blackColor];
            plot1.lineWidth = 0.5;
            [kdjChartView3 addPlot:plot1];
            
            PNPlot *plot2 = [[PNPlot alloc] init];
            plot2.plottingValues = _self.kdj_d;
            plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
            plot2.lineWidth = 0.5;
            [kdjChartView3 addPlot:plot2];
            
            PNPlot *plot3 = [[PNPlot alloc] init];
            plot3.plottingValues = _self.kdj_j;
            plot3.lineColor = [UIColor redColor];
            plot3.lineWidth = 0.5;
            [kdjChartView3 addPlot:plot3];
            [kdjChartView3 setNeedsDisplay];
        };
        [[KingdaWorker getInstance] queue:task];
    } else {
        [kdjChartView3 setHidden:YES];
    }
    
    if (delta3 > 0) {
        [kdjChartView4 setHidden:NO];
        CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:info andDelta:delta3 andCount:10];
        task.onCompleteBlock = ^(CalculateKDJ* _self) {
            [kdjChartView4 clearPlot];
            
            if ([_self.kdj_d count] >= 2) {
                kdjChartView4.startIndex = [_self.kdj_d count] -2;
            }
            
            PNPlot *plot1 = [[PNPlot alloc] init];
            plot1.plottingValues = _self.kdj_k;
            plot1.lineColor = [UIColor blackColor];
            plot1.lineWidth = 0.5;
            [kdjChartView4 addPlot:plot1];
            
            PNPlot *plot2 = [[PNPlot alloc] init];
            plot2.plottingValues = _self.kdj_d;
            plot2.lineColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
            plot2.lineWidth = 0.5;
            [kdjChartView4 addPlot:plot2];
            
            PNPlot *plot3 = [[PNPlot alloc] init];
            plot3.plottingValues = _self.kdj_j;
            plot3.lineColor = [UIColor redColor];
            plot3.lineWidth = 0.5;
            [kdjChartView4 addPlot:plot3];
            [kdjChartView4 setNeedsDisplay];
        };
        [[KingdaWorker getInstance] queue:task];
    } else {
        [kdjChartView4 setHidden:YES];
    }
}

@end
