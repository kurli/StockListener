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
#import "KingdaWorker.h"
#import "StockInfo.h"

#define UP_SOUND @"up.mp3"
#define DOWN_SOUND @"down.mp3"
#define MUSIC_SOUND @"test.mp3"

#define REFRESH_RATE 10
#define SPEACH_COUNTER 3

@interface StockPlayerManager() {
    int _currentPlayIndex;
    BOOL _continueRefresh;
    int speachCounter;
}

@property (nonatomic,strong) NSTimer *stockRefreshTimer;

@property (nonatomic,strong) FSAudioController *audioController;
@property (nonatomic,strong) FSAudioController *audioController2;
@property (nonatomic,strong) AVSpeechSynthesizer *speechPlayer;
@property (nonatomic,strong) NSMutableArray* playList;

@end

@implementation StockPlayerManager

@synthesize audioController2;

- (id) init {
    if (self = [super init]) {
        _currentPlayIndex = 0;
        _continueRefresh = NO;
        _configuration = [[FSStreamConfiguration alloc] init];
        _configuration.usePrebufferSizeCalculationInSeconds = YES;
        self.playList =[[NSMutableArray alloc] init];
        
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackgroundNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForegroundNotification:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        speachCounter = 0;
    }
    return self;
}

/*
 * =======================================
 * Timers
 * =======================================
 */

- (void)stockRefreshFired {
    speachCounter++;
    if (speachCounter == SPEACH_COUNTER) {
        [self stockSpeachFired];
        speachCounter = 0;
        return;
    }
    [self playCurrentStock];
}

- (void)stockSpeachFired {
    if ([self.stockPlayList count] == 0) {
        return;
    }
    if (_currentPlayIndex < 0 || _currentPlayIndex >= [self.stockPlayList count]) {
        _currentPlayIndex = 0;
    }
    StockInfo* info = [self.stockPlayList objectAtIndex:_currentPlayIndex];

//    GetStockValueTask* task = [[GetStockValueTask alloc] initWithStock:info];
//    task.onCompleteBlock = ^(StockInfo* info) {
        float value = info.changeRate * 100;
        NSString* proceStr = [NSString stringWithFormat:@"%.3f, 百分之%.2f", info.currentPrice, value];
        [self speak:proceStr];
//    };
//    [[KingdaWorker getInstance] queue: task];
}

/*
 * =======================================
 * Controllers getter
 * =======================================
 */
- (FSAudioController *)audioController
{
    if (!_audioController) {
        _audioController = [[FSAudioController alloc] init];
        _audioController.delegate = self;
        self.audioController.configuration = _configuration;
        __weak StockPlayerManager *weakSelf = self;
        _audioController.onStateChange = ^(FSAudioStreamState state) {
            switch (state) {
                case kFsAudioStreamPlaybackCompleted:{
                    NSLog(@"Completed");
                    if ([weakSelf.playList count] > 0) {
                        NSString* url = [weakSelf.playList objectAtIndex:0];
                        weakSelf.audioController.url = [weakSelf parseLocalFileUrl:url];
                        [weakSelf.audioController setVolume:1];
                        [weakSelf.audioController play];
                        [weakSelf.playList removeObjectAtIndex:0];
                        break;
                    }
                    [weakSelf playMusic:[NSString stringWithFormat:@"file://%@", MUSIC_SOUND ]];
                    break;
                }
                default:
                    break;
            }
        };
    }
    return _audioController;
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
    [self playMusic:[NSString stringWithFormat:@"file://%@", MUSIC_SOUND ]];
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

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    NSLog(@"Application entering background");
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    NSLog(@"Application entering foreground");
}

-(void)onStockValueGot:(StockInfo*)info andError:(NSString*)errorInfo {
    NSLog(@"StockValueGot");
    if ([self.stockPlayList count] == 0) {
        NSLog(@"stockPlayList = 0");
        return;
    }
    if (_currentPlayIndex < 0 || _currentPlayIndex >= [self.stockPlayList count]) {
        NSLog(@"invalid currentPlayIndex");
        return;
    }
    StockInfo* currentInfo = [self.stockPlayList objectAtIndex:_currentPlayIndex];
    if ([currentInfo.sid isEqualToString:info.sid]) {
        if (_continueRefresh) {
            currentInfo.name = info.name;
            currentInfo.changeRate = info.changeRate;
            [self stockValueChanged:info.currentPrice andTime:info.updateTime];
        }
    } else {
        for (StockInfo* tmp in self.stockPlayList) {
            if ([tmp.sid isEqualToString:info.sid]) {
                tmp.currentPrice = info.currentPrice;
                tmp.name = info.name;
                tmp.changeRate = info.changeRate;
            }
        }
    }
}
/*
 * =======================================
 * Private
 * =======================================
 */

- (void) stockValueChanged:(float)newValue andTime:(NSString*)time {
    if ([self.stockPlayList count] == 0) {
        return;
    }
    if (_currentPlayIndex < 0 || _currentPlayIndex >= [self.stockPlayList count]) {
        return;
    }
    StockInfo* currentInfo = [self.stockPlayList objectAtIndex:_currentPlayIndex];
    float value = currentInfo.changeRate * 100;
    [self setLockScreenTitle:[NSString stringWithFormat:@"%@  %.3f (%.2f%%)", currentInfo.name, newValue, value] andTime:time andRate:currentInfo.changeRate];

    if (currentInfo.currentPrice == 0) {
        currentInfo.currentPrice = newValue;
        [self playMusic:[NSString stringWithFormat:@"file://%@", MUSIC_SOUND ]];
        return;
    }
    float currentChangeRate = (newValue - currentInfo.currentPrice) / currentInfo.currentPrice;
    currentChangeRate*=100;
    int step = 1;
    if (currentInfo.lastChangeRate == 0) {
        step = 1;
        currentInfo.lastStep = 1;
    } else {
        float rt0 = currentInfo.lastChangeRate < 0 ? currentInfo.lastChangeRate * -1 : currentInfo.lastChangeRate;
        float rt1 = currentChangeRate < 0 ? currentChangeRate * -1 : currentChangeRate;
        float tmpDrt = rt1 / rt0;

        float t = tmpDrt * currentInfo.lastStep;
        if (((int)(t*10) % 10) >= 5) {
            t += 1;
        }
        step = t;
    }
    if (step <= 0) {
        step = 1;
    }
    if (step > 5) {
        step = 5;
    }
    NSLog(@"lastPrice: %f currentPrice:%f c_rate:%f last_rate:%f", currentInfo.currentPrice, newValue, currentChangeRate, currentInfo.lastChangeRate);
    if (currentChangeRate > 0) {
        [self playStockValueUp:step];
    } else if (currentChangeRate < 0) {
        [self playStockValueDown:step];
    }
    currentInfo.lastChangeRate = currentChangeRate;
    currentInfo.currentPrice = newValue;
    currentInfo.lastStep = step;
}

-(void) playStockValueUp: (int)step {
    for (int i=0; i<step; i++) {
        [self.playList addObject:[NSString stringWithFormat:@"file://%@", UP_SOUND ]];
    }
    [self playStockSound];
}

-(void) playStockValueDown: (int)step {
    for (int i=0; i<step; i++) {
        [self.playList addObject:[NSString stringWithFormat:@"file://%@", DOWN_SOUND ]];
    }
    [self playStockSound];
}

- (void)speak: (NSString*)str {
    [self.audioController stop];
    self.audioController2 = self.audioController;
    self.audioController = nil;
    AVSpeechUtterance* u=[[AVSpeechUtterance alloc]initWithString:str];
    u.voice=[AVSpeechSynthesisVoice voiceWithLanguage:@"zh-TW"];
    [self.speechPlayer speakUtterance:u];
}

- (void) setLockScreenTitle:(NSString*) str andTime:(NSString*)time andRate:(float)rate {
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    songInfo[MPMediaItemPropertyTitle] = str;
    songInfo[MPMediaItemPropertyArtist] = time;
    int value = rate * 1000 + 100;
    NSLog(@"rate=%f value = %d", rate, value);
    [songInfo setObject:[NSNumber numberWithFloat:200] forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:[NSNumber numberWithFloat:value] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [songInfo setObject:[NSNumber numberWithFloat:0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

- (NSURL *)parseLocalFileUrl:(NSString *)fileUrl
{
    // Resolve the local bundle URL
    NSString *path = [fileUrl substringFromIndex:7];
    
    NSRange range = [path rangeOfString:@"." options:NSBackwardsSearch];
    
    NSString *fileName = [path substringWithRange:NSMakeRange(0, range.location)];
    NSString *suffix = [path substringWithRange:NSMakeRange(range.location + 1, [path length] - [fileName length] - 1)];
    
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:fileName ofType:suffix]];
}

- (void) playStockSound {
    if ([self.audioController isPlaying]) {
        NSString* url = [self.audioController.url absoluteString];
        if ([url containsString:MUSIC_SOUND]) {
            [self.audioController stop];
            self.audioController2 = self.audioController;
            self.audioController = nil;
        }
    }
    if ([self.playList count] > 0) {
        NSString* url = [self.playList objectAtIndex:0];
        self.audioController.url = [self parseLocalFileUrl:url];
        [self.audioController setVolume:1];
        [self.audioController play];
        [self.playList removeObjectAtIndex:0];
    }
}

- (void) playMusic:(NSString*)url {
    self.audioController.url = [self parseLocalFileUrl:url];
    [self.audioController setVolume:0.3];
    [self.audioController play];
}

-(void) playStock:(StockInfo*)info {
    GetStockValueTask* task = [[GetStockValueTask alloc] initWithStock:info];
    task.delegate = self;
    [[KingdaWorker getInstance] queue: task];
    if (_continueRefresh) {
        if (_stockRefreshTimer == nil) {
            _stockRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_RATE target:self selector:@selector(stockRefreshFired) userInfo:nil repeats:YES];
        }
    } else {
        [self stopRefresh];
    }
}

-(void) stopRefresh {
    _continueRefresh = NO;
    [_stockRefreshTimer invalidate];
    _stockRefreshTimer = nil;
}

- (void) playCurrentStock {
    if ([self.stockPlayList count] == 0) {
        return;
    }
    if (_currentPlayIndex < 0 || _currentPlayIndex >= [self.stockPlayList count]) {
        _currentPlayIndex = 0;
    }
    StockInfo* info = [self.stockPlayList objectAtIndex:_currentPlayIndex];
//    info.currentPrice = 0;
    [self playStock:info];
}

/*
 * =======================================
 * APIs
 * =======================================
 */
- (void) play {
    _continueRefresh = true;
    if ([self.stockPlayList count] == 0) {
        return;
    }
    if (_currentPlayIndex < 0 || _currentPlayIndex >= [self.stockPlayList count]) {
        _currentPlayIndex = 0;
    }
    StockInfo* info = [self.stockPlayList objectAtIndex:_currentPlayIndex];
    info.currentPrice = 0;
    [self playCurrentStock];
    
    if (self.delegate) {
        [self.delegate onPlaying:[self.stockPlayList objectAtIndex:_currentPlayIndex]];
    }
}

-(void) pause {
    _continueRefresh = false;
    [self.audioController stop];
    self.audioController2 = self.audioController;
    self.audioController = nil;
    [self stopRefresh];
    
    if (self.delegate) {
        [self.delegate onPLayPaused];
    }
}

-(BOOL) isPlaying {
    return _continueRefresh;
}

-(void) next {
    _currentPlayIndex++;
    if (_currentPlayIndex >= [self.stockPlayList count]) {
        _currentPlayIndex = 0;
    }
    [self pause];
    [self play];
}

-(void) pre {
    _currentPlayIndex--;
    if (_currentPlayIndex < 0) {
        _currentPlayIndex = (int)[self.stockPlayList count] -1;
    }
    [self pause];
    [self play];
}

-(int) getCurrentPlayIndex {
    return _currentPlayIndex;
}

@end
