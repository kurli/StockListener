//
//  ViewController.m
//  StockListener
//
//  Created by Guozhen Li on 11/26/15.
//  Copyright (c) 2015 Guangzhen Li. All rights reserved.
//

#import "ViewController.h"
#import "KingdaWorker.h"
#import "FSAudioController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
- (IBAction)onDoneClicked:(id)sender {
    player = [[StockPlayerManager alloc] init];
    NSMutableArray* array = [[NSMutableArray alloc] init];
    StockInfo* info = [[StockInfo alloc] init];
    info.name = @"";
    info.sid = self.textField.text;
    [array addObject:info];
    [player setStockPlayList:array];
    [player play];
}
- (IBAction)onPayseClicked:(id)sender {
    [player pauseOnPauseClidked];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause: /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlPlay:  /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [player pauseOnPauseClidked];
                break;
            default:
                break;
        }
    }
}

@end
