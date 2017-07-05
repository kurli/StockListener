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
#import "TestColorViewController.h"
#import "ConfigHelper.h"
#import "DatabaseHelper.h"
#import "GetTodayStockValue.h"
#import "GetWeeksStockValue.h"
#import "GetFiveDayStockValue.h"
#import "GetDaysStockValue.h"
#import "SyncPoint.h"

#define AVOL_SETTING 0
#define STOCK_CHANGE 1

@interface KLineSettingViewController () <UITableViewDelegate,UITableViewDataSource> {
    KLineViewController* klineViewController;
    VOLChartViewController* volController;
    AVOLChartViewController* aVolController;
    KDJViewController* kdjViewController;
    NSInteger startIndex;
    NSInteger endIndex;
    BOOL isKLine;
    
//    UIButton* aVolSettingButton;
    ZSYPopoverListView* aVolSettingView;
    ZSYPopoverListView* stockListView;

    BOOL isAVOLDynamic;
    NSInteger avolDynamicType;
    NSInteger setting;
    
    float klineViewHeight;
}

@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegmentController;
//@property (weak, nonatomic) IBOutlet UIView *ylineTypeView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ylineTypeSegmentController;
@property (strong, nonatomic) NSArray* volArray;
@property (strong, nonatomic) NSArray* priceArray;
@property (strong, nonatomic) NSMutableArray* kdj_k;
@property (strong, nonatomic) NSMutableArray* kdj_d;
@property (strong, nonatomic) NSMutableArray* kdj_j;
@property (strong, nonatomic) NSMutableArray* boll_ma;
@property (strong, nonatomic) NSMutableArray* boll_md;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UILabel *addLabel;
@property (weak, nonatomic) IBOutlet UIButton *finishButton;
@property (weak, nonatomic) IBOutlet UITableView *lineTableView;
@property (weak, nonatomic) IBOutlet UILabel *dynamicAVOLLabel;
@property (weak, nonatomic) IBOutlet UIButton *dynamicAVOLButton;
@property (weak, nonatomic) IBOutlet UIButton *stockNameButton;
@property (weak, nonatomic) IBOutlet UIView *topView;
@end

@implementation KLineSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    klineViewController = [[KLineViewController alloc] initWithParentView:self.view];
    [klineViewController hideInfoButton];
    klineViewController.stockInfo = self.stockInfo;
    kdjViewController = [[KDJViewController alloc] initWithParentView:self.view];
    
//    aVolSettingButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
//    [aVolSettingButton addTarget:self action:@selector(aVolSettingClicked:) forControlEvents:UIControlEventTouchUpInside];
//    [aVolSettingButton setImage:[UIImage imageNamed:@"setting"] forState:UIControlStateNormal];
//    aVolSettingButton.layer.borderWidth = 0.5;
//    aVolSettingButton.layer.borderColor = [[UIColor grayColor] CGColor];
//    [self.view addSubview:aVolSettingButton];

    __weak KLineViewController *_weak_self = klineViewController;
    __weak KLineSettingViewController *_self = self;
    [klineViewController enableGesture];
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
    isAVOLDynamic = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    float leftWidth = ((int)(LEFT_VIEW_WIDTH)/(DEFAULT_DISPLAY_COUNT-1))*(DEFAULT_DISPLAY_COUNT-1);

    CGRect rect = self.typeSegmentController.frame;
    rect.size.width = leftWidth;
    rect.origin.x = 0;
    [self.typeSegmentController setFrame:rect];

    float rightViewWidth = self.view.frame.size.width - leftWidth;
    klineViewHeight = self.view.frame.size.height / 8 * 3;

    float y = self.typeSegmentController.frame.origin.y + self.typeSegmentController.frame.size.height + 1;
    [klineViewController setFrame:CGRectMake(0, y, leftWidth, klineViewHeight)];

    if (aVolController == nil) {
        aVolController = [[AVOLChartViewController alloc] initWithParentView:self.view];
        rect = CGRectMake(leftWidth, y - AVOL_EXPAND/2, rightViewWidth, klineViewHeight + AVOL_EXPAND);
        [aVolController loadViewVertical:rect];
        CGRect rect2 = self.addLabel.frame;
        rect2.origin.x = rect.origin.x;
        rect2.origin.y = rect.origin.y + rect.size.height + 5;
        [self.addLabel setFrame:rect2];
        CGRect rect3 = self.addButton.frame;
        rect3.origin.x = rect.origin.x;
        rect3.origin.y = rect2.origin.y + rect2.size.height;
        [self.addButton setFrame:rect3];
        CGRect rect4 = self.finishButton.frame;
        rect4.origin.x = rect3.origin.x;
        rect4.origin.y = rect3.origin.y;
        [self.finishButton setFrame:rect4];
    }

    // Set VOL frame
    y = y + klineViewHeight + 1;
    if (volController == nil) {
        volController = [[VOLChartViewController alloc] initWithParentView:self.view];
        CGRect rect2 = CGRectMake(LEFT_PADDING, y, leftWidth - LEFT_PADDING, self.typeSegmentController.frame.size.height);
        [volController loadView:rect2];
        __weak KLineSettingViewController *_self = self;
        aVolController.onItemCLicked = ^(NSInteger index) {
            [_self aVolSettingClicked:nil];
        };
    }

    y = y + self.typeSegmentController.frame.size.height + 1;
    [kdjViewController setIsShowSnapshot:NO];
    [kdjViewController setFrame:CGRectMake(0, y, leftWidth, self.typeSegmentController.frame.size.height*2.5)];
    
    y = y + self.typeSegmentController.frame.size.height*2.5;

    self.lineTableView.layer.borderWidth = 0.5;
    self.lineTableView.layer.borderColor = [[UIColor grayColor] CGColor];
    
    rect = self.lineTableView.frame;
    rect.origin.x = 0;
    rect.origin.y = y;
    rect.size.width = self.view.frame.size.width;
    rect.size.height = self.view.frame.size.height - y;
    [self.lineTableView setFrame:rect];

    [self refreshEditLineButtons];
    
    [self typeSegmentChanged:nil];
    [self.stockNameButton setTitle:self.stockInfo.name forState:UIControlStateNormal];
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
    NSMutableArray* boll_ma = [[NSMutableArray alloc] init];
    NSMutableArray* boll_md = [[NSMutableArray alloc] init];
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
        [boll_ma addObject:[self.boll_ma objectAtIndex:i]];
        [boll_md addObject:[self.boll_md objectAtIndex:i]];
    }
    float delta = (h-l)/10;
    if (delta == 0) {
        delta += 5;
    }
    h += delta;
    l -= delta;
    klineViewController.priceKValues = priceValues;
    klineViewController.boll_ma = boll_ma;
    klineViewController.bool_md = boll_md;

    [klineViewController refresh:l andHighest:h andDrawKLine:isKLine];
    [self refreshAVOLAsync:l andHighest:h];
}

-(void) refreshAVOLAsync:(float)l andHighest:(float)h{
    CalculateAVOL* task = [[CalculateAVOL alloc] initWithStockInfo:self.stockInfo];
    if (isAVOLDynamic == YES) {
        task.endIndex = endIndex;
        if (self.typeSegmentController.selectedSegmentIndex == 5) {
            task.calType = AVOL_CAL_DAYS;
        } else if (self.typeSegmentController.selectedSegmentIndex == 1) {
            task.fiveDayPrice = self.priceArray;
            task.fiveDayVOL = self.volArray;
            task.calType = AVOL_CAL_5_DAYS;
        } else {
            task.calType = AVOL_CAL_WEEKS;
        }
    }
    if ([ConfigHelper getInstance].avolCalType == AVOL_CAL_5_DAYS) {
        task.fiveDayPrice = self.priceArray;
        task.fiveDayVOL = self.volArray;
    }
    task.onCompleteBlock = ^(NSDictionary* dic) {
        [self refreshAVOL:l andHighest:h andDic:dic];
    };
    [[KingdaWorker getInstance] removeSameKindTask:task];
    [task setSourceType:CalculateAVOLTypeHistory];
    [[KingdaWorker getInstance] queue:task];
}

-(void) refreshAVOL:(float)l andHighest:(float)h andDic:(NSDictionary*)dic{
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
    
    float valuePerPixel = (float)(hh - ll)/(float)klineViewHeight ;
    float extend = valuePerPixel * (AVOL_EXPAND / 2);
    [aVolController setMin:ll-extend];
    [aVolController setMax:hh+extend];
    [aVolController setAverageVolDic:dic];
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
        self.boll_md = _self.boll_md;
        self.boll_ma = _self.boll_ma;
        
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
    klineViewController.editLineColor = RSRandomColorOpaque(YES);
    [klineViewController startEditLine];
    [self refreshEditLineButtons];
}

- (IBAction)finishButtonClicked:(id)sender {
    float k = [klineViewController getEditLineK];
    float b = [klineViewController getEditLineB];
    UIColor* color = klineViewController.editLineColor;
    CGFloat cr, cg, cb, ca;
    [color getRed:&cr green:&cg blue:&cb alpha:&ca];
    NSString* colorStr = [NSString stringWithFormat:@"(%f,%f,%f)", cr, cg, cb];
    NSString* str = [NSString stringWithFormat:@"%@ %f %f", colorStr,  k, b];
    [self.stockInfo.lines addObject:str];
    [klineViewController endEditLine];
    [self refreshEditLineButtons];

    [self.lineTableView reloadData];
}

// Delegates
#define NAME_LABEL 101
#define EDIT_BUTTON 102
#define DELETE_BUTTON 103
#define IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.stockInfo.lines count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

-(void) editClicked:(id)headsetImg {
    float k, b;
    TestColorViewController *rootController = [[TestColorViewController alloc] initWithNibName:nil bundle:nil];

    UIButton *button = (UIButton *)headsetImg;
    UIView *contentView;
    if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        contentView = [button superview];
    } else if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        contentView = [[button superview] superview];
    } else {
        contentView = [button superview];
    }
    UITableViewCell *cell = (UITableViewCell*)[contentView superview];
    if ([cell isKindOfClass:[UITableViewCell class]] == false) {
        return;
    }
    NSIndexPath *indexPath = [self.lineTableView indexPathForCell:cell];
    if (indexPath.row < [self.stockInfo.lines count]) {
        // First delete
        NSString* str = [self.stockInfo.lines objectAtIndex:indexPath.row];
        NSArray* array = [str componentsSeparatedByString:@" "];
        if ([array count] == 3) {
            NSString* colorStr = [array objectAtIndex:0];
            k = [[array objectAtIndex:1] floatValue];
            b = [[array objectAtIndex:2] floatValue];
            colorStr = [colorStr stringByReplacingOccurrencesOfString:@"(" withString:@""];
            colorStr = [colorStr stringByReplacingOccurrencesOfString:@")" withString:@""];
            NSArray* array = [colorStr componentsSeparatedByString:@","];
            CGFloat cr, cg, cb;
            if ([array count] == 3) {
                cr = [[array objectAtIndex:0] floatValue];
                cg = [[array objectAtIndex:1] floatValue];
                cb = [[array objectAtIndex:2] floatValue];
                UIColor* color = [UIColor colorWithRed:cr green:cg blue:cb alpha:1];
                rootController.color = color;
                rootController.onFinish = ^(UIColor* color) {
                    CGFloat cr, cg, cb, ca;
                    [color getRed:&cr green:&cg blue:&cb alpha:&ca];
                    NSString* colorStr = [NSString stringWithFormat:@"(%f,%f,%f)", cr, cg, cb];
                    NSString* str = [NSString stringWithFormat:@"%@ %f %f", colorStr,  k, b];
                    [self.stockInfo.lines replaceObjectAtIndex:indexPath.row withObject:str];
                    [self redraw];
                    [self.lineTableView reloadData];
                };
                [self presentViewController:rootController animated:YES completion:nil];
            }
//            float k = [[array objectAtIndex:1] floatValue];
//            float b = [[array objectAtIndex:2] floatValue];
//            [klineViewController setEditLineK:k];
//            [klineViewController setEditLineB:b];
//            [klineViewController resetEditButton];
        }
    }
}

-(void) deleteClicked:(id)headsetImg {
    UIButton *button = (UIButton *)headsetImg;
    UIView *contentView;
    if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        contentView = [button superview];
    } else if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        contentView = [[button superview] superview];
    } else {
        contentView = [button superview];
    }
    UITableViewCell *cell = (UITableViewCell*)[contentView superview];
    if ([cell isKindOfClass:[UITableViewCell class]] == false) {
        return;
    }
    NSIndexPath *indexPath = [self.lineTableView indexPathForCell:cell];
    if (indexPath.row < [self.stockInfo.lines count]) {
        [self.stockInfo.lines removeObjectAtIndex:indexPath.row];
    }
    [self.lineTableView reloadData];
    [self redraw];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *flag=@"LineTableItem";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:flag];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"LineTableItem" owner:self options:nil] lastObject];
        [cell setValue:flag forKey:@"reuseIdentifier"];
        UIButton* editButton = [cell viewWithTag:EDIT_BUTTON];
        [editButton addTarget:self action:@selector(editClicked:) forControlEvents:UIControlEventTouchUpInside];
        UIButton* deleteButton = [cell viewWithTag:DELETE_BUTTON];
        [deleteButton addTarget:self action:@selector(deleteClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    UILabel* label = [cell viewWithTag:NAME_LABEL];
    [label setText:[NSString stringWithFormat:@"辅助线 %ld", indexPath.row]];
    NSString* str = [self.stockInfo.lines objectAtIndex:indexPath.row];
    NSArray* array = [str componentsSeparatedByString:@" "];
    if ([array count] == 3) {
        NSString* colorStr = [array objectAtIndex:0];
        colorStr = [colorStr stringByReplacingOccurrencesOfString:@"(" withString:@""];
        colorStr = [colorStr stringByReplacingOccurrencesOfString:@")" withString:@""];
        NSArray* array = [colorStr componentsSeparatedByString:@","];
        CGFloat r, g, b;
        if ([array count] == 3) {
            r = [[array objectAtIndex:0] floatValue];
            g = [[array objectAtIndex:1] floatValue];
            b = [[array objectAtIndex:2] floatValue];
            UIColor* color = [UIColor colorWithRed:r green:g blue:b alpha:1];
            [label setTextColor:color];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma AVOL setting

-(void) aVolSettingClicked:(id)btn {
    aVolSettingView = [[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 250, 350)];
    aVolSettingView.datasource = self;
    aVolSettingView.titleName.text = @"成本分布设置";
    aVolSettingView.delegate = self;
    setting = AVOL_SETTING;
    [aVolSettingView show];
}

- (NSInteger)popoverListView:(ZSYPopoverListView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (setting == AVOL_SETTING) {
        return 8;
    } else {
        return [[DatabaseHelper getInstance].stockList count];
    }
}

- (UITableViewCell *)popoverListView:(ZSYPopoverListView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (setting == AVOL_SETTING) {
        static NSString *identifier = @"identifier";
        UITableViewCell *cell = [tableView dequeueReusablePopoverCellWithIdentifier:identifier];
        if (nil == cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        NSInteger avolCalType = [ConfigHelper getInstance].avolCalType;
        switch (indexPath.row) {
            case 0:
                cell.imageView.image = nil;
                cell.textLabel.text = @"设置计算周期：";
                break;
            case 1:
                if (avolCalType == AVOL_CAL_DAYS) {
                    cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
                } else {
                    cell.imageView.image = [UIImage imageNamed:@"selection_normal.png"];
                }
                cell.textLabel.text = @"    100天内的成本分布";
                break;
            case 2:
                if (avolCalType == AVOL_CAL_WEEKS) {
                    cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
                } else {
                    cell.imageView.image = [UIImage imageNamed:@"selection_normal.png"];
                }
                cell.textLabel.text = @"    100周内的成本分布";
                break;
            case 3:
                if (avolCalType == AVOL_CAL_5_DAYS) {
                    cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
                } else {
                    cell.imageView.image = [UIImage imageNamed:@"selection_normal.png"];
                }
                cell.textLabel.text = @"    5天内的成本分布";
                break;
            case 4:
                cell.imageView.image = nil;
                cell.textLabel.text = @"成本动态变动模式查看：";
                break;
            case 5:
                cell.imageView.image = nil;
                cell.textLabel.text = @"    日线成本变动模式";
                break;
            case 6:
                cell.imageView.image = nil;
                cell.textLabel.text = @"    周线成本变动模式";
                break;
            case 7:
                cell.imageView.image = nil;
                cell.textLabel.text = @"    5天成本变动模式（5分钟级别）";
                break;
            default:
                break;
        }
        return cell;
    } else {
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
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (setting == AVOL_SETTING) {
        switch (indexPath.row) {
            case 1:
                // Days
                [[ConfigHelper getInstance] setAvolCalType:AVOL_CAL_DAYS];
                [self typeSegmentChanged:nil];
                [aVolSettingView dismiss];
                break;
            case 2:
                // Weeks
                [[ConfigHelper getInstance] setAvolCalType:AVOL_CAL_WEEKS];
                [self typeSegmentChanged:nil];
                [aVolSettingView dismiss];
                break;
            case 3:
                // 5 Days
                [[ConfigHelper getInstance] setAvolCalType:AVOL_CAL_5_DAYS];
                [self typeSegmentChanged:nil];
                [aVolSettingView dismiss];
                break;
            case 5:
                [self showDynamicAVOL:AVOL_CAL_DAYS];
                [aVolSettingView dismiss];
                break;
            case 6:
                [self showDynamicAVOL:AVOL_CAL_WEEKS];
                [aVolSettingView dismiss];
                break;
            case 7:
                [self showDynamicAVOL:AVOL_CAL_5_DAYS];
                [aVolSettingView dismiss];
                break;
            default:
                break;
        }
    } else {
        UITableViewCell *cell = [tableView popoverCellForRowAtIndexPath:indexPath];
        cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
        StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:indexPath.row];
        self.stockInfo = info;
        [self.stockNameButton setTitle:info.name forState:UIControlStateNormal];
        
        klineViewController.stockInfo = self.stockInfo;
        if ([self.stockInfo.todayPriceByMinutes count] == 0) {
            GetTodayStockValue* task = [[GetTodayStockValue alloc] initWithStock:self.stockInfo];
            [[KingdaWorker getInstance] queue:task];
        }
        if ([self.stockInfo.fiveDayPriceByMinutes count] == 0) {
            GetFiveDayStockValue* task = [[GetFiveDayStockValue alloc] initWithStock:self.stockInfo];
            [[KingdaWorker getInstance] queue:task];
        }
        if ([self.stockInfo.hundredDaysPrice count] == 0) {
            GetDaysStockValue* task = [[GetDaysStockValue alloc] initWithStock:self.stockInfo];
            [[KingdaWorker getInstance] queue:task];
        }
        if ([self.stockInfo.weeklyPrice count] == 0) {
            GetWeeksStockValue* task6 = [[GetWeeksStockValue alloc] initWithStock:self.stockInfo];
            [[KingdaWorker getInstance] queue:task6];
        }
        SyncPoint* sync = [[SyncPoint alloc] init];
        sync.onCompleteBlock = ^(StockInfo* info) {
            [self refreshEditLineButtons];
            [self typeSegmentChanged:nil];
        };
        [[KingdaWorker getInstance] queue:sync];
        [stockListView dismiss];
        [self.lineTableView reloadData];
    }
}

-(void) showDynamicAVOL:(NSInteger)type {
    isAVOLDynamic = YES;
    avolDynamicType = type;
    if (type == AVOL_CAL_WEEKS) {
        [self.typeSegmentController setSelectedSegmentIndex:6];
        [self.dynamicAVOLLabel setText:@"滑动查看 周线 成本变动情况"];
    } else if (type == AVOL_CAL_5_DAYS) {
        [self.typeSegmentController setSelectedSegmentIndex:1];
        [self.dynamicAVOLLabel setText:@"滑动查看 5天 成本变动情况"];
    } else {
        [self.typeSegmentController setSelectedSegmentIndex:5];
        [self.dynamicAVOLLabel setText:@"滑动查看 日线 成本变动情况"];
    }
    [self typeSegmentChanged:nil];
    [self.typeSegmentController setHidden:YES];
    [self.dynamicAVOLButton setHidden:NO];
    [self.dynamicAVOLLabel setHidden:NO];
}

- (IBAction)dynamicAVOLCancelClicked:(id)sender {
    [self.typeSegmentController setHidden:NO];
    [self.dynamicAVOLButton setHidden:YES];
    [self.dynamicAVOLLabel setHidden:YES];
    isAVOLDynamic = NO;
}

- (IBAction)nameButtonClicked:(id)sender {
    stockListView = [[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 250, 350)];
    stockListView.datasource = self;
    stockListView.titleName.text = @"请选择";
    stockListView.delegate = self;
    setting = STOCK_CHANGE;
    [stockListView show];
}


@end
