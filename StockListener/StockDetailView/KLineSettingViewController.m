//
//  KLineSettingViewController.m
//  StockListener
//
//  Created by Guozhen Li on 1/19/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "KLineSettingViewController.h"
#import "KLineViewController.h"
#import "StockInfo.h"
#import "VOLChartViewController.h"
#import "StockKDJViewController.h"
#import "CalculateKDJ.h"
#import "KingdaWorker.h"
#import "AVOLChartViewController.h"
#import "CalculateAVOL.h"
#import "KDJViewController.h"

@interface KLineSettingViewController () {
    KLineViewController* klineViewController;
    VOLChartViewController* volController;
    AVOLChartViewController* aVolController;
    KDJViewController* kdjViewController;
    NSInteger startIndex;
    NSInteger endIndex;
    float kViewWidth;
    BOOL isKLine;
}

@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegmentController;
//@property (weak, nonatomic) IBOutlet UIView *ylineTypeView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ylineTypeSegmentController;
@property (strong, nonatomic) NSArray* volArray;
@property (strong, nonatomic) NSArray* priceArray;
@property (strong, nonatomic) NSMutableArray* kdj_k;
@property (strong, nonatomic) NSMutableArray* kdj_d;
@property (strong, nonatomic) NSMutableArray* kdj_j;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UILabel *addLabel;
@property (weak, nonatomic) IBOutlet UIButton *finishButton;
@end

@implementation KLineSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    klineViewController = [[KLineViewController alloc] initWithParentView:self.view];
    [klineViewController hideInfoButton];
    klineViewController.stockInfo = self.stockInfo;
    kdjViewController = [[KDJViewController alloc] initWithParentView:self.view];

    __weak KLineViewController *_weak_self = klineViewController;
    __weak KLineSettingViewController *_self = self;
    [klineViewController setOnScroll:^(NSInteger delta, BOOL finished) {
        float pointerInterval = [_weak_self getPointerInterval];
        NSInteger d = 0;
        if (pointerInterval != 0) {
            d = -1* (delta / pointerInterval);
            if (startIndex + d < 0) {
                d = -startIndex;
            }
            if (endIndex + d > [self.priceArray count]) {
                d = [self.priceArray count] - endIndex;
            }
            startIndex += d;
            endIndex += d;
            [_self refreshKDJ];
            [_self redraw];
            if (!finished) {
                startIndex -= d;
                endIndex -= d;
            }
        }
    }];
    [klineViewController setOnScale:^(float zoom, BOOL finished) {
        NSInteger maxCount = endIndex - startIndex;
        NSInteger d = 0;
        if (maxCount != 0 && zoom != 0) {
            d = maxCount * zoom;
            if (d == 0) {
                if (zoom > 0) {
                    d = 1;
                } else {
                    d = -1;
                }
            }
            if (startIndex + d < 0) {
                d = -startIndex;
            }
            if (startIndex + d >= endIndex - 10) {
                d = endIndex - startIndex - 10;
            }
            startIndex += d;
            [_self refreshKDJ];
            [_self redraw];
//            if (!finished) {
//                startIndex += d;
//            }
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    float leftWidth = ((int)(LEFT_VIEW_WIDTH)/(DEFAULT_DISPLAY_COUNT-1))*(DEFAULT_DISPLAY_COUNT-1);
    CGRect rect = self.typeSegmentController.frame;
    rect.size.width = LEFT_VIEW_WIDTH;
    rect.origin.x = 0;
    [self.typeSegmentController setFrame:rect];
    
    float y = self.typeSegmentController.frame.origin.y + self.typeSegmentController.frame.size.height + 1;
    [klineViewController setFrame:CGRectMake(0, y, leftWidth, KLINE_VIEW_HEIGHT*1.5)];

    aVolController = [[AVOLChartViewController alloc] initWithParentView:self.view];
    rect = CGRectMake(leftWidth, y - AVOL_EXPAND/2, RIGHT_VIEW_WIDTH, KLINE_VIEW_HEIGHT*1.5 + AVOL_EXPAND);
    [aVolController loadViewVertical:rect];

    kViewWidth = self.view.frame.size.width-10;
    
    // Set VOL frame
    y = y + KLINE_VIEW_HEIGHT*1.5 + 1;
    if (volController == nil) {
        volController = [[VOLChartViewController alloc] initWithParentView:self.view];
        CGRect rect2 = CGRectMake(LEFT_PADDING, y, leftWidth - LEFT_PADDING, 45);
        [volController loadView:rect2];
    }
    
    y = y + 45 + 1;
    [kdjViewController setIsShowSnapshot:NO];
    [kdjViewController setFrame:CGRectMake(0, y, leftWidth, 75)];
    
    y = y + 75 + 15;
    // Set yline view frame
//    rect = self.ylineTypeView.frame;
//    rect.origin.y = y;
//    [self.ylineTypeView setFrame:rect];
    rect = self.addButton.frame;
    rect.origin.x = 5;
    rect.origin.y = y;
    [self.addButton setFrame:rect];
    
    rect = self.addLabel.frame;
    rect.origin.x = self.addButton.frame.origin.x + self.addButton.frame.size.width + 5;
    rect.origin.y = y;
    [self.addLabel setFrame:rect];
    
    rect = self.finishButton.frame;
    rect.origin.x = self.addLabel.frame.origin.x + self.addLabel.frame.size.width + 5;
    rect.origin.y = y;
    [self.finishButton setFrame:rect];
    
    [self refreshEditLineButtons];
    
    [self typeSegmentChanged:nil];
}

-(void) refreshEditLineButtons {
    if (![klineViewController isEditLine]) {
        [self.finishButton setHidden:YES];
        [self.addButton setHidden:NO];
    } else {
        [self.finishButton setHidden:NO];
        [self.addButton setHidden:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) redraw {
    if (startIndex < 0) {
        startIndex = 0;
    }
    if (endIndex > [self.priceArray count]) {
        endIndex = [self.priceArray count];
    }
    klineViewController.timeStartIndex = startIndex;

    // VOL
    volController.volValues = [[NSMutableArray alloc] init];
    for (NSInteger i=startIndex; i<endIndex; i++) {
        if (i < [self.volArray count]) {
            NSNumber* vol = [self.volArray objectAtIndex:i];
            [volController.volValues addObject:vol];
        } else {
            [volController.volValues addObject:[NSNumber numberWithInt:0]];
        }
    }
    [volController reload];
    // End
    
    NSInteger calStartIndex = startIndex - 20;
    if (calStartIndex < 0) {
        calStartIndex = 0;
    }
    
    klineViewController.todayStartIndex = 0;
    klineViewController.startIndex = startIndex - calStartIndex;

    NSMutableArray* priceValues = [[NSMutableArray alloc] init];
    float l = 100000;
    float h = -100000;
    for (NSInteger i=calStartIndex; i<endIndex; i++) {
        NSArray* array = [self.priceArray objectAtIndex:i];
        float tmpH = [[array objectAtIndex:1] floatValue];
        float tmpL = [[array objectAtIndex:3] floatValue];
        if (tmpH > h) {
            h = tmpH;
        }
        if (tmpL < l) {
            l = tmpL;
        }
        [priceValues addObject:array];
    }
    float delta = (h-l)/10;
    if (delta == 0) {
        delta += 5;
    }
    h += delta;
    l -= delta;
    klineViewController.priceKValues = priceValues;

    [klineViewController refresh:l andHighest:h andDrawKLine:isKLine];
    [self refreshAVOLAsync:l andHighest:h];
}

-(void) refreshAVOLAsync:(float)l andHighest:(float)h{
    CalculateAVOL* task = [[CalculateAVOL alloc] initWithStockInfo:self.stockInfo];
    task.onCompleteBlock = ^() {
        [self refreshAVOL:l andHighest:h];
    };
    [[KingdaWorker getInstance] removeSameKindTask:task];
    [[KingdaWorker getInstance] queue:task];
}

-(void) refreshAVOL:(float)l andHighest:(float)h{
    // Average VOL
    float delta = 0.01;
    if (h < 3) {
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

- (void) refreshKDJ {
    if (startIndex < 0) {
        startIndex = 0;
    }
    if (endIndex > [self.kdj_d count]) {
        endIndex = [self.kdj_d count];
    }
    NSMutableArray* k = [[NSMutableArray alloc] init];
    NSMutableArray* d = [[NSMutableArray alloc] init];
    NSMutableArray* j = [[NSMutableArray alloc] init];
    NSNumber* number;
    for (NSInteger i=startIndex; i<endIndex; i++) {
        number = [self.kdj_d objectAtIndex:i];
        [d addObject:number];
        number = [self.kdj_j objectAtIndex:i];
        [j addObject:number];
        number = [self.kdj_k objectAtIndex:i];
        [k addObject:number];
    }
    kdjViewController.kdj_k = k;
    kdjViewController.kdj_d = d;
    kdjViewController.kdj_j = j;
    [kdjViewController refresh:0 andStock:self.stockInfo];
}

- (IBAction)typeSegmentChanged:(id)sender {
    int delta = 1;
    UISegmentedControl* control = self.typeSegmentController;
    int maxCount = 10;
    isKLine = YES;
    switch (control.selectedSegmentIndex) {
        case 0:
            delta = ONE_MINUTE;
            isKLine = NO;
            maxCount = 30;
            break;
        case 1:
            delta = FIVE_MINUTES;
            maxCount = 24;
            break;
        case 2:
            delta = FIFTEEN_MINUTES;
            maxCount = 16;
            break;
        case 3:
            delta = THIRTY_MINUTES;
            maxCount = 16;
            break;
        case 4:
            delta = ONE_HOUR;
            maxCount = 20;
            break;
        case 5:
            delta = ONE_DAY;
            maxCount = 20;
            break;
        case 6:
            delta = ONE_WEEK;
            maxCount = 20;
            break;
        default:
            break;
    }
    klineViewController.timeDelta = delta;
    CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:self.stockInfo andDelta:delta andCount:MAX_COUNT];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        self.kdj_d = _self.kdj_d;
        self.kdj_j = _self.kdj_j;
        self.kdj_k = _self.kdj_k;
        
        self.volArray = _self.volValues;
        self.priceArray = _self.priceKValues;
        startIndex = [_self.priceKValues count] - 20;
        endIndex = [_self.priceKValues count];
        [self refreshKDJ];
        [self redraw];
    };
    
    [[KingdaWorker getInstance] queue:task];
    
    if ([klineViewController isEditLine]) {
        [self finishButtonClicked:nil];
    }
}

- (IBAction)addButtonClicked:(id)sender {
    [klineViewController startEditLine];
    [self refreshEditLineButtons];
}

- (IBAction)finishButtonClicked:(id)sender {
    [klineViewController endEditLine];
    [self refreshEditLineButtons];
}
@end
