//
//  JBColorConstants.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/7/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#define UIColorFromHex(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:1.0]

#pragma mark - Navigation

#define kJBColorNavigationBarTint UIColorFromHex(0xFFFFFF)
#define kJBColorNavigationTint UIColorFromHex(0x000000)

#pragma mark - Bar Chart

#define kJBColorBarChartControllerBackground UIColorFromHex(0x313131)
#define kJBColorBarChartBackground [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]
#define kJBColorBarChartBarBlue UIColorFromHex(0x08bcef)
#define kJBColorBarChartBarGreen UIColorFromHex(0x34b234)
#define kJBColorBarChartBarGray [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0]
#define kJBColorBarChartBarYello [UIColor yellowColor]
#define kJBColorBarChartBarRed [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]
#define kJBColorBarChartHeaderSeparatorColor UIColorFromHex(0x686868)

#pragma mark - Line Chart

#define kJBColorLineChartControllerBackground UIColorFromHex(0xb7e3e4)
#define kJBColorLineChartBackground UIColorFromHex(0xb7e3e4)
#define kJBColorLineChartHeader UIColorFromHex(0x1c474e)
#define kJBColorLineChartHeaderSeparatorColor UIColorFromHex(0x8eb6b7)
#define kJBColorLineChartDefaultSolidLineColor [UIColor colorWithWhite:1.0 alpha:0.5]
#define kJBColorLineChartDefaultSolidSelectedLineColor [UIColor colorWithWhite:1.0 alpha:1.0]
#define kJBColorLineChartDefaultDashedLineColor [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0]
#define kJBColorLineChartDefaultDashedSelectedLineColor [UIColor colorWithWhite:1.0 alpha:1.0]
#define kJBColorLineChartDefaultSolidFillColor [UIColor clearColor]
#define kJBColorLineChartDefaultDashedFillColor [UIColor colorWithWhite:1.0 alpha:0.3]
#define kJBColorLineChartDefaultGradientStartColor UIColorFromHex(0x0000FF)
#define kJBColorLineChartDefaultGradientEndColor UIColorFromHex(0x00FF00)
#define kJBColorLineChartDefaultFillGradientStartColor UIColorFromHex(0xFFFFFF)
#define kJBColorLineChartDefaultFillGradientEndColor UIColorFromHex(0xbe0000)

#define mark - Area Chart

#define kJBColorAreaChartControllerBackground UIColorFromHex(0xb7e3e4)
#define kJBColorAreaChartBackground UIColorFromHex(0xb7e3e4)
#define kJBColorAreaChartHeader UIColorFromHex(0x1c474e)
#define kJBColorAreaChartHeaderSeparatorColor UIColorFromHex(0x8eb6b7)
#define kJBColorAreaChartDefaultSunLineColor [UIColor clearColor]
#define kJBColorAreaChartDefaultSunAreaColor [UIColorFromHex(0xfcfb3a) colorWithAlphaComponent:0.5]
#define kJBColorAreaChartDefaultSunSelectedLineColor [UIColor clearColor]
#define kJBColorAreaChartDefaultSunSelectedAreaColor UIColorFromHex(0xfcfb3a)
#define kJBColorAreaChartDefaultMoonLineColor [UIColor clearColor]
#define kJBColorAreaChartDefaultMoonAreaColor [[UIColor blackColor] colorWithAlphaComponent:0.5]
#define kJBColorAreaChartDefaultMoonSelectedLineColor [UIColor clearColor]
#define kJBColorAreaChartDefaultMoonSelectedAreaColor [UIColor blackColor]

#pragma mark - Tooltips

#define kJBColorTooltipColor [UIColor colorWithWhite:1.0 alpha:0.9]
#define kJBColorTooltipTextColor UIColorFromHex(0x313131)
