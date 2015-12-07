//
//  ServerConnectionBase.m
//  SmartHome
//
//  Created by Guozhen Li on 2/4/15.
//  Copyright (c) 2015 LiGuozhen. All rights reserved.
//

#import "ServerConnectionBase.h"
#import "AppDelegate.h"
#import "zlib.h"
#import "StockPlayerManager.h"

#define CONNECTION_TIMEOUT 500

@implementation ServerConnectionBase


-(id) init {
    if ((self = [super init]) != nil) {
    }
    return self;
}

-(void) onComplete:(NSString*) data {
    
}

-(void) post:(StockInfo*)info {
    NSString *urlString = [NSString stringWithFormat:@"http://hq.sinajs.cn/list=%@", info.sid];
    NSString *agentString = @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]]; [request setValue:agentString forHTTPHeaderField:@"User-Agent"];
    NSData *data = [ NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil ];
    NSString *returnData = [[NSString alloc] initWithBytes: [data bytes] length:[data length] encoding: NSUTF8StringEncoding]; NSLog(@"%@", returnData);

    NSHTTPURLResponse* urlResponse = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString* str = [[NSString alloc]initWithData:responseData encoding:enc];
    
    [self onComplete:str];
}

@end
