//
//  KingdaWorker.m
//  SmartHome
//
//  Created by Guozhen Li on 2/4/15.
//  Copyright (c) 2015 LiGuozhen. All rights reserved.
//

#import "KingdaWorker.h"

@interface KingdaWorker()
@property (nonatomic, strong) NSThread *mThread;
@property (nonatomic, strong) NSMutableArray *mQueue;
@property (nonatomic, strong) KingdaTask *mActiveTask;

@end

static KingdaWorker *static_worker;

@implementation KingdaWorker {
    BOOL mActive;
}

+(KingdaWorker*) getInstance {
    if (nil == static_worker) {
        static_worker = [[KingdaWorker alloc] init];
    }
    return static_worker;
}

-(id) init {
    self = [super init];
    self.mQueue = [[NSMutableArray alloc] init];
    mActive = false;
    self.mActiveTask = nil;
    return self;
}

-(void) workerThread {
    BOOL a = true;
    self.mActiveTask = nil;
    while (a) {
        if (!mActive || [self.mQueue count] == 0) {
            a = false;
            mActive = false;
            self.mThread = nil;
            
            self.mActiveTask = nil;
        } else {
            self.mActiveTask = [self.mQueue objectAtIndex:0];
            [self.mQueue removeObjectAtIndex:0];
        }
        
        if (self.mActiveTask != nil) {
            @try {
                [self.mActiveTask run];
            } @catch (NSException* e) {
            }
        }
    }
}

-(void) queue:(KingdaTask*) task {
    if (self.mActiveTask == task) {
        return;
    }
    
    [self.mQueue addObject:task];
    if (!mActive) {
        mActive = true;
        if (self.mThread == nil || ![self.mThread isExecuting]) {
            [self setMThread:nil];
            self.mThread = [[NSThread alloc] initWithTarget:self selector:@selector(workerThread) object:nil];
            [self.mThread start];
        }
    }
}

-(void) stop {
    [self.mQueue removeAllObjects];
}

@end
