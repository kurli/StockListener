//
//  KLineChartViewController.h
//  StockListener
//
//  Created by Guozhen Li on 1/11/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StockInfo;
@interface KLineViewController : NSObject

-(id) initWithParentView:(UIView*)view;

-(void) setFrame:(CGRect)rect;

-(void) refresh:(float)lowest andHighest:(float)highest andDrawKLine:(BOOL)drawKLine;

-(void) setSplitX:(NSInteger)x;

-(void) setPriceMark:(float)priceMark;

-(void) setPriceMarkColor:(UIColor*)color;

-(void) setPriceInfoStr:(NSString*)str;

-(void) clearPlot;

-(void) hideInfoButton;

-(float) getPointerInterval;

-(void) startEditLine;

-(void) endEditLine;

-(BOOL) isEditLine;

-(float) getEditLineK;

-(float) getEditLineB;

-(void) setEditLineK:(float)k;

-(void) setEditLineB:(float)b;

-(void) resetEditButton;

-(void) enableGesture;

-(void) removeFromSuperView;

@property (nonatomic, assign) NSInteger todayStartIndex;
@property (nonatomic, assign) NSInteger startIndex;
@property (nonatomic, strong) NSMutableArray* priceKValues;
@property (weak, nonatomic) IBOutlet UILabel *fiveAPrice;
@property (weak, nonatomic) IBOutlet UILabel *tenAPrice;
@property (weak, nonatomic) IBOutlet UILabel *twentyAPrice;
@property (nonatomic, strong) UIViewController* viewController;
@property (nonatomic, strong) StockInfo* stockInfo;
@property (copy) void (^onScroll)(NSInteger delta, BOOL finished);
@property (copy) void (^onScale)(float delta, BOOL finished);

@property (nonatomic, strong) NSMutableArray* boll_ma;
@property (nonatomic, strong) NSMutableArray* bool_md;

@property (nonatomic, unsafe_unretained) NSInteger timeDelta;
@property (nonatomic, unsafe_unretained) NSInteger timeStartIndex;
@property (nonatomic, strong) UIColor* editLineColor;
@end
