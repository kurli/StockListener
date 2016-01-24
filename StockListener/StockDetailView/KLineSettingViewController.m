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

@interface KLineSettingViewController () {
    KLineViewController* klineViewController;
    VOLChartViewController* volController;
    NSInteger startIndex;
    NSInteger endIndex;
    float kViewWidth;
    BOOL isKLine;
}

@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegmentController;
@property (weak, nonatomic) IBOutlet UIView *ylineTypeView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ylineTypeSegmentController;
@property (strong, nonatomic) NSArray* volArray;
@property (strong, nonatomic) NSArray* priceArray;
@end

@implementation KLineSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    klineViewController = [[KLineViewController alloc] initWithParentView:self.view];
    [klineViewController hideInfoButton];
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
            NSLog(@"%ld %f", d, zoom);
            if (startIndex + d < 0) {
                d = -startIndex;
                NSLog(@"1: %ld", d);
            }
            if (startIndex + d >= endIndex - 10) {
                d = endIndex - startIndex - 10;
                NSLog(@"2: %ld", d);
            }
            startIndex += d;
            NSLog(@"%ld %ld %ld\n----", startIndex, endIndex, d);
            [_self redraw];
//            if (!finished) {
//                startIndex += d;
//            }
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [klineViewController setFrame:CGRectMake(5, self.typeSegmentController.frame.origin.y + self.typeSegmentController.frame.size.height + 1, self.view.frame.size.width-10, self.view.frame.size.height/3)];
    kViewWidth = self.view.frame.size.width-10;
    
    // Set VOL frame
    float height = self.typeSegmentController.frame.origin.y + self.typeSegmentController.frame.size.height + 1 +self.view.frame.size.height/3 + 1;
    if (volController == nil) {
        volController = [[VOLChartViewController alloc] initWithParentView:self.view];
        CGRect rect2 = CGRectMake(25, height, self.view.frame.size.width-30, 45);
        [volController loadView:rect2];
    }
    
    // Set yline view frame
    CGRect rect = self.ylineTypeView.frame;
    rect.origin.y = self.typeSegmentController.frame.origin.y + self.typeSegmentController.frame.size.height + 1 +self.view.frame.size.height/3 + 1 + 45;
    [self.ylineTypeView setFrame:rect];
    
    [self typeSegmentChanged:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)ylineTypeChanged:(id)sender {
}

-(void) redraw {
    if (startIndex < 0) {
        startIndex = 0;
    }
    if (endIndex > [self.priceArray count]) {
        endIndex = [self.priceArray count];
    }

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
    CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:self.stockInfo andDelta:delta andCount:MAX_COUNT];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        self.volArray = _self.volValues;
        self.priceArray = _self.priceKValues;
        startIndex = [_self.priceKValues count] - 20;
        endIndex = [_self.priceKValues count];

        [self redraw];
    };

    [[KingdaWorker getInstance] queue:task];
}
@end
