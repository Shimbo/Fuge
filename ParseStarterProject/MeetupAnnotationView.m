//
//  MeetupAnnotationView.m
//  SecondCircle
//
//  Created by Constantine Fry on 4/6/13.
//
//

#import "MeetupAnnotationView.h"
#import "CustomBadge.h"
#import <QuartzCore/QuartzCore.h>
#import "MainStyle.h"

@implementation MeetupAnnotationView

- (id) initWithAnnotation: (id <MKAnnotation>) annotation reuseIdentifier: (NSString *) reuseIdentifier
{
    self = [super initWithAnnotation: annotation reuseIdentifier: reuseIdentifier];
    if (self != nil)
    {
        self.frame = CGRectMake(0, 0, 82, 60);
        self.opaque = NO;
        _time = 0.4;
        [self setPinPrivacy:PinPublic];
        [self setNeedsDisplay];
    }
    return self;
}

-(void)updateBadgeForColor:(PinColor)color{
    _timerColor = nil;
    UIColor *badgeColor = nil;
    switch (color) {
        case PinBlue:
            badgeColor = [MainStyle blueColor];
            _timerColor = [MainStyle lightBlueColor];
            break;
        case PinOrange:
            badgeColor = [MainStyle orangeColor];
            _timerColor = [MainStyle yellowColor];
            break;
        case PinGray:
            badgeColor = [MainStyle grayColor];
            _timerColor = [UIColor clearColor];
            break;
    }
    _badge = [CustomBadge badgeWithWhiteBackgroundAndTextColor:badgeColor];
    _badge.center = CGPointMake(8, 0);
}



-(void)updateBackForColor:(PinColor)color{
    switch (color) {
        case PinBlue:
            _back = [UIImage imageNamed:@"meetPinBlue.png"];
            break;
        case PinOrange:
            _back = [UIImage imageNamed:@"meetPinOrange.png"];
            break;
        case PinGray:
            _back = [UIImage imageNamed:@"meetPinGray.png"];
            break;
        default:
            NSLog(@"Color Error");
            break;
    }
}

-(void)setPinColor:(PinColor)color{
    [self updateBadgeForColor:color];
    [self updateBackForColor:color];
//    [self setNeedsDisplay];
}

-(void)setPinPrivacy:(PinPrivacy)privacy{
    switch (privacy) {
        case PinPrivate:
            _icon = [UIImage imageNamed:@"iconPrivate.png"];
            break;
        case PinPublic:
            _icon = [UIImage imageNamed:@"iconPublic.png"];
            break;
        default:
            NSLog(@"Privacy Error");
            break;
    }
//    [self setNeedsDisplay];
}

-(void)setTime:(CGFloat)time{
    _time = time;
    if (_time == 0) {
        _time = 0.00001;
    }
    if (_time == 1) {
        _time = 0.99999;
    }
//    [self setNeedsDisplay];
}


-(void)setUnreaCount:(NSUInteger)count{
    [_badge setNumber:count];
//    [self setNeedsDisplay];
}

-(void)prepareForAnnotation:(MeetupAnnotation*)ann{
    [self setPinColor:ann.pinColor];
    [self setPinPrivacy:ann.pinPrivacy];
    [self setTime:ann.time];
    [self setUnreaCount:ann.numUnreadCount];
    [self setNeedsDisplay];
}













-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    [_back drawInRect:CGRectMake(16, 2, _back.size.width, _back.size.height)];
    CGRect iconRect =CGRectMake(self.frame.size.width/2-_icon.size.width/2,
                            self.frame.size.height/2-_icon.size.height/2-4,
                            _icon.size.width, _icon.size.height);
    [_icon drawInRect:iconRect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextTranslateCTM(context,
                          _badge.frame.origin.x+_badge.frame.size.width/2.0,
                          _badge.frame.origin.y+_badge.frame.size.height/2.0);
    [_badge.layer renderInContext:context];
    CGContextRestoreGState(context);
    [self drawTimeInContext:context];
}

-(void)drawTimeInContext:(CGContextRef)context{
    CGContextSaveGState(context);
    CGRect allRect = CGRectMake(25, 11, 31, 31);
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
    CGContextRestoreGState(context);
}


@end
