//
//  ConfigHelper.m
//  StockListener
//
//  Created by Guozhen Li on 1/25/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "ConfigHelper.h"
#import "StockPlayerManager.h"
#import "StockRefresher.h"
#import "DatabaseHelper.h"
#import "StockPlayerManager.h"

#define STOCK_REFRESH_INTERVAL @"stock_refresh_interval"
#define SOUND_INTERVAL @"sound_interval"
#define IS_RONGDUAN @"is_rongduan"
#define SPEAK_INTERVAL @"speak_interval"
#define IS_AUTO_SWITCH_STOCK @"is_auto_switch_stock"
#define IS_PLAY_BACKGROUND @"is_play_background"

@implementation ConfigHelper

+(ConfigHelper*) getInstance {
    static ConfigHelper* shelper;
    if (shelper == nil) {
        shelper = [[ConfigHelper alloc] init];
    }
    return shelper;
}

-(id) init {
    if (self = [super init]) {
        [self reloadSettings];
    }
    return self;
}

-(void) reloadSettings {
    NSNumber* stockRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:STOCK_REFRESH_INTERVAL];
    if (stockRefresh == nil) {
        _stockRefreshInterval = DEFAULT_STOCK_INTERVAL;
    } else {
        _stockRefreshInterval = [stockRefresh integerValue];
    }
//    NSNumber* isRongduan = [[NSUserDefaults standardUserDefaults] objectForKey:IS_RONGDUAN];
//    if (isRongduan == nil) {
//        _isRongDuan = NO;
//    } else {
//        _isRongDuan = [isRongduan boolValue];
//    }
//    NSNumber* soundInterval = [[NSUserDefaults standardUserDefaults] objectForKey:SOUND_INTERVAL];
//    if (soundInterval == nil) {
//        _soundInterval = DEFAULT_SOUND_INTERVAL;
//    } else {
//        _soundInterval = [soundInterval integerValue];
//    }
    NSNumber* speakInterval = [[NSUserDefaults standardUserDefaults] objectForKey:SPEAK_INTERVAL];
    if (speakInterval == nil) {
        _speakInterval = DEFAULT_SPEAK_INTERVAL;
    } else {
        _speakInterval = [speakInterval integerValue];
    }
    NSNumber* isAutoSwitchStock = [[NSUserDefaults standardUserDefaults] objectForKey:IS_AUTO_SWITCH_STOCK];
    if (isAutoSwitchStock == nil) {
        _isAutoSwitchStock = YES;
    } else {
        _isAutoSwitchStock = [isAutoSwitchStock boolValue];
    }
    NSNumber* isPlayBackground = [[NSUserDefaults standardUserDefaults] objectForKey:IS_PLAY_BACKGROUND];
    if (isPlayBackground == nil) {
        _isPlayBackground = NO;
    } else {
        _isPlayBackground = YES;
    }
    [[StockPlayerManager getInstance] setIsAudoChoose:isAutoSwitchStock];
}

-(void) setStockRefreshInterval:(NSInteger)stockRefreshInterval {
    _stockRefreshInterval = stockRefreshInterval;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:stockRefreshInterval] forKey:STOCK_REFRESH_INTERVAL];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[DatabaseHelper getInstance] stopRefreshStock];
    [[DatabaseHelper getInstance] startRefreshStock];
}

//-(void) setIsRongDuan:(BOOL)isRongDuan {
//    _isRongDuan = isRongDuan;
//    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isRongDuan] forKey:IS_RONGDUAN];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    if (isRongDuan) {
//        [[DatabaseHelper getInstance] stopRefreshStock];
//    } else {
//        [[DatabaseHelper getInstance] startRefreshStock];
//    }
//}

//-(void) setSoundInterval:(NSInteger)soundInterval {
//    _soundInterval = soundInterval;
//    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:soundInterval] forKey:SOUND_INTERVAL];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}

-(void) setSpeakInterval:(NSInteger)speakInterval {
    _speakInterval = speakInterval;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:speakInterval] forKey:SPEAK_INTERVAL];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([[StockPlayerManager getInstance] isPlaying]) {
        [[StockPlayerManager getInstance] pause];
        [[StockPlayerManager getInstance] play];
    }
}

-(void) setIsAutoSwitchStock:(BOOL)isAutoSwitchStock {
    _isAutoSwitchStock = isAutoSwitchStock;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:isAutoSwitchStock] forKey:IS_AUTO_SWITCH_STOCK];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[StockPlayerManager getInstance] setIsAudoChoose:isAutoSwitchStock];
}

-(void) setIsPlayBackground:(BOOL)isPlayBackground {
    _isPlayBackground = isPlayBackground;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:isPlayBackground] forKey:IS_PLAY_BACKGROUND];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
