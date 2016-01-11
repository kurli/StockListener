//
//  FenshiViewController.h
//  StockListener
//
//  Created by Guozhen Li on 1/11/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StockInfo;

@interface FenshiViewController : NSObject

-(id) initWithParentView:(UIView*)view;

-(void) setFrame:(CGRect)rect;

-(void) refresh:(StockInfo*)info;

-(void) setSplitX:(NSInteger)x;

@end
