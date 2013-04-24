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
        self.frame = CGRectMake(0, 0, 46, 58);
        self.opaque = NO;
        
        _back = [[UIImageView alloc]initWithFrame:self.bounds];
        [self addSubview:_back];
        
        _icon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"threadIcon.png"]];
        _icon.center = CGPointMake(23, 23);
        [self addSubview:_icon];
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
    [_badge removeFromSuperview];
    _badge = [CustomBadge badgeWithWhiteBackgroundAndTextColor:badgeColor];
    _badge.center = CGPointMake(6, 8);
    [self addSubview:_badge];
}



-(void)updateBackForColor:(PinColor)color{
    UIImage *im = nil;
    switch (color) {
        case PinBlue:
            im = [UIImage imageNamed:@"threadPinBlue.png"];
            break;
        case PinOrange:
            im = [UIImage imageNamed:@"threadPinOrange.png"];
            break;
        case PinGray:
            im = [UIImage imageNamed:@"threadPinGray.png"];
            break;
        default:
            NSLog(@"Color Error");
            break;
    }
    _back.image = im;
}

-(void)setPinColor:(PinColor)color{
    [self updateBadgeForColor:color];
    [self updateBackForColor:color];
}

-(void)setPinIcon:(Meetup*)meetup{
    if ( meetup.privacy == MEETUP_PRIVATE )
        _icon.image = [UIImage imageNamed:@"iconPrivate.png"];
    else
        _icon.image = [UIImage imageNamed:@"iconThread.png"];
}

-(void)setUnreaCount:(NSUInteger)count{
    [_badge setNumber:count];
}

-(void)prepareForAnnotation:(ThreadAnnotation*)ann{
    [self setPinColor:ann.pinColor];
    [self setPinIcon:ann.meetup];
    [self setUnreaCount:ann.numUnreadCount];
}

@end
