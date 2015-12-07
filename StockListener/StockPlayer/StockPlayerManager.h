//
//  StockPlayerManager.h
//  StockListener
//
//  Created by Guozhen Li on 11/29/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSAudioController.h"
#import <AVFoundation/AVFoundation.h>
#import "GetStockValueTask.h"

@interface StockInfo : NSObject <NSCopying>

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* sid;
@property (atomic, unsafe_unretained) float currentPrice;
@property (atomic, strong) NSString* updateTime;
@property (atomic, unsafe_unretained) float lastChangeRate;
@property (atomic, unsafe_unretained) int lastStep;
@property (atomic, unsafe_unretained) float changeRate;

@end

@interface StockPlayerManager : NSObject <FSAudioControllerDelegate, GetStockValueDoneDelegate, AVSpeechSynthesizerDelegate> {

    FSStreamConfiguration *_configuration;
}

@property (nonatomic, strong) NSArray* stockPlayList;

-(void) play;

-(void) pauseOnPauseClidked;
@end
