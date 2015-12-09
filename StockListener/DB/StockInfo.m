//
//  StockInfo.m
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockInfo.h"

@implementation StockInfo

@synthesize sid;
@synthesize name;

#define SID @"sid"
#define NAME @"name"
#define CURRENT_PRICE @"current_price"
#define CHANGE_RATE @"change_rate"

- (id)copyWithZone:(NSZone *)zone {
    StockInfo* info = [[StockInfo allocWithZone:zone] init];
    info.sid = [self.sid copy];
    info.name = [self.name copy];
    info.currentPrice = self.currentPrice;
    info.lastChangeRate = self.lastChangeRate;
    info.changeRate = self.changeRate;
    info.lastStep = self.lastStep;
    return info;
}

-(void) assign:(StockInfo*) info {
    self.name = info.name;
    self.currentPrice = info.currentPrice;
    self.lastChangeRate = info.lastChangeRate;
    self.changeRate = info.changeRate;
    self.lastStep = info.lastStep;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.sid forKey:SID];
    [aCoder encodeObject:self.name forKey:NAME];
    [aCoder encodeObject:[NSNumber numberWithFloat:self.currentPrice] forKey:CURRENT_PRICE];
    [aCoder encodeObject:[NSNumber numberWithFloat:self.changeRate] forKey:CHANGE_RATE];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.sid = [aDecoder decodeObjectForKey:SID];
        self.name = [aDecoder decodeObjectForKey:NAME];
        self.currentPrice = [(NSNumber*)[aDecoder decodeObjectForKey:CURRENT_PRICE] floatValue];
        self.changeRate = [(NSNumber*)[aDecoder decodeObjectForKey:CHANGE_RATE] floatValue];
    }
    return self;
}

@end
