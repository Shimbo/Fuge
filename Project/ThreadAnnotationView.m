//
//  ThreadAnnotationView.m
//  SecondCircle
//
//  Created by Constantine Fry on 4/7/13.
//
//

#import "ThreadAnnotationView.h"
#import "MeetupAnnotation.h"
#import "CustomBadge.h"
#import "GlobalData.h"

@implementation ThreadPin

-(void)setup{
    _back = [[UIImageView alloc]initWithFrame:self.bounds];
    [self addSubview:_back];
    
    _icon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"iconThread.png"]];
    _icon.center = CGPointMake(23, 23);
    [self addSubview:_icon];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}

-(void)updateBadgeForColor:(PinColor)color{
    UIColor *badgeColor = nil;
    switch (color) {
        case PinBlue:
            badgeColor = [UIColor FUGblueColor];
            break;
        case PinOrange:
            badgeColor = [UIColor FUGorangeColor];
            break;
        case PinGray:
            badgeColor = [UIColor FUGgrayColor];
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
            im = nil;
            break;
    }
    _back.image = im;
}

-(void)setPinColor:(PinColor)color{
    [self updateBadgeForColor:color];
    [self updateBackForColor:color];
}

-(void)setPinIcon:(FUGEvent*)meetup{
    if ( meetup.privacy == MEETUP_PRIVATE )
        _icon.image = [UIImage imageNamed:@"iconPrivate.png"];
    else
        _icon.image = [UIImage imageNamed:@"iconThread.png"];
}

-(void)setUnreadCount:(NSUInteger)count{
    [_badge setNumber:count];
}

-(void)prepareForAnnotation:(ThreadAnnotation*)ann{
    [self setPinColor:ann.pinColor];
    [self setPinIcon:ann.meetup];
    [self setUnreadCount:[globalData unreadConversationCount:ann.meetup]];
}
@end

@implementation ThreadAnnotationView

- (id) initWithAnnotation: (id <MKAnnotation>) annotation reuseIdentifier: (NSString *) reuseIdentifier
{
    self = [super initWithAnnotation: annotation reuseIdentifier: reuseIdentifier];
    if (self != nil)
    {
        self.frame = CGRectMake(0, 0, 46, 58);
        self.opaque = NO;
        self.centerOffset = CGPointMake(0, -22);
        _contentView = [[ThreadPin alloc]initWithFrame:self.bounds];
        [self addSubview:_contentView];

    }
    return self;
}


- (void)setAnnotation:(id<MKAnnotation>)annotation {
    [super setAnnotation:annotation];
    [_contentView prepareForAnnotation:annotation];
}


@end
