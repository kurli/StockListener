//
//  KDJViewController.h
//  StockListener
//
//  Created by Guozhen Li on 1/11/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StockInfo;

@interface KDJViewController : NSObject

-(id) initWithParentView:(UIView*)view;

-(void) setFrame:(CGRect)rect;

-(void) refresh:(NSInteger)type andStock:(StockInfo*)info;

-(void) setSplitX:(NSInteger)x;

-(void) clearPlot;

-(void) removeFromSuperView;

@property (nonatomic, assign) NSInteger todayStartIndex;
@property (nonatomic, strong) NSMutableArray* kdj_k;
@property (nonatomic, strong) NSMutableArray* kdj_d;
@property (nonatomic, strong) NSMutableArray* kdj_j;
@property (nonatomic, assign) BOOL isShowSnapshot;

@property (weak, nonatomic) IBOutlet UILabel *kdjInfo1;
@property (weak, nonatomic) IBOutlet UILabel *kdjInfo5;
@property (weak, nonatomic) IBOutlet UILabel *kdjInfo15;
@property (weak, nonatomic) IBOutlet UILabel *kdjInfo30;
@property (weak, nonatomic) IBOutlet UILabel *kdjInfo60;
@property (weak, nonatomic) IBOutlet UILabel *kdjInfoDay;
@property (weak, nonatomic) IBOutlet UILabel *kdjInfoWeek;
@end
