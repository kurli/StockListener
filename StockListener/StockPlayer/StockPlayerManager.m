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

#define UP_SOUND @"up.mp3"
#define DOWN_SOUND @"down.mp3"
#define MUSIC_SOUND @"test.mp3"

#define SPEACH_COUNTER 6

@interface StockPlayerManager() {
    int _currentPlayIndex;
    BOOL _continueRefresh;
    int speachCounter;
}

@property (nonatomic,strong) FSAudioController *audioController;
@property (nonatomic,strong) FSAudioController *musicController;
@property (nonatomic,strong) AVSpeechSynthesizer *speechPlayer;
@property (nonatomic,strong) NSMutableArray* playList;
@property (nonatomic,strong) StockInfo* currentPlayStock;
@property (nonatomic,assign) BOOL musicPaused;

@end

@implementation StockPlayerManager

- (id) init {
    if (self = [super init]) {
        _currentPlayIndex = 0;
        _continueRefresh = NO;
        _configuration = [[FSStreamConfiguration alloc] init];
        _configuration.usePrebufferSizeCalculationInSeconds = YES;
        self.playList =[[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onStockValueRefreshed)
                                                     name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                                   object:nil];
        speachCounter = 0;
    }
    return self;
}

/*
 * =======================================
 * Observer
 * =======================================
 */

- (void)onStockValueRefreshed {
    if ([self.dbHelper.stockList count] == 0) {
        return;
    }
    if (_continueRefresh == NO) {
        return;
    }
    NSLog(@"onStockValueRefreshed");
    speachCounter++;
    if (speachCounter == SPEACH_COUNTER) {
        NSLog(@"onStockValueRefreshed speak");
        [self stockSpeachFired];
        return;
    }
    [self onStockValueGot];
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
        [weakSelf.audioController setVolume:1];
        _audioController.onStateChange = ^(FSAudioStreamState state) {
            switch (state) {
                case kFsAudioStreamPlaybackCompleted:{
                    NSLog(@"Stock play completed");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf playStockSound];
                    });
                    break;
                }
                default:
                    break;
            }
        };
    }
    return _audioController;
}

- (FSAudioController *)musicController
{
    if (!_musicController) {
        _musicController = [[FSAudioController alloc] init];
        _musicController.delegate = self;
        self.musicController.configuration = _configuration;
        self.musicController.url = [self parseLocalFileUrl:[NSString stringWithFormat:@"file://%@", MUSIC_SOUND ]];
        [self.musicController setVolume:0.3];
        __weak StockPlayerManager *weakSelf = self;
        _musicController.onStateChange = ^(FSAudioStreamState state) {
            switch (state) {
                case kFsAudioStreamPlaybackCompleted:{
                    [weakSelf playMusic];
                    break;
                }
                default:
                    break;
            }
        };
    }
    return _musicController;
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
    [self playMusic];
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

-(void)onStockValueGot{
    StockInfo* latestInfo = nil;
    if (self.currentPlayStock == nil) {
        return;
    }
    for (StockInfo* info in self.dbHelper.stockList) {
        if ([info.sid isEqualToString:self.currentPlayStock.sid]) {
            latestInfo = info;
        }
    }
    if (latestInfo == nil) {
        return;
    }
    _currentPlayStock.name = latestInfo.name;
    _currentPlayStock.changeRate = latestInfo.changeRate;
    [self stockValueChanged:latestInfo.currentPrice andTime:latestInfo.updateTime andLatestInfo:latestInfo];
}

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

- (void) stockValueChanged:(float)newValue andTime:(NSString*)time andLatestInfo:(StockInfo*) latestInfo {
    float value = _currentPlayStock.changeRate * 100;
    [self setLockScreenTitle:[NSString stringWithFormat:@"%@  %@ (%.2f%%)", _currentPlayStock.name, [self valueToStr:newValue], value] andTime:time andRate:_currentPlayStock.changeRate];

    if (_currentPlayStock.currentPrice == 0) {
        _currentPlayStock = [latestInfo copy];
        [self playMusic];
        return;
    }
    float currentChangeRate = (newValue - _currentPlayStock.currentPrice) / _currentPlayStock.currentPrice;
    currentChangeRate*=100;
    int step = 1;
    if (_currentPlayStock.lastChangeRate == 0) {
        step = 1;
        latestInfo.lastStep = 1;
    } else {
        float rt0 = _currentPlayStock.lastChangeRate < 0 ? _currentPlayStock.lastChangeRate * -1 : _currentPlayStock.lastChangeRate;
        float rt1 = currentChangeRate < 0 ? currentChangeRate * -1 : currentChangeRate;
        float tmpDrt = rt1 / rt0;

        float t = tmpDrt * _currentPlayStock.lastStep;
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
//    NSLog(@"lastPrice: %f currentPrice:%f c_rate:%f last_rate:%f step:%d", _currentPlayStock.currentPrice, newValue, currentChangeRate, _currentPlayStock.lastChangeRate, step);
    if (currentChangeRate > 0) {
        [self playStockValueUp:step];
    } else if (currentChangeRate < 0) {
        [self playStockValueDown:step];
    } else {
        [self playMusic];
    }
    latestInfo.lastChangeRate = currentChangeRate;
    latestInfo.currentPrice = newValue;
    latestInfo.lastStep = step;
    _currentPlayStock = [latestInfo copy];
//    NSLog(@"step:%d", _currentPlayStock.lastStep);
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
    [self pauseMusic];
    AVSpeechUtterance* u=[[AVSpeechUtterance alloc]initWithString:str];
    u.voice=[AVSpeechSynthesisVoice voiceWithLanguage:@"zh-TW"];
    [self.speechPlayer speakUtterance:u];
}

- (void) setLockScreenTitle:(NSString*) str andTime:(NSString*)time andRate:(float)rate {
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    songInfo[MPMediaItemPropertyTitle] = str;
    songInfo[MPMediaItemPropertyArtist] = time;
    int value = rate * 1000 + 100;
//    NSLog(@"rate=%f value = %d", rate, value);
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
    if (!_continueRefresh) {
        return;
    }
    if ([self.playList count] > 0) {
        NSString* url = [self.playList objectAtIndex:0];
        self.audioController.url = [self parseLocalFileUrl:url];
        [self pauseMusic];
        [self.audioController play];
        [self.playList removeObjectAtIndex:0];
    } else {
        [self playMusic];
    }
}

- (void) playMusic {
    if ([self.playList count] > 0) {
        NSLog(@"play music skipped");
        return;
    }
    if (!_continueRefresh) {
        return;
    }
    if (self.musicPaused) {
        NSLog(@"Play music after paused");
        [self.musicController pause];
        self.musicPaused = NO;
        return;
    }
    if (![self.musicController isPlaying]) {
        NSLog(@"Play music with play");
        [self.musicController play];
    }
    self.musicPaused = NO;
}

- (void) pauseMusic {
    NSLog(@"pause music");
    if (!self.musicPaused) {
        [self.musicController pause];
        self.musicPaused = YES;
    }
}

- (void)stockSpeachFired {
    if (_currentPlayIndex < 0 || _currentPlayIndex >= [self.dbHelper.stockList count]) {
        _currentPlayIndex = 0;
    }
    StockInfo* info = [self.dbHelper.stockList objectAtIndex:_currentPlayIndex];
    
    float value = info.changeRate * 100;
    NSString* proceStr = [NSString stringWithFormat:@"%@, 百分之%.2f", [self valueToStr:info.currentPrice], value];
    [self speak:proceStr];
    [self setLockScreenTitle:[NSString stringWithFormat:@"%@  %@ (%.2f%%)", _currentPlayStock.name, [self valueToStr:info.currentPrice], value] andTime:info.updateTime andRate:_currentPlayStock.changeRate];
}

/*
 * =======================================
 * APIs
 * =======================================
 */
- (void) play {
    if ([self.dbHelper.stockList count] == 0) {
        _continueRefresh = false;
        return;
    }
    _continueRefresh = true;

    if (_currentPlayIndex < 0 || _currentPlayIndex >= [self.dbHelper.stockList count]) {
        _currentPlayIndex = 0;
    }
    self.currentPlayStock = [[self.dbHelper.stockList objectAtIndex:_currentPlayIndex] copy];
    
    [self playMusic];
    [self onStockValueGot];
    
    if (self.delegate) {
        [self.delegate onPlaying:self.currentPlayStock];
    }
}

-(void) pause {
    [self.playList removeAllObjects];
    _continueRefresh = false;
    [self pauseMusic];
    
    if (self.delegate) {
        [self.delegate onPLayPaused];
    }
}

-(BOOL) isPlaying {
    return _continueRefresh;
}

-(void) next {
    _currentPlayIndex++;
    if (_currentPlayIndex >= [self.dbHelper.stockList count]) {
        _currentPlayIndex = 0;
    }
    [self pause];
    [self play];
}

-(void) pre {
    _currentPlayIndex--;
    if (_currentPlayIndex < 0) {
        _currentPlayIndex = (int)[self.dbHelper.stockList count] -1;
    }
    [self pause];
    [self play];
}

@end
