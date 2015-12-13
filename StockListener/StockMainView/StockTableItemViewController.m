//
//  StockTableItemViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/10/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockTableItemViewController.h"
#import "StockInfo.h"
#import "StockPlayerManager.h"
#import "DatabaseHelper.h"

#define NAME 101
#define PRICE 102
#define RATE 103
#define SID 104
#define DELETE 105
#define HEADSET 106

#define HEADSET_HIDE 0.2
#define HEADSET_SHOW 1

@implementation StockTableItemViewController

@synthesize nowPLayingSID;

- (NSString*) valueToStr:(NSString*)str {
//    NSString* str = [NSString stringWithFormat:@"%.3f", value];
    int index = (int)[str length] - 1;
    for (; index >= 0; index--) {
        char c = [str characterAtIndex:index];
        if (c !='0') {
            break;
        }
    }
    if (index <= 0) {
        return @"0";
    }
    if ([str characterAtIndex:index] == '.') {
        index--;
    }
    if (index <= 0) {
        return @"0";
    }
    str = [str substringToIndex:index+1];
    return str;
}

#define IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

-(void) headsetClicked:(id)headsetImg {
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
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    [self.player playByIndex:(int)indexPath.row];
}

-(void) deleteClicked:(id)b {
    UIButton *button = (UIButton *)b;
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
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    if (indexPath.row >= [self.dbHelper.stockList count]) {
        return;
    }
    StockInfo* info = [self.dbHelper.stockList objectAtIndex:indexPath.row];
    [self.dbHelper removeStockBySID:info.sid];
}

-(UITableViewCell*) getTableViewCell:(UITableView*)tableView andInfo:(StockInfo*)info {
    static NSString *flag=@"StockTableViewCellFlag";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:flag];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"StockTableItemView" owner:self options:nil] lastObject];
        [cell setValue:flag forKey:@"reuseIdentifier"];
        UIButton* headSetImg = [cell viewWithTag:HEADSET];
        [headSetImg addTarget:self action:@selector(headsetClicked:) forControlEvents:UIControlEventTouchUpInside];
        UIButton* delete = [cell viewWithTag:DELETE];
        [delete addTarget:self action:@selector(deleteClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    UILabel* nameLabel = [cell viewWithTag:NAME];
    UILabel* priceLabel = [cell viewWithTag:PRICE];
    UILabel* rateLabel = [cell viewWithTag:RATE];
    UILabel* sid = [cell viewWithTag:SID];
    UIButton* headSetImg = [cell viewWithTag:HEADSET];
    
    if (nowPLayingSID != nil) {
        if ([nowPLayingSID isEqualToString:info.sid]) {
            [headSetImg setAlpha:HEADSET_SHOW];
        } else {
            [headSetImg setAlpha:HEADSET_HIDE];
        }
    } else {
        [headSetImg setAlpha:HEADSET_HIDE];
    }

    [nameLabel setText:info.name];

    NSString* priceStr = [NSString stringWithFormat:@"%.3f", info.price];
    priceStr = [self valueToStr:priceStr];
    [priceLabel setText:priceStr];

    NSString* rateStr = [NSString stringWithFormat:@"%.2f%%", info.changeRate * 100];
    rateStr = [self valueToStr:rateStr];
    [rateLabel setText:rateStr];
    
    [sid setText:info.sid];
    
    float changeRate = [rateStr floatValue];
    if (changeRate > 0) {
        [priceLabel setTextColor:[UIColor redColor]];
        [rateLabel setTextColor:[UIColor redColor]];
        [rateLabel setText:[NSString stringWithFormat:@"+%@", rateStr]];
    } else if (changeRate < 0) {
        [priceLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
        [rateLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    }
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end
