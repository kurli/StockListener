//
//  BuySellChartViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/14/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "AVOLChartViewController.h"
#import "stockInfo.h"

// Views
#import "JBBarChartView.h"
#import "JBChartHeaderView.h"
#import "JBBarChartFooterView.h"
#import "JBChartInformationView.h"
#import "JBColorConstants.h"

#define MAX_COUNT 380

@interface AVOLChartViewController() <JBBarChartViewDelegate, JBBarChartViewDataSource> {
    UIView* view;
}
@property (nonatomic, strong) JBBarChartView *barChartView;

@end

@implementation AVOLChartViewController

-(id) initWithParentView:(UIView*)parentView {
    if (self = [super init]) {
        view = parentView;
    }
    return self;
}

- (void)dealloc
{
    _barChartView.delegate = nil;
    _barChartView.dataSource = nil;
}

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

#define degreeTOradians(x) (M_PI * (x)/180)
- (void)loadView:(CGRect) rect
{
    self.barChartView = [[JBBarChartView alloc] init];
    self.barChartView.frame = rect;
    self.barChartView.delegate = self;
    self.barChartView.dataSource = self;
    self.barChartView.minimumValue = 0.0f;
    self.barChartView.inverted = NO;
    self.barChartView.backgroundColor = kJBColorBarChartBackground;
    
    [view addSubview:self.barChartView];
    
    self.barChartView.layer.borderWidth = 0.5;
    self.barChartView.layer.borderColor = [[UIColor grayColor] CGColor];
}

#define degreeTOradians(x) (M_PI * (x)/180)
-(void) loadViewVertical:(CGRect) rect {
    self.barChartView = [[JBBarChartView alloc] init];
    self.barChartView.frame = CGRectMake(rect.origin.x-rect.size.height/2+rect.size.width/2,
                                         rect.origin.y + rect.size.height/2 - rect.size.width/2,
                                         rect.size.height, rect.size.width);
    self.barChartView.delegate = self;
    self.barChartView.dataSource = self;
    self.barChartView.minimumValue = 0.0f;
    self.barChartView.inverted = NO;
    self.barChartView.backgroundColor = kJBColorBarChartBackground;
    
    [view addSubview:self.barChartView];
    
    self.barChartView.transform =  CGAffineTransformMakeRotation(degreeTOradians(270));
    self.barChartView.layer.borderWidth = 0.5;
    self.barChartView.layer.borderColor = [[UIColor grayColor] CGColor];
}

-(void) removeFromSuperView {
    [self.barChartView removeFromSuperview];
}

- (void) reload {
    [self.barChartView reloadData];
    
    [self.barChartView setState:JBChartViewStateExpanded];
}

#pragma mark - JBChartViewDataSource

- (BOOL)shouldExtendSelectionViewIntoHeaderPaddingForChartView:(JBChartView *)chartView
{
    return NO;
}

- (BOOL)shouldExtendSelectionViewIntoFooterPaddingForChartView:(JBChartView *)chartView
{
    return NO;
}

- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    float delta = self.max - self.min;
    float mergeCount = delta / MAX_COUNT;
    if (mergeCount > 2) {
        return delta / mergeCount;
    }
    return self.max - self.min;
}

- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
{
    if (self.onItemCLicked) {
        self.onItemCLicked(index);
    }
}

- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
{
}

#pragma mark - JBBarChartViewDelegate

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
{
    float delta = self.max - self.min;
    float mergeCount = delta / MAX_COUNT;
    if (mergeCount > 2) {
        NSInteger volCount = 0;
        for (int i=0; i<mergeCount; i++) {
            float floatKey = self.min + index*mergeCount + i;
            NSInteger key = floatKey;
            NSString* keyStr = [NSString stringWithFormat:@"%ld", key];
            NSInteger vol = [[self.averageVolDic objectForKey:keyStr] integerValue];
//            NSLog(@"Calculate: key:%ld vol:%ld", key, vol);
            if (vol < 0) {
                continue;
            }
            volCount += vol;
        }
//        NSLog(@"vol: %ld", volCount);
//        NSLog(@"========");
        return volCount;
    } else {
        NSInteger key = self.min + index;
        NSString* keyStr = [NSString stringWithFormat:@"%ld", key];
        
        NSInteger vol = [[self.averageVolDic objectForKey:keyStr] integerValue];
        if (vol < 0) {
            NSLog(@"Fu de: %ld", vol);
            return 0;
        }
        return vol;
    }
    return 0;
}

- (UIColor *)barChartView:(JBBarChartView *)barChartView colorForBarViewAtIndex:(NSUInteger)index
{
    return kJBColorBarChartBarRed;
}

- (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView
{
    return [UIColor whiteColor];
}

- (CGFloat)barPaddingForBarChartView:(JBBarChartView *)barChartView
{
    return 0;
}
@end
