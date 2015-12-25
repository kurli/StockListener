// PNLineChartView.h
//
// Copyright (c) 2014 John Yung pincution@gmail.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <UIKit/UIKit.h>

@class PNPlot;

@interface PNLineChartView : UIView


@property (nonatomic, strong) NSArray *xAxisValues;
@property (nonatomic, assign) NSInteger xAxisFontSize;
@property (nonatomic, strong) UIColor*  xAxisFontColor;
@property (nonatomic, assign) NSInteger numberOfVerticalElements;

@property (nonatomic, strong) UIColor * horizontalLinesColor;



@property (nonatomic, assign) float  max; // max value in the axis
@property (nonatomic, assign) float  min; // min value in the axis
@property (nonatomic, assign) float  interval; // interval value between two horizontal line
@property (nonatomic, assign) float  pointerInterval; // the x interval width between pointers

@property (nonatomic, assign) float  axisLineWidth; // axis line width
@property (nonatomic, assign) float  horizontalLineInterval; // the height between two horizontal line
@property (nonatomic, assign) float  horizontalLineWidth; // the width of the horizontal line
@property (nonatomic, assign) float  axisBottomLinetHeight;  // xAxis line off the view
@property (nonatomic, assign) float  axisLeftLineWidth;   //yAxis line between the view left

@property (nonatomic, strong) NSString*  floatNumberFormatterString; // the yAxis label text should be formatted with


@property (nonatomic, strong) NSArray* yAxisValues; // array of number

/**
 *  readyonly dictionary that stores all the plots in the graph.
 */
@property (nonatomic, readonly, strong) NSMutableArray *plots;






/**
 *  this method will add a Plot to the graph.
 *
 *  @param newPlot the Plot that you want to draw on the Graph.
 */
- (void)addPlot:(PNPlot *)newPlot;
-(void)clearPlot;
@end
