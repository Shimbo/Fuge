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

@interface TimerView : UIView
@property (nonatomic,assign)CGFloat time;
@property (nonatomic,strong)UIColor *timerColor;

@end

@implementation TimerView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
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







@implementation MeetupAnnotationView

- (id) initWithAnnotation: (id <MKAnnotation>) annotation reuseIdentifier: (NSString *) reuseIdentifier
{
    self = [super initWithAnnotation: annotation reuseIdentifier: reuseIdentifier];
    if (self != nil)
    {
        self.frame = CGRectMake(0, 0, 50, 60);
        self.opaque = NO;

        
        _back = [[UIImageView alloc]initWithFrame:self.bounds];
        [self addSubview:_back];
        
        _icon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"threadIcon.png"]];
        _icon.center = CGPointMake(26, 24);
        [self addSubview:_icon];

        _timerView = [[TimerView alloc]initWithFrame:CGRectMake(6.4, 6.5, 37.2, 36.2)];
        [self addSubview:_timerView];
        
        [self setPinPrivacy:PinPublic];
        [self setNeedsDisplay];
    }
    return self;
}

-(void)updateBadgeForColor:(PinColor)color{
    UIColor *badgeColor = nil;
    switch (color) {
        case PinBlue:
            badgeColor = [MainStyle blueColor];
            break;
        case PinOrange:
            badgeColor = [MainStyle orangeColor];
            break;
        case PinGray:
            badgeColor = [MainStyle grayColor];
            break;
    }
    _badge = [CustomBadge badgeWithWhiteBackgroundAndTextColor:badgeColor];
    _badge.center = CGPointMake(8, 8);
    [self addSubview:_badge];
}


-(void)updateTimerForColor:(PinColor)color{
    switch (color) {
        case PinBlue:
            _timerView.timerColor = [MainStyle lightBlueColor];
            break;
        case PinOrange:
            _timerView.timerColor = [MainStyle yellowColor];
            break;
        case PinGray:
            _timerView.timerColor = [UIColor clearColor];
            break;
        default:
            _timerView.timerColor = nil;
            break;
    }
}

-(void)updateBackForColor:(PinColor)color{
    switch (color) {
        case PinBlue:
            _back.image = [UIImage imageNamed:@"meetPinBlue.png"];
            break;
        case PinOrange:
            _back.image = [UIImage imageNamed:@"meetPinOrange.png"];
            break;
        case PinGray:
            _back.image = [UIImage imageNamed:@"meetPinGray.png"];
            break;
        default:
            NSLog(@"Color Error");
            break;
    }
}

-(void)setPinColor:(PinColor)color{
    [self updateBadgeForColor:color];
    [self updateBackForColor:color];
    [self updateTimerForColor:color];
}

-(void)setPinPrivacy:(PinPrivacy)privacy{
    switch (privacy) {
        case PinPrivate:
            _icon.image = [UIImage imageNamed:@"iconPrivate.png"];
            break;
        case PinPublic:
            _icon.image = [UIImage imageNamed:@"iconPublic.png"];
            break;
        default:
            NSLog(@"Privacy Error");
            break;
    }
}

-(void)setTime:(CGFloat)time{
    _timerView.time = time;
    if (_timerView.time == 0) {
        _timerView.time = 0.00001;
    }
    if (_timerView.time == 1) {
        _timerView.time = 0.99999;
    }
    [_timerView setNeedsDisplay];
}


-(void)setUnreaCount:(NSUInteger)count{
    [_badge setNumber:count];
}

-(void)prepareForAnnotation:(MeetupAnnotation*)ann{
    [self setPinColor:ann.pinColor];
    [self setPinPrivacy:ann.pinPrivacy];
    [self setTime:ann.time];
    [self setUnreaCount:ann.numUnreadCount];
    
}


@end


