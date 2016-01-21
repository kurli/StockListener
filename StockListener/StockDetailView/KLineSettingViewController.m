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
}

@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegmentController;
@property (weak, nonatomic) IBOutlet UIView *ylineTypeView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ylineTypeSegmentController;
@end

@implementation KLineSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    klineViewController = [[KLineViewController alloc] initWithParentView:self.view];
    [klineViewController hideInfoButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [klineViewController setFrame:CGRectMake(5, self.typeSegmentController.frame.origin.y + self.typeSegmentController.frame.size.height + 1, self.view.frame.size.width-10, self.view.frame.size.height/3)];
    
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

-(void) refreshVOL:(NSInteger) startIndex andVolValues:(NSArray*)volValues {
    //VOL
    startIndex++;
    volController.volValues = [[NSMutableArray alloc] init];
    for (NSInteger i=startIndex; i<[volValues count]; i++) {
        NSNumber* vol = [volValues objectAtIndex:i];
        [volController.volValues addObject:vol];
    }
    // Insert zero for remaining
//    NSInteger count = [volController.volValues count] - MAX_DISPLAY_COUNT + 1;
//    for (NSInteger i=0; i<count; i++) {
//        [volController.volValues addObject:[NSNumber numberWithInteger:0]];
//    }
    [volController reload];
}

- (IBAction)typeSegmentChanged:(id)sender {
    int delta = 1;
    UISegmentedControl* control = self.typeSegmentController;
    switch (control.selectedSegmentIndex) {
        case 0:
            delta = ONE_MINUTE;
            break;
        case 1:
            delta = FIVE_MINUTES;
            break;
        case 2:
            delta = FIFTEEN_MINUTES;
            break;
        case 3:
            delta = THIRTY_MINUTES;
            break;
        case 4:
            delta = ONE_HOUR;
            break;
        case 5:
            delta = ONE_DAY;
            break;
        case 6:
            delta = ONE_WEEK;
            break;
        default:
            break;
    }
    CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:self.stockInfo andDelta:delta andCount:MAX_COUNT];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        klineViewController.todayStartIndex = _self.todayStartIndex;
        klineViewController.priceKValues = _self.priceKValues;

        [self refreshVOL:0 andVolValues:_self.volValues];
        
        [klineViewController refresh];
    };

    [[KingdaWorker getInstance] queue:task];
}
@end
