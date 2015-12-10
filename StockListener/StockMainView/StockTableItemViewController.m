//
//  StockTableItemViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/10/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockTableItemViewController.h"
#import "StockInfo.h"

#define NAME 101
#define PRICE 102
#define RATE 103

@implementation StockTableItemViewController

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

-(UITableViewCell*) getTableViewCell:(UITableView*)tableView andInfo:(StockInfo*)info {
    static NSString *flag=@"StockTableViewCellFlag";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:flag];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"StockTableItemView" owner:self options:nil] lastObject];
        [cell setValue:flag forKey:@"reuseIdentifier"];
    }
    UILabel* nameLabel = [cell viewWithTag:NAME];
    UILabel* priceLabel = [cell viewWithTag:PRICE];
    UILabel* rateLabel = [cell viewWithTag:RATE];

    [nameLabel setText:info.name];

    NSString* priceStr = [NSString stringWithFormat:@"%.3f", info.currentPrice];
    priceStr = [self valueToStr:priceStr];
    [priceLabel setText:priceStr];

    NSString* rateStr = [NSString stringWithFormat:@"%.2f%%", info.changeRate * 100];
    rateStr = [self valueToStr:rateStr];
    [rateLabel setText:rateStr];
    
    float changeRate = [rateStr floatValue];
    if (changeRate > 0) {
        [priceLabel setTextColor:[UIColor redColor]];
        [rateLabel setTextColor:[UIColor redColor]];
        [rateLabel setText:[NSString stringWithFormat:@"+%@", rateStr]];
    } else if (changeRate < 0) {
        [priceLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
        [rateLabel setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    }
    
    return cell;
}

@end
