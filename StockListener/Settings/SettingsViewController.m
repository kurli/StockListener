//
//  SettingsViewController.m
//  StockListener
//
//  Created by Guozhen Li on 1/25/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "SettingsViewController.h"
#import "ConfigHelper.h"

#define SWITCHER 101
#define NAME 102

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *stockRefreshIntervalTextField;
//@property (weak, nonatomic) IBOutlet UISwitch *rongDuanSwitcher;
@property (weak, nonatomic) IBOutlet UITextField *speakIntervalTextField;
@property (weak, nonatomic) IBOutlet UISwitch *autoSwitchStockSwitcher;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundSoundSwitcher;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    float appWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
    UIToolbar *accessoryView = [[UIToolbar alloc]
                                initWithFrame:CGRectMake(0, 0, appWidth, 0.1 * appWidth)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                              target:nil
                              action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(selectDoneButton)];
    accessoryView.items = @[space, done];
    self.stockRefreshIntervalTextField.inputAccessoryView = accessoryView;
}

- (void)selectDoneButton {
    [self.stockRefreshIntervalTextField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger stockInterval = [ConfigHelper getInstance].stockRefreshInterval;
//    NSInteger soundInterval = [ConfigHelper getInstance].soundInterval;
    NSInteger speakInterval = [ConfigHelper getInstance].speakInterval;
    self.stockRefreshIntervalTextField.text = [NSString stringWithFormat:@"%ld", stockInterval];
//    [self.rongDuanSwitcher setOn:[ConfigHelper getInstance].isRongDuan animated:YES];
    self.speakIntervalTextField.text = [NSString stringWithFormat:@"%ld", stockInterval * speakInterval];
    [self.autoSwitchStockSwitcher setOn:[ConfigHelper getInstance].isAutoSwitchStock animated:YES];
    [self.backgroundSoundSwitcher setOn:[ConfigHelper getInstance].isPlayBackground animated:YES];
    
//    [self rongduanChanged];
}

//- (void) rongduanChanged {
//    if ([ConfigHelper getInstance].isRongDuan) {
//        [self.stockRefreshIntervalTextField setEnabled:NO];
//        [self.backgroundSoundSwitcher setEnabled:NO];
//        [self.autoSwitchStockSwitcher setEnabled:NO];
//    } else {
//        [self.stockRefreshIntervalTextField setEnabled:YES];
//        [self.backgroundSoundSwitcher setEnabled:YES];
//        [self.autoSwitchStockSwitcher setEnabled:YES];
//    }
//}

- (void) changeSoundSpeakIntervals {
    self.speakIntervalTextField.text = [NSString stringWithFormat:@"%ld", [ConfigHelper getInstance].speakInterval * [ConfigHelper getInstance].stockRefreshInterval];
}

- (IBAction)stockRefreshSub:(id)sender {
//    if ([ConfigHelper getInstance].isRongDuan == YES) {
//        return;
//    }
    NSInteger stockRefreshInterval = [self.stockRefreshIntervalTextField.text integerValue];
    stockRefreshInterval--;
    if (stockRefreshInterval < DEFAULT_STOCK_INTERVAL) {
        stockRefreshInterval = 0;
    }
    self.stockRefreshIntervalTextField.text = [NSString stringWithFormat:@"%ld", stockRefreshInterval];
    [ConfigHelper getInstance].stockRefreshInterval = stockRefreshInterval;
    
    [self changeSoundSpeakIntervals];
}
- (IBAction)stockRefreshAdd:(id)sender {
//    if ([ConfigHelper getInstance].isRongDuan == YES) {
//        return;
//    }
    NSInteger stockRefreshInterval = [self.stockRefreshIntervalTextField.text integerValue];
    stockRefreshInterval++;
    if (stockRefreshInterval < DEFAULT_STOCK_INTERVAL) {
        stockRefreshInterval = DEFAULT_STOCK_INTERVAL;
    }
    self.stockRefreshIntervalTextField.text = [NSString stringWithFormat:@"%ld", stockRefreshInterval];
    [ConfigHelper getInstance].stockRefreshInterval = stockRefreshInterval;
    
    [self changeSoundSpeakIntervals];
}
- (IBAction)stockRefreshEndEditing:(id)sender {
    NSInteger stockRefreshInterval = [self.stockRefreshIntervalTextField.text integerValue];
    if (stockRefreshInterval < DEFAULT_STOCK_INTERVAL) {
        stockRefreshInterval = DEFAULT_STOCK_INTERVAL;
    }
    self.stockRefreshIntervalTextField.text = [NSString stringWithFormat:@"%ld", stockRefreshInterval];
    [ConfigHelper getInstance].stockRefreshInterval = stockRefreshInterval;
    
    [self changeSoundSpeakIntervals];
}

//- (IBAction)rongduanChanged:(id)sender {
//    UISwitch* switcher = (UISwitch*)sender;
//    [ConfigHelper getInstance].isRongDuan = switcher.isOn;
//    [self rongduanChanged];
//}

//- (IBAction)soundIntervalSub:(id)sender {
//    if ([ConfigHelper getInstance].isRongDuan == YES) {
//        return;
//    }
//    NSInteger soundInterval = [ConfigHelper getInstance].soundInterval;
//    soundInterval--;
//    if (soundInterval < 0) {
//        soundInterval = 0;
//    }
//    [ConfigHelper getInstance].soundInterval = soundInterval;
//    
//    [self changeSoundSpeakIntervals];
//}
//- (IBAction)soundIntervalAdd:(id)sender {
//    if ([ConfigHelper getInstance].isRongDuan == YES) {
//        return;
//    }
//    NSInteger soundInterval = [ConfigHelper getInstance].soundInterval;
//    soundInterval++;
//    [ConfigHelper getInstance].soundInterval = soundInterval;
//    
//    [self changeSoundSpeakIntervals];
//}

- (IBAction)speakIntervalSub:(id)sender {
//    if ([ConfigHelper getInstance].isRongDuan == YES) {
//        return;
//    }
    NSInteger speakInterval = [ConfigHelper getInstance].speakInterval;
    speakInterval--;
    if (speakInterval < 3) {
        speakInterval = 3;
    }
    [ConfigHelper getInstance].speakInterval = speakInterval;
    
    [self changeSoundSpeakIntervals];
}
- (IBAction)speakIntervalAdd:(id)sender {
//    if ([ConfigHelper getInstance].isRongDuan == YES) {
//        return;
//    }
    NSInteger speakInterval = [ConfigHelper getInstance].speakInterval;
    speakInterval++;
    [ConfigHelper getInstance].speakInterval = speakInterval;
    
    [self changeSoundSpeakIntervals];
}

- (IBAction)autoSwitchStockChanged:(id)sender {
//    if ([ConfigHelper getInstance].isRongDuan == YES) {
//        return;
//    }
    UISwitch* switcher = (UISwitch*)sender;
    [[ConfigHelper getInstance] setIsAutoSwitchStock:switcher.isOn];
}

- (IBAction)backgroundSoundChanged:(id)sender {
//    if ([ConfigHelper getInstance].isRongDuan == YES) {
//        return;
//    }
    UISwitch* switcher = (UISwitch*)sender;
    [ConfigHelper getInstance].isPlayBackground = switcher.isOn;
}

- (IBAction)websiteClicked:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://opengrok.club/category/23/stocklistener"]];
}

@end
