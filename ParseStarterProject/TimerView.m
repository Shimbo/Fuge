//
//  TimerView.m
//  SecondCircle
//
//  Created by Constantine Fry on 5/26/13.
//
//

#import "TimerView.h"

@implementation TimerView
- (id)init
{
    self = [super initWithFrame:CGRectMake(6.5, 6.5, 36, 36)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)drawRect:(CGRect)rect{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect allRect = CGRectMake(2.5, 2.5, rect.size.width-5, rect.size.height-5);
	const CGFloat* c = CGColorGetComponents(_timerColor.CGColor);
    CGContextSetStrokeColor(context, c); // white
    float x = CGRectGetMidX(allRect);
    float y = CGRectGetMidY(allRect);
    CGContextMoveToPoint(context, x, y-allRect.size.height/2);
    CGContextAddArc(context, x, y,
                    allRect.size.height/2,
                    -M_PI_2,
                    2 * M_PI * (1 - _time) - M_PI_2,
                    1);
    CGContextSetLineWidth(context, 5);
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextDrawPath(context, kCGPathStroke);
}


@end
