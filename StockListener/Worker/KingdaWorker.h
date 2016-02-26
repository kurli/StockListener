//
//  KingdaWorker.h
//  SmartHome
//
//  Created by Guozhen Li on 2/4/15.
//  Copyright (c) 2015 LiGuozhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KingdaTask.h"

@interface KingdaWorker : NSObject

-(void) queue:(KingdaTask*) task;
+(KingdaWorker*) getInstance;
-(void) removeSameKindTask:(KingdaTask*)task;

@end
