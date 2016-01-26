//
//  ConfigHelper.h
//  StockListener
//
//  Created by Guozhen Li on 1/25/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_STOCK_INTERVAL 6
//#define DEFAULT_SOUND_INTERVAL 1
#define DEFAULT_SPEAK_INTERVAL 60

@interface ConfigHelper : NSObject

@property (nonatomic, assign) NSInteger stockRefreshInterval;

//@property (nonatomic, assign) BOOL isRongDuan;

//@property (nonatomic, assign) NSInteger soundInterval;

@property (nonatomic, assign) NSInteger speakInterval;

@property (nonatomic, assign) BOOL isAutoSwitchStock;

@property (nonatomic, assign) BOOL isPlayBackground;

+(ConfigHelper*) getInstance;

@end
