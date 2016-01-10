// PNLineChartView.m
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

#import "PNLineChartView.h"
#import "PNPlot.h"
#import <math.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>


#pragma mark -
#pragma mark MACRO

#define POINT_CIRCLE  6.0f
#define NUMBER_VERTICAL_ELEMENTS (2)
#define HORIZONTAL_LINE_SPACES (50)
#define HORIZONTAL_LINE_WIDTH (0.2)
#define HORIZONTAL_START_LINE (0.17)
#define POINTER_WIDTH_INTERVAL  (50)
#define AXIS_FONT_SIZE    (10)

#define AXIS_BOTTOM_LINE_HEIGHT (1)
#define AXIS_LEFT_LINE_WIDTH (1)

#define FLOAT_NUMBER_FORMATTER_STRING  @"%.f"

#define DEVICE_WIDTH   (320)

#define AXIX_LINE_WIDTH (0.5)



#pragma mark -

@interface PNLineChartView ()

@property (nonatomic, strong) NSString* fontName;
@property (nonatomic, assign) CGPoint contentScroll;
@end


@implementation PNLineChartView


#pragma mark -
#pragma mark init

-(void)commonInit{
    
    self.fontName=@"Helvetica";
    self.numberOfVerticalElements=NUMBER_VERTICAL_ELEMENTS;
    self.xAxisFontColor = [UIColor darkGrayColor];
    self.xAxisFontSize = AXIS_FONT_SIZE;
    self.horizontalLinesColor = [UIColor lightGrayColor];
    
    self.horizontalLineInterval = HORIZONTAL_LINE_SPACES;
    self.horizontalLineWidth = HORIZONTAL_LINE_WIDTH;
    
    self.pointerInterval = DEVICE_WIDTH/35;
    
    self.axisBottomLinetHeight = AXIS_BOTTOM_LINE_HEIGHT;
    self.axisLeftLineWidth = AXIS_LEFT_LINE_WIDTH;
    self.axisLineWidth = AXIX_LINE_WIDTH;
    
    self.floatNumberFormatterString = FLOAT_NUMBER_FORMATTER_STRING;
    
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [[UIColor grayColor] CGColor];
}

- (instancetype)init {
  if((self = [super init])) {
      [self commonInit];
  }
  return self;
}

- (void)awakeFromNib
{
      [self commonInit];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
       [self commonInit];
    }
    return self;
}

#pragma mark -
#pragma mark Plots

- (void)addPlot:(PNPlot *)newPlot;
{
    if(nil == newPlot ) {
        return;
    }
    
    if (newPlot.plottingValues.count ==0) {
        return;
    }
    
    
    if(self.plots == nil){
        _plots = [NSMutableArray array];
    }
    
    [self.plots addObject:newPlot];
    
    [self layoutIfNeeded];
}

-(void)clearPlot{
    if (self.plots) {
        [self.plots removeAllObjects];
    }
}

#pragma mark -
#pragma mark Draw the lineChart

-(void)drawRect:(CGRect)rect{
    CGFloat startHeight = self.axisBottomLinetHeight;
    CGFloat startWidth = self.axisLeftLineWidth;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0f , self.bounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    
    // set text size and font
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSelectFont(context, [self.fontName UTF8String], self.xAxisFontSize, kCGEncodingMacRoman);
    
    // draw yAxis
    for (int i=0; i<self.numberOfVerticalElements; i++) {
        int height =self.horizontalLineInterval*i;
        float verticalLine = height + startHeight - self.contentScroll.y;
        
        CGContextSetLineWidth(context, self.horizontalLineWidth);
        
        [self.horizontalLinesColor set];
        
        NSNumber* yAxisVlue = [self.yAxisValues objectAtIndex:i];
        
        NSString* numberString = [NSString stringWithFormat:self.floatNumberFormatterString, yAxisVlue.floatValue];
        
        NSInteger count = [numberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        
        if (i == 0) {
            CGContextMoveToPoint(context, startWidth, verticalLine);
            CGContextAddLineToPoint(context, self.bounds.size.width, verticalLine);
            CGContextStrokePath(context);
            CGContextShowTextAtPoint(context, 0, 1, [numberString UTF8String], count);
        } else if (i == self.numberOfVerticalElements-1) {
            CGContextMoveToPoint(context, startWidth, verticalLine);
            CGContextAddLineToPoint(context, self.bounds.size.width, verticalLine);
            CGContextStrokePath(context);
            CGContextShowTextAtPoint(context, 0, verticalLine - self.xAxisFontSize, [numberString UTF8String], count);
        }
        else {
            CGContextMoveToPoint(context, startWidth, verticalLine);
            CGContextAddLineToPoint(context, self.bounds.size.width, verticalLine);
            CGContextStrokePath(context);
            CGContextShowTextAtPoint(context, 0, verticalLine - self.xAxisFontSize/2, [numberString UTF8String], count);
        }
    }
    
    // draw x line
    if (self.xAxisInterval != 0) {
        for (int i=1; i<DEVICE_WIDTH/self.xAxisInterval; i++) {
            int x = self.xAxisInterval * i;
            CGContextSetLineWidth(context, self.horizontalLineWidth);
            
            [self.horizontalLinesColor set];
            
            CGContextMoveToPoint(context, startWidth + x, 0);
            CGContextAddLineToPoint(context, startWidth + x, self.frame.size.height);
            CGContextStrokePath(context);
        }
    }
    // draw lines
    for (int i=0; i<self.plots.count; i++)
    {
        PNPlot* plot = [self.plots objectAtIndex:i];
        
        [plot.lineColor set];
        CGContextSetLineWidth(context, plot.lineWidth);

        NSArray* pointArray = plot.plottingValues;
        
        // draw lines
        BOOL newLine = NO;
        for (int i=0; i<pointArray.count; i++) {
            NSObject* obj = [pointArray objectAtIndex:i];
            if ([obj isKindOfClass:[NSNumber class]] == NO) {
                CGContextStrokePath(context);
                newLine = YES;
                continue;
            }
            NSNumber* value = [pointArray objectAtIndex:i];
            float floatValue = value.floatValue;
            
            float height = (floatValue-self.min)/self.interval*self.horizontalLineInterval-self.contentScroll.y+startHeight;
            float width =startWidth + self.pointerInterval*(i)+self.contentScroll.x+ startHeight;
            
            if (i==0 || newLine) {
                CGContextMoveToPoint(context,  width, height);
                newLine = NO;
            }
            else{
                CGContextAddLineToPoint(context, width, height);
            }
        }
        
        CGContextStrokePath(context);
    }
    
    if (self.splitX > 0) {
        int x = startWidth + self.pointerInterval*(self.splitX)+self.contentScroll.x+ startHeight;
        CGContextSetLineWidth(context, 1);
        [[UIColor blackColor] set];
        CGContextMoveToPoint(context, startWidth + x, 0);
        CGContextAddLineToPoint(context, startWidth + x, self.frame.size.height);
        CGContextStrokePath(context);
    }
    
//    // Draw vetical focus line
//    if ([self.plots count] > 0) {
//        PNPlot* plot = [self.plots objectAtIndex:0];
//        if ([plot.plottingValues count] >= 2) {
//            float width =startWidth + self.pointerInterval*([plot.plottingPointsLabels count]-2)+self.contentScroll.x+ startHeight;
//            CGContextSetLineWidth(context, self.axisLineWidth);
//            CGContextMoveToPoint(context,  width, 0);
//            CGContextAddLineToPoint(context, width, self.bounds.size.height);
//            CGContextStrokePath(context);
//        }
//    }
    
//    [self.xAxisFontColor set];
//    CGContextSetLineWidth(context, self.axisLineWidth);
//    CGContextMoveToPoint(context, startWidth, startHeight);
//    
//    CGContextAddLineToPoint(context, startWidth, self.bounds.size.height);
//    CGContextStrokePath(context);
//    
//    CGContextMoveToPoint(context, startWidth, startHeight);
//    CGContextAddLineToPoint(context, self.bounds.size.width, startHeight);
//    CGContextStrokePath(context);
    
    // x axis text
//    for (int i=0; i<self.xAxisValues.count; i++) {
//        float width =self.pointerInterval*(i+1)+self.contentScroll.x+ startHeight;
//        float height = self.xAxisFontSize;
//        
//        if (width<startWidth) {
//            continue;
//        }
//
//        
//        NSInteger count = [[self.xAxisValues objectAtIndex:i] lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
//        CGContextShowTextAtPoint(context, width, height, [[self.xAxisValues objectAtIndex:i] UTF8String], count);
//    }
    
}

#pragma mark -
#pragma mark touch handling
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
//    CGPoint touchLocation=[[touches anyObject] locationInView:self];
//    CGPoint prevouseLocation=[[touches anyObject] previousLocationInView:self];
//    float xDiffrance=touchLocation.x-prevouseLocation.x;
//    float yDiffrance=touchLocation.y-prevouseLocation.y;
//    
//    _contentScroll.x+=xDiffrance;
//    _contentScroll.y+=yDiffrance;
//    
//    if (_contentScroll.x >0) {
//        _contentScroll.x=0;
//    }
//    
//    if(_contentScroll.y<0){
//        _contentScroll.y=0;
//    }
//    
//    if (-_contentScroll.x>(self.pointerInterval*(self.xAxisValues.count +3)-DEVICE_WIDTH)) {
//        _contentScroll.x=-(self.pointerInterval*(self.xAxisValues.count +3)-DEVICE_WIDTH);
//    }
//    
//    if (_contentScroll.y>self.frame.size.height/2) {
//        _contentScroll.y=self.frame.size.height/2;
//    }
//    
//    
//    _contentScroll.y =0;// close the move up
//    
//    [self setNeedsDisplay];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}


@end

