//
//  AppDelegate.m
//  StockListener
//
//  Created by Guozhen Li on 11/26/15.
//  Copyright (c) 2015 Guangzhen Li. All rights reserved.
//

#import "AppDelegate.h"
#import "DatabaseHelper.h"
#import "TabBarController.h"
#import "StockKDJViewController.h"
#import "StockListViewController.h"
#import "StockPlayerManager.h"
#import "BuySellHistoryViewController.h"
#import "SettingsViewController.h"

@interface AppDelegate () {
}

@property (nonatomic, strong) TabBarController* tb;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.tb=[[TabBarController alloc]init];
    self.window.rootViewController=self.tb;

    //b.创建子控制器
    StockListViewController *c1=[[StockListViewController alloc] init];
    c1.tabBarItem.title=@"Stock";
    //    c3.tabBarItem.image=[UIImage imageNamed:@"Play"];

    StockKDJViewController *c2=[[StockKDJViewController alloc] init];
    c2.tabBarItem.title=@"KDJ";
    
    UIViewController *c3=[[UIViewController alloc]init];
    c3.view.backgroundColor=[UIColor yellowColor];
    c3.view.tag = 444;

    BuySellHistoryViewController *c4=[[BuySellHistoryViewController alloc] initWithNibName:@"BuySellHistoryViewController" bundle:nil];
    c4.tabBarItem.title=@"Caculator";

    SettingsViewController* c5=[[SettingsViewController alloc] init];
    c5.tabBarItem.title=@"Setting";
    
    self.tb.viewControllers =@[c3,c1,c2,c4,c5];
    self.tb.selectedViewController = c1;
    [self.window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputDeviceChanged:)name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    return YES;
}

- (void)outputDeviceChanged:(NSNotification *)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[StockPlayerManager getInstance] pause];
    });
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause: /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlPlay:  /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if ([[StockPlayerManager getInstance] isPlaying]) {
                    [[StockPlayerManager getInstance] pause];
                } else {
                    [[StockPlayerManager getInstance] play];
                }
                break;
            case UIEventSubtypeMotionShake:
            case UIEventSubtypeRemoteControlNextTrack:
                [[StockPlayerManager getInstance] next];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [[StockPlayerManager getInstance] pre];
                break;
            default:
                break;
        }
    }
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    if (![[StockPlayerManager getInstance] isPlaying]) {
        [[DatabaseHelper getInstance] stopRefreshStock];
        [[DatabaseHelper getInstance] clearStoredPriceData];
    }
    [[DatabaseHelper getInstance] saveToDB];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    [[DatabaseHelper getInstance] startRefreshStock];
    [self.tb.selectedViewController viewWillAppear:NO];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[DatabaseHelper getInstance] saveToDB];
}

@end
