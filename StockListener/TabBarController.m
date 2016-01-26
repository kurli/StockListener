//
//  TabBarController.m
//  StockListener
//
//  Created by Guozhen Li on 12/29/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "TabBarController.h"
#import "StockPlayerManager.h"
#import "StockListViewController.h"
#import "StockInfo.h"
#import "StockTableItemViewController.h"
#import "StockPlayerManager.h"
#import "ConfigHelper.h"

@interface TabBarController () <UITabBarControllerDelegate>

@end

@implementation TabBarController
@synthesize button;
@synthesize myTabBar;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setup
{
    //  添加突出按钮
    [self addCenterButtonWithImage:[UIImage imageNamed:@"Play"] selectedImage:[UIImage imageNamed:@"Pause"]];
    //  UITabBarControllerDelegate 指定为自己
    self.delegate=self;
    //  设点button状态
    button.selected=NO;
    //  设定其他item点击选中颜色
    myTabBar.tintColor= [UIColor colorWithRed:222/255.0 green:78/255.0 blue:22/255.0 alpha:1];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPlayerStatusChanged:)
                                                 name:STOCK_PLAYER_STETE_NOTIFICATION
                                               object:nil];
}

-(void) onPlayerStatusChanged:(NSNotification*)notification {
    StockInfo* info = [notification object];
    if (info != nil) {
        button.selected = YES;
    } else {
        button.selected = NO;
    }
}

// Create a custom UIButton and add it to the center of our tab bar
-(void) addCenterButtonWithImage:(UIImage*)buttonImage selectedImage:(UIImage*)selectedImage
{
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(pressChange:) forControlEvents:UIControlEventTouchUpInside];
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
    //  设定button大小为适应图片
    CGRect rect = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    
    //  这个比较恶心  去掉选中button时候的阴影
    button.adjustsImageWhenHighlighted=NO;
    
    
    /*
     *  核心代码：设置button的center 和 tabBar的 center 做对齐操作， 同时做出相对的上浮
     */
    CGFloat heightDifference = buttonImage.size.height - self.tabBar.frame.size.height;
//    if (heightDifference < 0) {
//        button.center = self.tabBar.center;
//    } else {
//        CGPoint center = self.tabBar.center;
//        center.y = center.y - heightDifference/2.0;
//        button.center = center;
//    }
    rect.origin.x = (self.tabBar.frame.size.width/5-rect.size.width)/2;
    rect.origin.y = self.tabBar.frame.origin.y - heightDifference;
//    if (heightDifference < 0) {
////        button.center = self.tabBar.center;
//        
//    } else {
//        CGPoint center = self.tabBar.center;
//        center.y = center.y - heightDifference/2.0;
//        button.center = center;
//    }
    button.frame = rect;
    
    [self.view addSubview:button];
}

-(void)pressChange:(id)sender
{
//    if ([ConfigHelper getInstance].isRongDuan) {
//        button.selected = NO;
//        return;
//    }
    
    button.selected = !button.selected;
    if (![[StockPlayerManager getInstance] isPlaying]) {
        [[StockPlayerManager getInstance] play];
    } else {
        [[StockPlayerManager getInstance] pause];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.selectedViewController viewWillAppear:animated];
}

#pragma mark- TabBar Delegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (viewController.view.tag == 444) {
        return NO;
    }
    return YES;
}
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [viewController viewWillAppear:NO];
}

@end
