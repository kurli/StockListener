//
//  StockPlayerManager.m
//  StockListener
//
//  Created by Guozhen Li on 11/29/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockPlayerManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "FSAudioStream.h"
#import "FSAudioController.h"
#import "FSPlaylistItem.h"
#import "StockInfo.h"
#import "StockRefresher.h"
#import "DatabaseHelper.h"
#import "TheAmazingAudioEngine.h"
#import "ConfigHelper.h"

#define UP_SOUND @"up"
#define DOWN_SOUND @"down"
#define MUSIC_SOUND @"music_default_1"

#define STOCK_UP 1
#define STOCK_DOWN 2

//#define NSLog(a)

#if 1

@interface StockPlayerManager() {
    int _currentPlayIndex;
    BOOL _continueRefresh;
    NSInteger speachCounter;
}

@property (nonatomic, strong) AEAudioController *audioController;
@property (nonatomic, strong) AEAudioFilePlayer *musicPlayer;
@property (nonatomic, strong) AEAudioFilePlayer *stockPlayer;
@property (nonatomic,strong) AVSpeechSynthesizer *speechPlayer;
@property (nonatomic,strong) NSString *currentPlaySID;
@property (atomic,strong) NSMutableArray* playList;

@end

@implementation StockPlayerManager

+(StockPlayerManager*) getInstance {
    static StockPlayerManager* shelper;
    if (shelper == nil) {
        shelper = [[StockPlayerManager alloc] init];
    }
    return shelper;
}

- (id) init {
    if (self = [super init]) {
        _currentPlayIndex = 0;
        _continueRefresh = NO;
        self.playList =[[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onStockValueRefreshed)
                                                     name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                                   object:nil];

        speachCounter = 0;
    }
    return self;
}

-(void) initAudio {
    if (_audioController != nil) {
        return;
    }
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:AEAudioStreamBasicDescriptionNonInterleaved16BitStereo
                            inputEnabled:NO];
    _audioController.preferredBufferDuration = 0.005;
    _audioController.useMeasurementMode = NO;
    [_audioController setAllowMixingWithOtherApps:NO];
    
    self.musicPlayer = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:MUSIC_SOUND withExtension:@"mp3"] error:NULL];
    _musicPlayer.volume = 0.001;
    _musicPlayer.loop = YES;
    _musicPlayer.channelIsMuted = YES;
    [_audioController addChannels:@[_musicPlayer]];
    [self setAllowMixing:[ConfigHelper getInstance].isPlayBackground];
}

/*
 * =======================================
 * Observer
 * =======================================
 */

- (void)onStockValueRefreshed {
    if ([[DatabaseHelper getInstance].stockList count] == 0) {
        return;
    }
    if (_continueRefresh == NO) {
        return;
    }
    if ([self.playList count] > 0) {
        return;
    }

    if (!_audioController.running) {
        return;
    }

    StockInfo* info = [[DatabaseHelper getInstance] getInfoById:_currentPlaySID];
    BOOL switched = NO;
    if (self.isAudoChoose)
    {
        int tmpStep = 0;
        StockInfo* tmpInfo = nil;
        NSArray* array = [DatabaseHelper getInstance].stockList;
        int i = 0;
        for (i=0; i<[array count]; i++) {
            StockInfo* info2 = [array objectAtIndex:i];
            if (info2.step > tmpStep) {
                tmpInfo = info2;
                tmpStep = info2.step;
            }
        }
        if (tmpStep > 3 && info != tmpInfo) {
            info = tmpInfo;
            switched = YES;
            _currentPlaySID = info.sid;
            _currentPlayIndex = i;
//            if (self.delegate) {
//                [self.delegate onPlaying:info];
//            }
            NSNotification * notice = [NSNotification notificationWithName:STOCK_PLAYER_STETE_NOTIFICATION object:info userInfo:nil];
            [[NSNotificationCenter defaultCenter]postNotification:notice];
            [self speak:info.name];
        }
    }
    if (info == nil) {
        [self pause];
        return;
    }

    float value = info.changeRate * 100;
    [self setLockScreenTitle:[NSString stringWithFormat:@"%@  %@ (%.2f%%)", info.name, [self valueToStr:info.price], value] andTime:info.updateTime andRate:info.changeRate];

    if (!switched) {
        speachCounter++;
        if (speachCounter >= [ConfigHelper getInstance].speakInterval) {
            [self stockSpeachFired];
            return;
        }
    }

    if (info.speed > 0) {
        [self playStockValueUp:info.step];
    } else if (info.speed < 0) {
        [self playStockValueDown:info.step];
    }
}

- (AVSpeechSynthesizer *)speechPlayer
{
    if (!_speechPlayer) {
        _speechPlayer = [[AVSpeechSynthesizer alloc] init];
        _speechPlayer.delegate = self;
    }
    return _speechPlayer;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    speachCounter = 0;
//    [_audioController start:nil];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance {
    speachCounter = 0;
//    [_audioController start:nil];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    speachCounter = 0;
//    [_audioController start:nil];
}

/*
 * =======================================
 * Delegate
 * =======================================
 */
- (BOOL)audioController:(FSAudioController *)audioController allowPreloadingForStream:(FSAudioStream *)stream
{
    // We could do some fine-grained control here depending on the connectivity status, for example.
    // Allow all preloads for now.
    return YES;
}

- (void)audioController:(FSAudioController *)audioController preloadStartedForStream:(FSAudioStream *)stream
{
    // Should we display the preloading status somehow?
}

/*
 * =======================================
 * Private
 * =======================================
 */

- (NSString*) valueToStr:(float)value {
    NSString* str = [NSString stringWithFormat:@"%.3f", value];
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

-(void) playStockValueUp: (int)step {
    for (int i=0; i<step; i++) {
        [self.playList addObject:[NSNumber numberWithInt:STOCK_UP]];
    }
    [self playStockSound];
}

-(void) playStockValueDown: (int)step {
    for (int i=0; i<step; i++) {
        [self.playList addObject:[NSNumber numberWithInt:STOCK_DOWN]];
    }
    [self playStockSound];
}

- (void)speak: (NSString*)str {
    AVSpeechUtterance* u=[[AVSpeechUtterance alloc]initWithString:str];
    u.voice=[AVSpeechSynthesisVoice voiceWithLanguage:@"zh-TW"];
//    [_audioController stop];
    [self.speechPlayer speakUtterance:u];
}

- (void) setLockScreenTitle:(NSString*) str andTime:(NSString*)time andRate:(float)rate {
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    songInfo[MPMediaItemPropertyTitle] = str;
    songInfo[MPMediaItemPropertyArtist] = time;
    int value = rate * 1000 + 100;
    [songInfo setObject:[NSNumber numberWithFloat:200] forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:[NSNumber numberWithFloat:value] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [songInfo setObject:[NSNumber numberWithFloat:0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

- (void) playStockSound {
    if (!_continueRefresh) {
        return;
    }
    if ([self.playList count] > 0) {
        NSNumber* type = [self.playList objectAtIndex:0];
        NSString* url = nil;
        switch ([type intValue]) {
            case STOCK_DOWN:
                url = DOWN_SOUND;
                break;
            case STOCK_UP:
                url = UP_SOUND;
                break;
            default:
                break;
        }
        __weak StockPlayerManager* weakSelf = self;
        self.stockPlayer = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:url withExtension:@"m4a"] error:NULL];
        _stockPlayer.removeUponFinish = YES;
        _stockPlayer.completionBlock = ^() {
            if ([weakSelf.playList count] > 0) {
                [weakSelf.playList removeObjectAtIndex:0];
                [weakSelf playStockSound];
            }
        };
        [self.audioController addChannels:@[_stockPlayer]];
    }
}

- (void) playMusic {
    [_audioController start:NULL];
    _musicPlayer.channelIsMuted = NO;
}

- (void) pauseMusic {
    _musicPlayer.channelIsMuted = YES;
    [_audioController stop];
}

- (void)stockSpeachFired {
    StockInfo* info = [[DatabaseHelper getInstance] getInfoById:_currentPlaySID];
    if (info == nil) {
        speachCounter = 0;
        return;
    }

    float value = info.changeRate * 100;
    NSString* proceStr = [NSString stringWithFormat:@"%@, 百分之%.2f", [self valueToStr:info.price], value];
    [self speak:proceStr];
}

/*
 * =======================================
 * APIs
 * =======================================
 */
- (void) play {
//    if ([ConfigHelper getInstance].isRongDuan) {
//        _continueRefresh = false;
//        return;
//    }
    [self initAudio];

    if ([[DatabaseHelper getInstance].stockList count] == 0) {
        _continueRefresh = false;
        return;
    }
    _continueRefresh = true;

    if (_currentPlayIndex < 0 || _currentPlayIndex >= [[DatabaseHelper getInstance].stockList count]) {
        _currentPlayIndex = 0;
    }
    StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:_currentPlayIndex];
    [self setCurrentPlaySID:info.sid];
    
    speachCounter = [ConfigHelper getInstance].speakInterval - 2;
    [self onStockValueRefreshed];

    [self playMusic];
    
//    if (self.delegate) {
//        [self.delegate onPlaying:info];
//    }
    NSNotification * notice = [NSNotification notificationWithName:STOCK_PLAYER_STETE_NOTIFICATION object:info userInfo:nil];
    [[NSNotificationCenter defaultCenter]postNotification:notice];
}

-(void) pause {
    [self.playList removeAllObjects];
    _continueRefresh = false;
    [self.speechPlayer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
    [self pauseMusic];
//    
//    if (self.delegate) {
//        [self.delegate onPLayPaused];
//    }
    
    NSNotification * notice = [NSNotification notificationWithName:STOCK_PLAYER_STETE_NOTIFICATION object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter]postNotification:notice];
}

-(BOOL) isPlaying {
    return _continueRefresh;
}

-(void) next {
    _currentPlayIndex++;
    if (_currentPlayIndex >= [[DatabaseHelper getInstance].stockList count]) {
        _currentPlayIndex = 0;
    }
    [self pause];
    [self play];
}

-(void) pre {
    _currentPlayIndex--;
    if (_currentPlayIndex < 0) {
        _currentPlayIndex = (int)[[DatabaseHelper getInstance].stockList count] -1;
    }
    [self pause];
    [self play];
}

-(void) playByIndex:(int)index {
    if (index < 0) {
        index = 0;
    }
    if (index >= [[DatabaseHelper getInstance].stockList count]) {
        index = 0;
    }
    _currentPlayIndex = index;
    [self pause];
    [self play];
}

-(StockInfo*) getCurrentPlayingInfo {
    if ([_currentPlaySID length] == 0) {
        return nil;
    }
    StockInfo* info = [[DatabaseHelper getInstance] getInfoById:_currentPlaySID];
    return info;
}

-(void) setAllowMixing:(BOOL)enable {
    [self pause];
    [self initAudio];
    [_audioController setAllowMixingWithOtherApps:enable];
}


@end
#endif