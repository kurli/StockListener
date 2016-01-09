//
//  StockInfo.h
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StockInfo : NSObject <NSCopying, NSCoding>

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* sid;

//Today
@property (atomic, unsafe_unretained) float changeRate;         // Current change rate by open price
@property (atomic, strong) NSMutableDictionary* buySellDic;
@property (atomic, strong) NSMutableArray* todayPriceByMinutes;
@property (atomic, strong) NSString* todayUpdateDay;
//Five day detail by minute
@property (atomic, strong) NSMutableArray* fiveDayPriceByMinutes;
@property (atomic, strong) NSString* fiveDayLastUpdateDay;
//A hundred days price (low final highest)
@property (atomic, strong) NSMutableArray* hundredDaysPrice;
@property (atomic, strong) NSString* hundredDayLastUpdateDay;

// Used for play sound
@property (atomic, unsafe_unretained) int step;                 // Used for play sound
@property (atomic, unsafe_unretained) float speed;              // last change SPEED

// Today detail
@property (atomic, unsafe_unretained) float openPrice;          //1
@property (atomic, unsafe_unretained) float lastDayPrice;       //2
@property (atomic, unsafe_unretained) float price;              //3
@property (atomic, unsafe_unretained) float todayHighestPrice;  //4
@property (atomic, unsafe_unretained) float todayLoestPrice;    //5
@property (atomic, unsafe_unretained) long   dealCount;          //8
@property (atomic, unsafe_unretained) float dealTotalMoney;     //9
@property (atomic, unsafe_unretained) long buyOneCount;          //10
@property (atomic, unsafe_unretained) float buyOnePrice;        //11
@property (atomic, unsafe_unretained) long buyTwoCount;          //12
@property (atomic, unsafe_unretained) float buyTwoPrice;        //13
@property (atomic, unsafe_unretained) long buyThreeCount;        //14
@property (atomic, unsafe_unretained) float buyThreePrice;      //15
@property (atomic, unsafe_unretained) long buyFourCount;         //16
@property (atomic, unsafe_unretained) float buyFourPrice;       //17
@property (atomic, unsafe_unretained) long buyFiveCount;         //18
@property (atomic, unsafe_unretained) float buyFivePrice;       //19
@property (atomic, unsafe_unretained) long sellOneCount;         //20
@property (atomic, unsafe_unretained) float sellOnePrice;       //21
@property (atomic, unsafe_unretained) long sellTwoCount;         //22
@property (atomic, unsafe_unretained) float sellTwoPrice;       //23
@property (atomic, unsafe_unretained) long sellThreeCount;       //24
@property (atomic, unsafe_unretained) float sellThreePrice;     //25
@property (atomic, unsafe_unretained) long sellFourCount;        //26
@property (atomic, unsafe_unretained) float sellFourPrice;      //27
@property (atomic, unsafe_unretained) long sellFiveCount;        //28
@property (atomic, unsafe_unretained) float sellFivePrice;      //29
@property (atomic, strong) NSString* updateDay;                 //30
@property (atomic, strong) NSString* updateTime;                //31

-(void) newPriceGot;

//temp data
//@property (atomic, strong) NSMutableArray* changeRateArray;

//-(void) assign:(StockInfo*) info;
@end