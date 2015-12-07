//
//  ServerConnectionBase.h
//  SmartHome
//
//  Created by Guozhen Li on 2/4/15.
//  Copyright (c) 2015 LiGuozhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KingdaTask.h"

@class StockInfo;
@interface ServerConnectionBase : KingdaTask

-(void) post: (StockInfo*)sid;

-(void) onComplete:(NSString*) data;

@end
