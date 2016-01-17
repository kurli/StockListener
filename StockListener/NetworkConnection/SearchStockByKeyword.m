//
//  SearchStockByKeyword.m
//  StockListener
//
//  Created by Guozhen Li on 1/13/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "SearchStockByKeyword.h"

@implementation SearchStockByKeyword

-(id) initWithKeyword:(NSString*) keywork {
    if ((self = [super init]) != nil) {
        keywork = [keywork lowercaseString];
        self.mURL =  [NSString stringWithFormat:@"http://suggest3.sinajs.cn/suggest/type=&key=%@", keywork];
        self.mURL = [self.mURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    }
    return self;
}

-(void) run {
    [self post];
}

-(NSString*) parseItem:(NSString*)data {
    NSArray* array = [data componentsSeparatedByString:@","];
    if ([array count] < 5) {
        return nil;
    }
    NSString* sid = [array objectAtIndex:3];
    NSString* name = [array objectAtIndex:4];
    
    if ([sid length] != 8) {
        return nil;
    }
    NSString* subStr = [sid substringToIndex:2];
    if (![subStr isEqualToString:@"sh"] && ![subStr isEqualToString:@"sz"]
        &&![subStr isEqualToString:@"cf"]) {
        return nil;
    }
    sid = [sid stringByReplacingOccurrencesOfString:@"cf" withString:@"sz"];

    return [NSString stringWithFormat:@"%@:%@", sid, name];
}

-(NSArray*) parseData:(NSString*)data {
    NSMutableArray* retArray = [[NSMutableArray alloc] init];
    NSArray* tmpArray = [data componentsSeparatedByString:@"\""];
    if ([tmpArray count] != 3) {
        return nil;
    }
    data = [tmpArray objectAtIndex:1];
    tmpArray = [data componentsSeparatedByString:@";"];
    if ([tmpArray count] == 0) {
        NSString* result = [self parseItem:data];
        if (result != nil) {
            [retArray addObject:result];
        }
    }
    for (NSInteger i=0; i<[tmpArray count]; i++) {
        NSString* str = [tmpArray objectAtIndex:i];
        NSString* result = [self parseItem:str];
        if (result != nil) {
            [retArray addObject:result];
        }
    }
    return retArray;
}

-(void) onComplete:(NSString *)data {
    NSArray* array = [self parseData:data];
    if (self.onStockListGotBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.onStockListGotBlock(array);
        });
    }
}
@end
