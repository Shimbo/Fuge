//
//  ThreadAnnotationView.m
//  SecondCircle
//
//  Created by Constantine Fry on 4/7/13.
//
//

#import "ThreadAnnotationView.h"
#import "MeetupAnnotation.h"
#import "MainStyle.h"
#import "CustomBadge.h"
#import <QuartzCore/QuartzCore.h>
@implementation ThreadAnnotationView

- (id) initWithAnnotation: (id <MKAnnotation>) annotation reuseIdentifier: (NSString *) reuseIdentifier
{
    self = [super initWithAnnotation: annotation reuseIdentifier: reuseIdentifier];
    if (self != nil)
    {
        self.frame = CGRectMake(0, 0, 80, 62);
        self.opaque = NO;
        _icon = [UIImage imageNamed:@"threadIcon.png"];
        
    }
    return self;
}

-(void)drawBadgeInContext:(CGContextRef)context{
    CGContextSaveGState(context);
    CGContextTranslateCTM(context,
                          _badge.frame.origin.x+_badge.frame.size.width/2.0,
                          _badge.frame.origin.y+_badge.frame.size.height/2.0);
    [_badge.layer renderInContext:context];
    CGContextRestoreGState(context);
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [_back drawInRect:CGRectMake(16, 5, _back.size.width, _back.size.height)];
    CGRect iconRect =CGRectMake(self.frame.size.width/2-_icon.size.width/2,
                                self.frame.size.height/2-_icon.size.height/2-3,
                                _icon.size.width, _icon.size.height);
    [_icon drawInRect:iconRect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawBadgeInContext:context];
    // Drawing code
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
    _badge.center = CGPointMake(8, 0);
}



-(void)updateBackForColor:(PinColor)color{
    switch (color) {
        case PinBlue:
            _back = [UIImage imageNamed:@"threadPinBlue.png"];
            break;
        case PinOrange:
            _back = [UIImage imageNamed:@"threadPinOrange.png"];
            break;
        case PinGray:
            _back = [UIImage imageNamed:@"threadPinGray.png"];
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

-(void)setUnreaCount:(NSUInteger)count{
    [_badge setNumber:count];
    //    [self setNeedsDisplay];
}

-(void)prepareForAnnotation:(ThreadAnnotation*)ann{
    [self setPinColor:ann.pinColor];
    [self setUnreaCount:ann.numUnreadCount];
    
}

@end
