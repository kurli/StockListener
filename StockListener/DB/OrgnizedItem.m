//
//  OrgnizedItem.m
//  StockListener
//
//  Created by Guozhen Li on 6/15/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "OrgnizedItem.h"

#define SID @"sid"
#define TYPE @"type"
#define DELTA @"delta"

@implementation OrgnizedItem

- (id) init {
    if (self = [super init]) {
        self.sid = nil;
        self.type = ORGNIZED_TYPE_NONE;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.sid forKey:SID];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.type] forKey:TYPE];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.delta] forKey:DELTA];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.sid = [aDecoder decodeObjectForKey:SID];
        self.type = [[aDecoder decodeObjectForKey:TYPE] integerValue];
        self.delta = [[aDecoder decodeObjectForKey:DELTA] integerValue];
    }
    return self;
}

@end
