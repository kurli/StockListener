//
//  StockKDJViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/22/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockKDJViewController.h"

@interface StockKDJViewController ()

@end

@implementation StockKDJViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) calculateKDJ:(NSArray *)data {
    //KDJ
    NSMutableArray *kdj_k = [[NSMutableArray alloc] init];
    NSMutableArray *kdj_d = [[NSMutableArray alloc] init];
    NSMutableArray *kdj_j = [[NSMutableArray alloc] init];
    float prev_k = 50;
    float prev_d = 50;
    float rsv = 0;
    for(int i = 60;i < data.count;i++){
        float h  = [[[data objectAtIndex:i] objectAtIndex:2] floatValue];
        float l = [[[data objectAtIndex:i] objectAtIndex:3] floatValue];
        float c = [[[data objectAtIndex:i] objectAtIndex:1] floatValue];
        for(int j=i;j>i-10;j--){
            if([[[data objectAtIndex:j] objectAtIndex:2] floatValue] > h){
                h = [[[data objectAtIndex:j] objectAtIndex:2] floatValue];
            }
            
            if([[[data objectAtIndex:j] objectAtIndex:3] floatValue] < l){
                l = [[[data objectAtIndex:j] objectAtIndex:3] floatValue];
            }
        }
        
        if(h!=l)
            rsv = (c-l)/(h-l)*100;
        float k = 2*prev_k/3+1*rsv/3;
        float d = 2*prev_d/3+1*k/3;
        float j = d+2*(d-k);
        
        prev_k = k;
        prev_d = d;
        
        NSMutableArray *itemK = [[NSMutableArray alloc] init];
        [itemK addObject:[@"" stringByAppendingFormat:@"%f",k]];
        [kdj_k addObject:itemK];
        NSMutableArray *itemD = [[NSMutableArray alloc] init];
        [itemD addObject:[@"" stringByAppendingFormat:@"%f",d]];
        [kdj_d addObject:itemD];
        NSMutableArray *itemJ = [[NSMutableArray alloc] init];
        [itemJ addObject:[@"" stringByAppendingFormat:@"%f",j]];
        [kdj_j addObject:itemJ];
    }
//    [dic setObject:kdj_k forKey:@"kdj_k"];
//    [dic setObject:kdj_d forKey:@"kdj_d"];
//    [dic setObject:kdj_j forKey:@"kdj_j"];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
