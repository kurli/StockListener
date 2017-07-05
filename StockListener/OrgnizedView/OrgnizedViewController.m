//
//  OrgnizedViewController.m
//  StockListener
//
//  Created by Guozhen Li on 6/15/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "OrgnizedViewController.h"
#import "ZSYPopoverListView.h"
#import "DatabaseHelper.h"
#import "StockInfo.h"
#import "OrgnizedItem.h"
#import "KLineViewController.h"
#import "StockKDJViewController.h"
#import "AVOLChartViewController.h"
#import "KDJViewController.h"
#import "VOLChartViewController.h"
#import "OrgnizedViewUpdator.h"

#define ADDITEM_STOCK 0
#define ADDITEM_TYPE 1

#define KLINE_HEIGHT 130
#define KDJ_HEIGHT 50
#define VOL_HEIGHT 30

@interface OrgnizedViewController ()<ZSYPopoverListDatasource, ZSYPopoverListDelegate> {
    ZSYPopoverListView* listView;
    int listViewType;
    int currentViewY;
    NSInteger selectionType;
}

@property (strong, nonatomic) NSString* addSID;
@property (unsafe_unretained, nonatomic) NSInteger addType;
@property (unsafe_unretained, nonatomic) NSInteger addDelta;
@property (nonatomic,strong) NSTimer *kdjTypeHideTimer;
@property (nonatomic, strong) OrgnizedViewUpdator* updator;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *addItemView;
@property (weak, nonatomic) IBOutlet UIButton *addItemStockButton;
@property (weak, nonatomic) IBOutlet UIButton *addItemTypeButton;
@property (weak, nonatomic) IBOutlet UIButton *addItemTimeButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentController;
@end

@implementation OrgnizedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.scrollView.scrollEnabled = YES;
    self.addSID = nil;
    self.addType = ORGNIZED_TYPE_NONE;
    self.addDelta = 5;
    currentViewY = 0;
    selectionType = 1000;
    self.updator = [[OrgnizedViewUpdator alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appHasGoneInForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) appHasGoneInForeground:(id)data {
    [self.updator updateOrgnizedStocks];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showAllOrgnizedItems];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////
-(void) showAllOrgnizedItems {
    currentViewY = 0;
    NSArray* array = [DatabaseHelper getInstance].orgnizedList;
    for (UIView* view in [self.scrollView subviews]) {
        [view removeFromSuperview];
    }
    [self.scrollView addSubview:self.addItemView];
    for (NSInteger index = 0; index < [array count]; index++) {
        OrgnizedItem* item = [array objectAtIndex:index];
//        [item.klineViewController removeFromSuperView];
//        [item.kdjViewController removeFromSuperView];
//        [item.aVolController removeFromSuperView];
//        [item.volController removeFromSuperView];
        [self addOrgnizedView:item andIndex:index];
    }
    
    CGRect addItemViewFrame = self.addItemView.frame;
    
    addItemViewFrame.origin.x = 0;
    addItemViewFrame.origin.y = currentViewY;
    [self.addItemView setFrame:addItemViewFrame];

    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, currentViewY + self.addItemView.frame.size.height*2)];
    [self.updator updateOrgnizedStocks];
}

-(void) deleteClicked:(id)btn {
    UIButton* button = (UIButton*)btn;
    NSInteger index = button.tag;
    [[DatabaseHelper getInstance] removeOrgnizedItemByIndex:index];
    [self showAllOrgnizedItems];
}

-(void) addKLineView:(OrgnizedItem*) info {
    info.klineViewController = [[KLineViewController alloc] initWithParentView:self.scrollView];

    float leftWidth = ((int)(self.scrollView.frame.size.width/100*85)/(DEFAULT_DISPLAY_COUNT-1))*(DEFAULT_DISPLAY_COUNT-1);
    [info.klineViewController setFrame:CGRectMake(0, currentViewY, leftWidth, KLINE_HEIGHT)];
    [info.klineViewController hideInfoButton];

    float rightViewWidth = self.scrollView.frame.size.width - leftWidth;
    info.aVolController = [[AVOLChartViewController alloc] initWithParentView:self.scrollView];
    CGRect rect = CGRectMake(leftWidth, currentViewY, rightViewWidth, KLINE_HEIGHT);
    [info.aVolController loadViewVertical:rect];
    
    currentViewY += KLINE_HEIGHT;
}

-(void) addKDJView:(OrgnizedItem*) info {
    info.kdjViewController = [[KDJViewController alloc] initWithParentView:self.scrollView];
    
    float leftWidth = ((int)(self.scrollView.frame.size.width/100*85)/(DEFAULT_DISPLAY_COUNT-1))*(DEFAULT_DISPLAY_COUNT-1);
    [info.kdjViewController setFrame:CGRectMake(0, currentViewY, leftWidth, KDJ_HEIGHT)];
    
    currentViewY += KDJ_HEIGHT;
}

-(void) addVOLView:(OrgnizedItem*) info {
    info.volController = [[VOLChartViewController alloc] initWithParentView:self.scrollView];
    float leftWidth = ((int)(self.scrollView.frame.size.width/100*85)/(DEFAULT_DISPLAY_COUNT-1))*(DEFAULT_DISPLAY_COUNT-1);
    CGRect rect2 = CGRectMake(20, currentViewY, leftWidth-LEFT_PADDING, VOL_HEIGHT);
    [info.volController loadView:rect2];
    
    currentViewY += VOL_HEIGHT;
}

-(NSString*) timeToStr:(NSInteger)type {
    if (type == ONE_MINUTE) {
        return @"1分";
    } else if (type == FIVE_MINUTES) {
        return @"5分";
    } else if (type == FIFTEEN_MINUTES) {
        return @"15分";
    } else if (type == THIRTY_MINUTES) {
        return @"30分";
    } else if (type == ONE_HOUR) {
        return @"60分";
    } else if (type == ONE_DAY) {
        return @"1日";
    } else if (type == ONE_WEEK) {
        return @"1周";
    }
    return @"";
}

-(void) addOrgnizedView:(OrgnizedItem*) item andIndex:(NSInteger) index {
    StockInfo* stockInfo = [[DatabaseHelper getInstance] getInfoById:item.sid];
    if (stockInfo == nil) {
        return;
    }

    ///
    float leftWidth = ((int)(self.scrollView.frame.size.width/100*85)/(DEFAULT_DISPLAY_COUNT-1))*(DEFAULT_DISPLAY_COUNT-1);
    float rightViewWidth = self.scrollView.frame.size.width - leftWidth;
    UILabel* label = [[UILabel alloc] init];
    UIFont *font = [UIFont systemFontOfSize: 15];
    label.font = font;
    [label setText:stockInfo.name];
    [label setFrame:CGRectMake(5, currentViewY, font.lineHeight*4, font.lineHeight)];
    [self.scrollView addSubview:label];
    
    UIButton* button2 = [[UIButton alloc] initWithFrame:CGRectMake(font.lineHeight*4 + 20, currentViewY, font.lineHeight*4, font.lineHeight)];
    button2.titleLabel.font = font;
    [button2 setBackgroundColor:[UIColor blueColor]];
    NSString* str = [self timeToStr:item.delta];
    [button2 setTitle:str forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(addItemTimeClicked:) forControlEvents:UIControlEventTouchUpInside];
    button2.tag = index;
    [self.scrollView addSubview:button2];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(self.scrollView.frame.size.width - font.lineHeight*4 - rightViewWidth, currentViewY, font.lineHeight*4, font.lineHeight)];
    button.titleLabel.font = font;
    [button setBackgroundColor:[UIColor redColor]];
    [button setTitle:@"删除" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(deleteClicked:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = index;
    [self.scrollView addSubview:button];

    currentViewY += label.frame.size.height;
    ///
    
    if (item.type == ORGNIZED_TYPE_KLINE) {
        [self addKLineView:item];
    } else if (item.type == ORGNIZED_TYPE_KDJ) {
        [self addKDJView:item];
    } else if (item.type == ORGNIZED_TYPE_VOL) {
        [self addVOLView:item];
    }
}
////////

- (IBAction)finishButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addItemStockClicked:(id)sender {
    listView = [[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 250, 350)];
    listView.datasource = self;
    listView.titleName.text = @"请选择";
    listView.delegate = self;
    listViewType = ADDITEM_STOCK;
    [listView show];
}

- (IBAction)addItemTypeClicked:(id)sender {
    listView = [[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 250, 350)];
    listView.datasource = self;
    listView.titleName.text = @"请选择";
    listView.delegate = self;
    listViewType = ADDITEM_TYPE;
    [listView show];
}

- (IBAction)addItemAddClicked:(id)sender {
    if ([self.addSID length] == 0 || self.addType == ORGNIZED_TYPE_NONE || self.addDelta == 0) {
        return;
    }
    OrgnizedItem* item = [[OrgnizedItem alloc] init];
    [item setSid:self.addSID];
    [item setType:self.addType];
    [item setDelta:self.addDelta];
    [[DatabaseHelper getInstance] addOrgnizedItem:item];

    self.addSID = nil;
    self.addType = ORGNIZED_TYPE_NONE;
    self.addDelta = 5;
    
    [self.addItemStockButton setTitle:@"股票" forState:UIControlStateNormal];
    [self.addItemTypeButton setTitle:@"类型" forState:UIControlStateNormal];
    [self.addItemTimeButton setTitle:@"5分" forState:UIControlStateNormal];

    [self showAllOrgnizedItems];
}

-(void)onHideKDJTypeFired {
    [self.segmentController setHidden:YES];
    [self.kdjTypeHideTimer invalidate];
    [self setKdjTypeHideTimer:nil];
}

- (IBAction)addItemTimeClicked:(id)sender {
    UIButton* button = (UIButton*)sender;
    CGRect rect = self.segmentController.frame;
    if (button.tag == 1000) {
        if ([[DatabaseHelper getInstance].orgnizedList count] == 0) {
            rect.origin.y =  self.addItemView.frame.origin.y - self.scrollView.contentOffset.y + self.scrollView.frame.origin.y + self.addItemView.frame.size.height;
        } else {
            rect.origin.y =  self.addItemView.frame.origin.y - self.scrollView.contentOffset.y;
        }
    } else {
        rect.origin.y = button.frame.origin.y + button.frame.size.height + self.segmentController.frame.size.height*2 - self.scrollView.contentOffset.y;
    }
    
    selectionType = button.tag;

    [self.segmentController setFrame:rect];
    [self.segmentController setHidden:NO];
    self.kdjTypeHideTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(onHideKDJTypeFired) userInfo:nil repeats:NO];
}

- (IBAction)segmentTouchOutside:(id)sender {
    [self onHideKDJTypeFired];
}

- (IBAction)segmentChanged:(id)sender {
    UISegmentedControl* control = sender;
    NSInteger delta = 0;
    NSString* str;
        switch (control.selectedSegmentIndex) {
            case 0:
                delta = ONE_MINUTE;
                str = @"1分";
                break;
            case 1:
                delta = FIVE_MINUTES;
                str = @"5分";
                break;
            case 2:
                delta = FIFTEEN_MINUTES;
                str = @"15分";
                break;
            case 3:
                delta = THIRTY_MINUTES;
                str = @"30分";
                break;
            case 4:
                delta = ONE_HOUR;
                str = @"60分";
                break;
            case 5:
                delta = ONE_DAY;
                str = @"天";
                break;
            case 6:
                delta = ONE_WEEK;
                str = @"周";
                break;
            default:
                break;
        }
    if (selectionType == 1000) {
        self.addDelta = delta;
        [self.addItemTimeButton setTitle:str forState:UIControlStateNormal];
    } else {
        if (selectionType < [[DatabaseHelper getInstance].orgnizedList count]) {
            OrgnizedItem* item = [[DatabaseHelper getInstance].orgnizedList objectAtIndex:selectionType];
            item.delta = delta;
            [self showAllOrgnizedItems];
        }
    }
    [self onHideKDJTypeFired];
}

#pragma popoverview delegate

- (NSInteger)popoverListView:(ZSYPopoverListView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (listViewType == ADDITEM_STOCK) {
        return [[DatabaseHelper getInstance].stockList count];
    } else if (listViewType == ADDITEM_TYPE) {
        return 3;
    }
    return 0;
}

- (UITableViewCell *)popoverListView:(ZSYPopoverListView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"identifier";
    UITableViewCell *cell = [tableView dequeueReusablePopoverCellWithIdentifier:identifier];
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.imageView.image = [UIImage imageNamed:@"selection_normal.png"];
    
    if (listViewType == ADDITEM_STOCK) {
        StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:indexPath.row];
        NSString* rateStr = [NSString stringWithFormat:@"%.2f%%", info.changeRate * 100];
        cell.textLabel.text = [NSString stringWithFormat:@"%@  %@",info.name, rateStr];
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"K线+BOLL线+成本分布";
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"KDJ";
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"成交量";
        }
    }
    return cell;
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView popoverCellForRowAtIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
    
    if (listViewType == ADDITEM_STOCK) {
        StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:indexPath.row];
        [self.addItemStockButton setTitle:info.name forState:UIControlStateNormal];
        self.addSID = info.sid;
    } else {
        if (indexPath.row == 0) {
            [self.addItemTypeButton setTitle:@"k线" forState:UIControlStateNormal];
            self.addType = ORGNIZED_TYPE_KLINE;
        } else if (indexPath.row == 1) {
            [self.addItemTypeButton setTitle:@"KDJ" forState:UIControlStateNormal];
            self.addType = ORGNIZED_TYPE_KDJ;
        } else if (indexPath.row == 2) {
            [self.addItemTypeButton setTitle:@"成交量" forState:UIControlStateNormal];
            self.addType = ORGNIZED_TYPE_VOL;
        }
    }
    [listView dismiss];
}

@end
