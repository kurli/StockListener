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
#define AXIS_FONT_SIZE_DOUBLE    (20)

#define AXIS_BOTTOM_LINE_HEIGHT (1)
#define AXIS_LEFT_LINE_WIDTH (1)

#define FLOAT_NUMBER_FORMATTER_STRING  @"%.f"

#define DEVICE_WIDTH   (320)

#define AXIX_LINE_WIDTH (0.5)



#pragma mark -

@interface PNLineChartView () {
    CGPoint longPressPoint;
    BOOL showLongPress;
    float lastScale;
}

@property (nonatomic, strong) NSString* fontName;
@property (nonatomic, strong) NSTimer* hideLongPressTimer;
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
    
    self.pointerInterval = 0;
    
    self.axisBottomLinetHeight = AXIS_BOTTOM_LINE_HEIGHT;
    self.axisLeftLineWidth = AXIS_LEFT_LINE_WIDTH;
    self.axisLineWidth = AXIX_LINE_WIDTH;
    
    self.floatNumberFormatterString = FLOAT_NUMBER_FORMATTER_STRING;
    
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [[UIColor grayColor] CGColor];
    
    UILongPressGestureRecognizer *longPressGR =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(handleLongPress:)];
    longPressGR.allowableMovement=YES;
    longPressGR.minimumPressDuration = 0.2;
    [self addGestureRecognizer:longPressGR];

    self.splitX = 0;
    self.startIndex = 0;
    self.markY = -10;
    self.markYColor = [UIColor blackColor];

    showLongPress = NO;
    self.yAxisPercentage = NO;
    self.handleLongClick = YES;
    
    self.lines = [[NSMutableArray alloc] init];
    self.splitXArray = [[NSMutableArray alloc] init];
    self.maxXCount = 0;
}

-(void) enableGesture {
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:pan];
    
    UIPinchGestureRecognizer *zoom = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoom:)];
    [self addGestureRecognizer:zoom];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];
}

-(void) onHideLongPressFired {
    showLongPress = NO;
    [self setNeedsDisplay];
}

-(void) handleTap:(UITapGestureRecognizer*)rec {
    if (rec.state == UIGestureRecognizerStateEnded) {
        if (self.onTap != nil) {
            self.onTap(true);
        }
    }
}

-(void) handleZoom:(UIPinchGestureRecognizer*)rec {
    
    if (rec.state == UIGestureRecognizerStateEnded) {
        if (self.onScale != nil) {
            self.onScale(rec.scale - lastScale, true);
        }
    } else if (rec.state == UIGestureRecognizerStateBegan) {
        lastScale = rec.scale;
    } else {
        if (self.onScale != nil) {
            self.onScale(rec.scale - lastScale, false);
        }
    }
    lastScale = rec.scale;
}

- (void) handlePan: (UIPanGestureRecognizer *)rec{
    CGPoint point = [rec translationInView:self];
    
    if (rec.state == UIGestureRecognizerStateEnded) {
        if (self.onScroll != nil) {
            self.onScroll(point.x, true);
        }
    } else {
        if (self.onScroll != nil) {
            self.onScroll(point.x, false);
        }
    }
}

-(IBAction)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer{
    if (!self.handleLongClick) {
        return;
    }
    longPressPoint = [gestureRecognizer locationInView:self];
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        showLongPress = YES;
        [self.hideLongPressTimer invalidate];
        [self setHideLongPressTimer:nil];
    } else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
//        showLongPress = NO;
        self.hideLongPressTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(onHideLongPressFired) userInfo:nil repeats:NO];
    }
    [self setNeedsDisplay];
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

-(float) getHeightByPrice:(float)price {
    return (price-self.min)/self.interval*self.horizontalLineInterval+self.axisBottomLinetHeight;
}

#define UIColorFromHex(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:1.0]

-(void) drawLine:(UIColor*)color andP1:(CGPoint)p1 andP2:(CGPoint)p2 {
    // Draw edit line
    if (self.interval*self.horizontalLineInterval != 0){
        CGContextRef context = UIGraphicsGetCurrentContext();

        CGFloat startHeight = self.axisBottomLinetHeight;
        CGFloat startWidth = self.axisLeftLineWidth;
        float height = (p1.y-self.min)/self.interval*self.horizontalLineInterval+startHeight;
        float width =startWidth + self.pointerInterval*(p1.x);
        if (color == nil) {
            color = [UIColor blackColor];
        }
        [color set];
        CGContextSetLineWidth(context, 2);
        CGFloat lengths[] = {};
        CGContextSetLineDash(context, 0, lengths,0);
        CGContextMoveToPoint(context,  width, height);
        height = (p2.y-self.min)/self.interval*self.horizontalLineInterval+startHeight;
        width =startWidth + self.pointerInterval*(p2.x) + self.pointerInterval/2;
        CGContextAddLineToPoint(context, width, height);
        CGContextStrokePath(context);
    }
}

-(void) drawKLine:(CGContextRef)context andPlot:(PNPlot*)plot {
    [plot.lineColor set];
    CGContextSetLineWidth(context, plot.lineWidth);
    
    NSArray* pointArray = plot.plottingValues;
    
    // draw lines
    for (NSInteger i=self.startIndex; i<pointArray.count; i++) {
        NSObject* obj = [pointArray objectAtIndex:i];
        if ([obj isKindOfClass:[NSArray class]] == NO) {
            continue;
        }
        
        NSArray* value = [pointArray objectAtIndex:i];
        if ([value count] != 4) {
            continue;
        }
        float open = [[value objectAtIndex:0] floatValue];
        float highest = [[value objectAtIndex:1] floatValue];
        float curPrice = [[value objectAtIndex:2] floatValue];
        float lowest = [[value objectAtIndex:3] floatValue];
        
        float openY = [self getHeightByPrice:open];
        float curY = [self getHeightByPrice:curPrice];
        float hY = [self getHeightByPrice:highest];
        float lY = [self getHeightByPrice:lowest];
        float width =self.axisLeftLineWidth + self.pointerInterval*(i-self.startIndex);
        
        if (openY > curY) {
            [[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1] set];
            [UIColorFromHex(0x34b234) set];
        } else {
            [[UIColor redColor] set];
        }
        // Draw highest & lowest
        CGContextMoveToPoint(context, width+self.pointerInterval/2, lY);
        CGContextAddLineToPoint(context, width+self.pointerInterval/2, hY);
        CGContextStrokePath(context);

        // Draw rect
        float h = curY - openY;
        if (h == 0) {
            h = plot.lineWidth;
        }
        CGContextFillRect(context, CGRectMake(width, openY, self.pointerInterval, h));
        CGContextStrokePath(context);
    }
    
    CGContextStrokePath(context);
}

-(void)drawRect:(CGRect)rect{
    CGFloat startHeight = self.axisBottomLinetHeight;
    CGFloat startWidth = self.axisLeftLineWidth;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0f , self.bounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    
    // set text size and font
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSelectFont(context, [self.fontName UTF8String], self.xAxisFontSize, kCGEncodingMacRoman);
    
    if (self.yAxisPercentage == YES) {
        if ([self.plots count] > 0) {
            PNPlot* plot = [self.plots objectAtIndex:0];
            NSArray* pointArray = plot.plottingValues;
            //Find obj
            NSObject* obj = nil;
            for (NSInteger i=[pointArray count]-1; i>=0; i--) {
                obj = [pointArray objectAtIndex:i];
                if ([obj isKindOfClass:[NSNumber class]] == YES ||
                    [obj isKindOfClass:[NSArray class]] == YES) {
                    break;
                }
                obj = nil;
            }
            if (obj != nil) {
                NSNumber* value = (NSNumber*)obj;
                if (plot.isKLine == YES) {
                    NSArray* array = (NSArray*)obj;
                    value = [array objectAtIndex:2];
                }
                float base = [value floatValue];
                float delta = self.max - self.min;
                delta = delta/5;
                delta = delta / base;
                if (delta <= 0.0025) {
                    delta = 0.002;
                } else if (delta <= 0.0055) {
                    delta = 0.005;
                } else if (delta <= 0.015) {
                    delta = 0.01;
                } else if (delta <= 0.025) {
                    delta = 0.02;
                } else if (delta <= 0.055) {
                    delta = 0.05;
                } else if (delta <= 0.15) {
                    delta = 0.1;
                }

                CGContextSetLineWidth(context, self.horizontalLineWidth);
                [self.horizontalLinesColor set];
                NSString* numberString = @"0%";
                NSInteger count = [numberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                
                // Draw current
                float height = (base-self.min)/self.interval*self.horizontalLineInterval+startHeight;
                CGContextMoveToPoint(context, startWidth, height);
                CGContextAddLineToPoint(context, self.bounds.size.width, height);
                CGContextStrokePath(context);
                [[UIColor blackColor] set];
                CGContextShowTextAtPoint(context, 0, height - self.xAxisFontSize/2, [numberString UTF8String], count);

                // Draw above
                for (int i=1; i<15; i++) {
                    numberString = [NSString stringWithFormat:@"%.1f%%", i*delta*100];
                    NSInteger count = [numberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                    height = (base*(1+i*delta)-self.min)/self.interval*self.horizontalLineInterval+startHeight;
                    if (height > self.frame.size.height-10) {
                        break;
                    }
                    [self.horizontalLinesColor set];
                    CGContextMoveToPoint(context, startWidth, height);
                    CGContextAddLineToPoint(context, self.bounds.size.width, height);
                    CGContextStrokePath(context);
                    [[UIColor blackColor] set];
                    CGContextShowTextAtPoint(context, 0, height - self.xAxisFontSize/2, [numberString UTF8String], count);
                }

                // Draw down
                for (int i=1; i<15; i++) {
                    numberString = [NSString stringWithFormat:@"-%.1f%%", i*delta*100];
                    NSInteger count = [numberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                    height = (base*(1-i*delta)-self.min)/self.interval*self.horizontalLineInterval+startHeight;
                    if (height < 10) {
                        break;
                    }
                    [self.horizontalLinesColor set];
                    CGContextMoveToPoint(context, startWidth, height);
                    CGContextAddLineToPoint(context, self.bounds.size.width, height);
                    CGContextStrokePath(context);
                    [[UIColor blackColor] set];
                    CGContextShowTextAtPoint(context, 0, height - self.xAxisFontSize/2, [numberString UTF8String], count);
                }
            }
        }
    } else {
        // draw yAxis
        for (int i=0; i<self.numberOfVerticalElements; i++) {
            float height =self.horizontalLineInterval*i;
            float verticalLine = height + startHeight;
            
            CGContextSetLineWidth(context, self.horizontalLineWidth);
            
            [self.horizontalLinesColor set];
            
            NSNumber* yAxisVlue = [self.yAxisValues objectAtIndex:i];
            
            NSString* numberString = [NSString stringWithFormat:self.floatNumberFormatterString, yAxisVlue.floatValue];
            
            NSInteger count = [numberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            
            CGContextMoveToPoint(context, startWidth, verticalLine);
            if (i == 0) {
                CGContextAddLineToPoint(context, self.bounds.size.width, verticalLine);
                CGContextStrokePath(context);
                [[UIColor blackColor] set];
                CGContextShowTextAtPoint(context, 0, 1, [numberString UTF8String], count);
            } else if (i == self.numberOfVerticalElements-1) {
                CGContextAddLineToPoint(context, self.bounds.size.width, verticalLine);
                CGContextStrokePath(context);
                [[UIColor blackColor] set];
                CGContextShowTextAtPoint(context, 0, verticalLine - self.xAxisFontSize, [numberString UTF8String], count);
            }
            else {
                CGContextAddLineToPoint(context, self.bounds.size.width, verticalLine);
                CGContextStrokePath(context);
                [[UIColor blackColor] set];
                CGContextShowTextAtPoint(context, 0, verticalLine - self.xAxisFontSize/2, [numberString UTF8String], count);
            }
        }
    }
    
    // draw x line
    if (self.xAxisInterval != 0) {
        for (int i=0; i<(self.frame.size.width-startWidth)/self.xAxisInterval; i++) {
            int x = self.xAxisInterval * i;
            CGContextSetLineWidth(context, self.horizontalLineWidth);
            
            [self.horizontalLinesColor set];
            
            CGContextMoveToPoint(context, startWidth + x, 0);
            CGContextAddLineToPoint(context, startWidth + x, self.frame.size.height);
            CGContextStrokePath(context);
        }
    }
    
    // Draw lines
    if ([self.lines count] != 0) {
        for (int i=0; i < [self.lines count]; i++) {
            NSArray* array = [self.lines objectAtIndex:i];
            if ([array count] == 5) {
                UIColor* color = [array objectAtIndex:0];
                float x0 = [[array objectAtIndex:1] floatValue];
                float y0 = [[array objectAtIndex:2] floatValue];
                float xn = [[array objectAtIndex:3] floatValue];
                float yn = [[array objectAtIndex:4] floatValue];
                [self drawLine:color andP1:CGPointMake(x0, y0) andP2:CGPointMake(xn, yn)];
            }
        }
    }
    
    // draw lines
    for (int i=0; i<self.plots.count; i++)
    {
        PNPlot* plot = [self.plots objectAtIndex:i];
        if (plot.isKLine == YES) {
            [self drawKLine:context andPlot:plot];
            continue;
        }
        
        [plot.lineColor set];
        CGContextSetLineWidth(context, plot.lineWidth);

        NSArray* pointArray = plot.plottingValues;
        
        // draw lines
        BOOL newLine = NO;
        for (NSInteger i=self.startIndex; i<pointArray.count; i++) {
            NSObject* obj = [pointArray objectAtIndex:i];
            if ([obj isKindOfClass:[NSNumber class]] == NO) {
                CGContextStrokePath(context);
                newLine = YES;
                continue;
            }
            NSNumber* value = [pointArray objectAtIndex:i];
            float floatValue = value.floatValue;
            
            float height = (floatValue-self.min)/self.interval*self.horizontalLineInterval+startHeight;
            float width =startWidth + self.pointerInterval*(i-self.startIndex) + self.pointerInterval/2;
            
            if (plot.isDashLine) {
                CGFloat lengths[] = {2,2};
                CGContextSetLineDash(context, 0, lengths,2);
            } else {
                CGFloat lengths[] = {};
                CGContextSetLineDash(context, 0, lengths,0);
            }
            
            if (i==self.startIndex || newLine) {
                CGContextMoveToPoint(context,  width, height);
                newLine = NO;
            }
            else{
                CGContextAddLineToPoint(context, width, height);
            }
        }
        
        CGContextStrokePath(context);
    }
    CGFloat lengths[] = {};
    CGContextSetLineDash(context, 0, lengths,0);
    
    for (int i=0; i<[self.splitXArray count]; i++) {
        NSInteger sx = [[self.splitXArray objectAtIndex:i] integerValue];
        int x = startWidth + self.pointerInterval*(sx-self.startIndex) + self.pointerInterval/2;
        CGContextSetLineWidth(context, 1);
        [[UIColor blackColor] set];
        CGContextMoveToPoint(context,  x, 0);
        CGContextAddLineToPoint(context, x, self.frame.size.height);
        CGContextStrokePath(context);
        
        [[UIColor blackColor] set];
        NSString* number;
        if (i == 0) {
            number = @"0";
        } else {
            NSInteger delta = sx - [[self.splitXArray objectAtIndex:i-1] integerValue] + 1;
            number = [NSString stringWithFormat:@"%ld", delta];
        }
        CGContextShowTextAtPoint(context, x, 5, [number UTF8String], [number length]);
    }
    if ([self.splitXArray count] > 0) {
        NSInteger sx = [[self.splitXArray lastObject] integerValue];
        NSString* number = [NSString stringWithFormat:@"%ld", self.maxXCount - sx + 1];
        int x = startWidth + self.pointerInterval*(self.maxXCount-self.startIndex-1) + self.pointerInterval/2;
        CGContextShowTextAtPoint(context, x, 5, [number UTF8String], [number length]);
    }

    if (self.splitX > 0) {
        int x = startWidth + self.pointerInterval*(self.splitX) + startHeight;
        CGContextSetLineWidth(context, 1);
        [[UIColor blackColor] set];
        CGContextMoveToPoint(context,  x, 0);
        CGContextAddLineToPoint(context, x, self.frame.size.height);
        CGContextStrokePath(context);
    }
    
    if (showLongPress == YES) {
        CGContextSetLineWidth(context, 1);
        [[UIColor blackColor] set];
        CGContextMoveToPoint(context,  startWidth, self.frame.size.height - longPressPoint.y);
        CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height - longPressPoint.y);
        CGContextStrokePath(context);
        CGContextMoveToPoint(context,  longPressPoint.x, self.frame.size.height);
        CGContextAddLineToPoint(context, longPressPoint.x, 0);
        CGContextStrokePath(context);
        float value = ((self.frame.size.height - longPressPoint.y)-startHeight)/self.horizontalLineInterval*self.interval +self.min;
        
        NSObject* curValue = nil;
        if ([self.plots count] > 0) {
            PNPlot* plot = [self.plots objectAtIndex:0];
            NSArray* pointArray = plot.plottingValues;
            //Find obj
            for (NSInteger i=[pointArray count]-1; i>=0; i--) {
                curValue = [pointArray objectAtIndex:i];
                if ([curValue isKindOfClass:[NSNumber class]] == YES) {
                    break;
                }
                if ([[pointArray objectAtIndex:i] isKindOfClass:[NSArray class]] == YES) {
                    NSArray* array = [pointArray objectAtIndex:i];
                    curValue = [array objectAtIndex:2];
                    break;
                }
                curValue = nil;
            }
        }

        NSString* str;
        if (value < 3) {
            if (curValue != nil) {
                float curValueF = [(NSNumber*)curValue floatValue];
                if (curValueF != 0) {
                    str = [NSString stringWithFormat:@"%.3f (%.2f%%)", value, (value-curValueF)/curValueF*100];
                } else {
                    str = [NSString stringWithFormat:@"%.3f", value];
                }
            } else {
                str = [NSString stringWithFormat:@"%.3f", value];
            }
        } else {
            if (curValue != nil) {
                float curValueF = [(NSNumber*)curValue floatValue];
                if (curValueF != 0) {
                    str = [NSString stringWithFormat:@"%.2f (%.2f%%)", value, (value-curValueF)/curValueF*100];
                } else {
                    str = [NSString stringWithFormat:@"%.2f", value];
                }
            } else {
                str = [NSString stringWithFormat:@"%.2f", value];
            }
        }
        NSInteger count = [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        [[UIColor lightTextColor] set];
        float x = self.frame.size.width - 100;
        float y = self.frame.size.height - longPressPoint.y + 5;
        CGContextFillRect(context, CGRectMake(x, y, count * 10, 15));
        [[UIColor blackColor] set];

        CGContextSelectFont(context, [self.fontName UTF8String], self.xAxisFontSize*1.5, kCGEncodingMacRoman);
        CGContextShowTextAtPoint(context, x, y, [str UTF8String], count);
    }

    if (self.markY > -10) {
        float height = (self.markY-self.min)/self.interval*self.horizontalLineInterval+startHeight;
        [self.markYColor set];
        CGContextSetLineWidth(context, 1);
        CGFloat lengths[] = {10,10};
        CGContextSetLineDash(context, 0, lengths,2);
        CGContextMoveToPoint(context,  startWidth, height);
        CGContextAddLineToPoint(context, self.frame.size.width, height);
        CGContextStrokePath(context);
        float x = startWidth;
        float y = height + 5;
        NSInteger count = [self.infoStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        [[UIColor lightTextColor] set];
        CGContextFillRect(context, CGRectMake(x, y, count * 8, 15));
        [[UIColor blackColor] set];
        CGContextSelectFont(context, [self.fontName UTF8String], self.xAxisFontSize*1.5, kCGEncodingMacRoman);
        CGContextShowTextAtPoint(context, x, y, [self.infoStr UTF8String], count);
    }
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

-(float) getPriceByY:(float)y {
    return ((self.frame.size.height - y)-self.axisBottomLinetHeight)/self.horizontalLineInterval*self.interval +self.min;
}

-(int) getTimeDeltaByX:(float)x {
    if (self.xAxisInterval == 0) {
        return 0;
    }
    return (x) / self.xAxisInterval;
}
@end

