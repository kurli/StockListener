//
//  ViewController.m
//  StockListener
//
//  Created by Guozhen Li on 11/26/15.
//  Copyright (c) 2015 Guangzhen Li. All rights reserved.
//

#import "ViewController.h"
#import "KingdaWorker.h"
#import "FSAudioController.h"
#import "DatabaseHelper.h"
#import "SearchStockController.h"
#import "StockInfo.h"

@interface ViewController () {
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic, strong) UISearchController *searchController;
@property(nonatomic, strong) DatabaseHelper* dbHelper;
@property (weak, nonatomic) IBOutlet UILabel *stockTitle;
@property(nonatomic, strong) SearchStockController* searchStockController;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _searchStockController = [[SearchStockController alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    self.tableView.tableHeaderView = self.searchController.searchBar;
    _searchController.searchBar.placeholder = @"股票代码";
    
    // Init stock list
    _dbHelper = [[DatabaseHelper alloc] init];
    [_dbHelper setDelegate:self];
    
    player = [[StockPlayerManager alloc] init];
    [player setDelegate:self];

    [player setStockPlayList:self.dbHelper.stockList];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputDeviceChanged:)name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
}

- (void)outputDeviceChanged:(NSNotification *)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [player pause];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause: /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlPlay:  /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if ([player isPlaying]) {
                    [player pause];
                } else {
                    [player play];
                }
                break;
            case UIEventSubtypeMotionShake:
            case UIEventSubtypeRemoteControlNextTrack:
                [player next];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [player pre];
                break;
            default:
                break;
        }
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.searchController.active) {
        return [self.searchStockController.searchList count];
    }else{
        return [self.dbHelper.stockList count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *flag=@"cellFlag";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:flag];
    if (cell==nil) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:flag];
    }
    if (self.searchController.active) {
        [cell.textLabel setText:self.searchStockController.searchList[indexPath.row]];
    }
    else{
        NSArray* stockList = self.dbHelper.stockList;
        if (indexPath.row >= [stockList count]) {
            [cell.textLabel setText:@"N/A"];
        }
        StockInfo* info = [stockList objectAtIndex:indexPath.row];
        if ([info.name length] == 0) {
            [cell.textLabel setText:info.sid];
        } else {
            [cell.textLabel setText:info.name];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        if (indexPath.row >= [self.searchStockController.searchList count]) {
            return;
        }
        [self addBySID:[self.searchStockController.searchList objectAtIndex:indexPath.row]];
        [self.searchController setActive:NO];
    } else {
        if (indexPath.row >= [self.dbHelper.stockList count]) {
            return;
        }
        StockInfo* info = [self.dbHelper.stockList objectAtIndex:indexPath.row];
        [self.dbHelper removeStockBySID:info.sid];
    }
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if ([searchString length] == 0) {
        [self.searchStockController.searchList removeAllObjects];
        [self.tableView reloadData];
        return;
    }
    
    [self.searchStockController search:searchString];
    [self.tableView reloadData];
}

- (void) addBySID:(NSString*)sid {
    [self.dbHelper addStockBySID:sid];
}

-(void)onStockListChanged {
    if (!self.searchController.active) {
        [self.tableView reloadData];
    }
//    [player pause];
//    [player setStockPlayList:self.dbHelper.stockList];
}

- (IBAction)playButtonClicked:(id)sender {
    if (![player isPlaying]) {
        [player play];
    } else {
        [player pause];
    }
}

- (IBAction)preButtonClicked:(id)sender {
    [player pre];
}

- (IBAction)nextButtonClicked:(id)sender {
    [player next];
}

-(void) onPlaying:(StockInfo*)info {
    [self.stockTitle setText:info.name];
    [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
}

-(void) onPLayPaused {
    [self.stockTitle setText:@"听股市"];
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
}

@end
