//
//  StockListViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/30/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockListViewController.h"
#import "StockPlayerManager.h"
#import "DatabaseHelper.h"
#import "KingdaWorker.h"
#import "DatabaseHelper.h"
#import "SearchStockController.h"
#import "StockInfo.h"
#import "StockTableItemViewController.h"
#import "StockRefresher.h"
#import "CERoundProgressView.h"

@interface StockListViewController ()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UISearchResultsUpdating, OnStockListChangedDelegate> {
    NSInteger stockSelected;
}
@property(nonatomic, strong) UISearchController *searchController;
@property(nonatomic, strong) SearchStockController* searchStockController;
@property (weak, nonatomic) IBOutlet CERoundProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *stockTitle;
@property(nonatomic, strong) StockTableItemViewController* stockTableItemViewController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *shValue;
@property (weak, nonatomic) IBOutlet UILabel *szValue;
@property (weak, nonatomic) IBOutlet UILabel *chuangValue;
@end

@implementation StockListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    self.tableView.tableHeaderView = self.searchController.searchBar;
    _searchController.searchBar.placeholder = @"股票代码/拼音简写/名称";
    
    // Init stock list
    [[DatabaseHelper getInstance] setDelegate:self];
    
    _searchStockController = [[SearchStockController alloc] init];
    __weak StockListViewController* _self = self;
    _searchStockController.onStockListGotBlock = ^() {
        [_self.tableView reloadData];
    };
    _stockTableItemViewController = [[StockTableItemViewController alloc] init];
    [_stockTableItemViewController setTableView:self.tableView];
    [_stockTableItemViewController setViewController:self];
    
    stockSelected = -1;
    
    //    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = view;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0f);
    
    UIColor *tintColor = [UIColor redColor];
    [[CERoundProgressView appearance] setTintColor:tintColor];
    self.progressView.trackColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    self.progressView.startAngle = (3.0*M_PI)/2.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStockValueRefreshed)
                                                 name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPlayerStatusChanged:)
                                                 name:STOCK_PLAYER_STETE_NOTIFICATION
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidUnload {
    [self setProgressView:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.searchController.active) {
        return [self.searchStockController.searchList count];
    }else{
        return [[DatabaseHelper getInstance].stockList count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        return 44;
    } else {
        if (stockSelected == indexPath.row) {
            return 135;
        }
        return 60;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.searchController.active) {
        static NSString *flag=@"searchCellFlag";
        UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:flag];
        if (cell==nil) {
            cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:flag];
        }
        NSString* tmp = self.searchStockController.searchList[indexPath.row];
        NSArray* array = [tmp componentsSeparatedByString:@":"];
        if ([array count] == 2) {
            NSString* name = [array objectAtIndex:1];
            NSString* sid = [array objectAtIndex:0];
            [cell.textLabel setText:[NSString stringWithFormat:@"%@  %@", sid, name]];
        } else {
            [cell.textLabel setText:@""];
        }
        return cell;
    }
    else{
        StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:indexPath.row];
        BOOL selected = NO;
        if (indexPath.row == stockSelected) {
            selected = YES;
        }
        UITableViewCell* cell2 = [self.stockTableItemViewController getTableViewCell:tableView andInfo:info andSelected:selected];
        return cell2;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        if (indexPath.row >= [self.searchStockController.searchList count]) {
            return;
        }
        NSString* tmp = self.searchStockController.searchList[indexPath.row];
        NSArray* array = [tmp componentsSeparatedByString:@":"];
        if ([array count] == 2) {
            NSString* sid = [array objectAtIndex:0];
            [self addBySID:sid];
        } else {
        }
        [self.searchController setActive:NO];
    } else {
        [tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];
        [tableView beginUpdates];
        if (stockSelected == indexPath.row) {
            stockSelected = -1;
            [tableView endUpdates];
            return;
        }
        
        stockSelected = indexPath.row;
        [tableView endUpdates];
    }
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    [self.searchStockController search:searchString];
    [self.tableView reloadData];
}

- (void) addBySID:(NSString*)sid {
    [[DatabaseHelper getInstance] addStockBySID:sid];
}

-(void)onStockListChanged {
    if (!self.searchController.active) {
        [self.tableView reloadData];
    }
}

- (void)onStockValueRefreshed {
    [self.tableView reloadData];
    
    //Da pan
    StockInfo* info = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    NSMutableString* str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.shValue setText:str];
    if (info.changeRate < 0) {
        [self.shValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.shValue setTextColor:[UIColor redColor]];
    }
    
    info = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.szValue setText:str];
    if (info.changeRate < 0) {
        [self.szValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.szValue setTextColor:[UIColor redColor]];
    }
    
    info = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.chuangValue setText:str];
    if (info.changeRate < 0) {
        [self.chuangValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.chuangValue setTextColor:[UIColor redColor]];
    }
}
- (IBAction)onAutoSwitchChanged:(id)sender {
    UISegmentedControl* control = (UISegmentedControl*)sender;
    if (control.selectedSegmentIndex == 0) {
        [[StockPlayerManager getInstance] setIsAudoChoose:NO];
    } else {
        [[StockPlayerManager getInstance] setIsAudoChoose:YES];
    }
}

-(void) onPlayerStatusChanged:(NSNotification*)notification {
    StockInfo* info = [notification object];
    if (info != nil) {
        [self.stockTitle setText:info.name];
        [self.stockTableItemViewController setNowPLayingSID:info.sid];
        [self.tableView reloadData];
    } else {
        [self.stockTitle setText:@"听股市"];
        [self.stockTableItemViewController setNowPLayingSID:nil];
        [self.tableView reloadData];
    }
}

@end
