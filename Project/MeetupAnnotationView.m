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
#import "Person.h"
#import "ImageLoader.h"
#import "UIImage+Circled.h"
#import "TimerView.h"
#import "GlobalData.h"


@implementation MeetupPin

-(void)setup{
    _back = [[UIImageView alloc]init];
    [self addSubview:_back];
    
    _icon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"iconMtGeneric.png"]];
    _icon.center = CGPointMake(24, 24);
    [self addSubview:_icon];
    
    _personImage = [[UIImageView alloc]initWithFrame:CGRectMake(12.5, 12, 25, 25)];
    _personImage.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:_personImage];
    
    _timerView = [[TimerView alloc]init];
    [self addSubview:_timerView];
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
    if ( ! _badge )
    {
        _badge = [CustomBadge badgeWithWhiteBackgroundAndTextColor:badgeColor];
        _badge.center = CGPointMake(8, 8);
        [self addSubview:_badge];
    }
    else
    {
        _badge.badgeTextColor = badgeColor;
        _badge.badgeFrameColor = badgeColor;
    }
    //[_badge removeFromSuperview];
}


-(void)updateTimerForColor:(PinColor)color{
    switch (color) {
        case PinBlue:
            _timerView.timerColor = [UIColor FUGlightBlueColor];
            break;
        case PinOrange:
            _timerView.timerColor = [UIColor FUGyellowColor];
            break;
        case PinGray:
            _timerView.timerColor = [UIColor FUGlightGrayColor];
            break;
        default:
            _timerView.timerColor = nil;
            break;
    }
    [_timerView setNeedsDisplay];
}

-(void)updateBackForColor:(PinColor)color withPin:(BOOL)pinned{
    switch (color) {
        case PinBlue:
            if ( pinned )
                _back.image = [UIImage imageNamed:@"meetPinBlue.png"];
            else
                _back.image = [UIImage imageNamed:@"blue-comb.png"];
            break;
        case PinOrange:
            if ( pinned )
                _back.image = [UIImage imageNamed:@"meetPinOrange.png"];
            else
                _back.image = [UIImage imageNamed:@"orange-comb.png"];
            break;
        case PinGray:
            if ( pinned )
                _back.image = [UIImage imageNamed:@"meetPinGray.png"];
            else
                _back.image = [UIImage imageNamed:@"grey-comb.png"];
            break;
        default:
            _back.image = nil;
            break;
    }
    [_back sizeToFit];
}

-(void)setPinColor:(PinColor)color withPin:(BOOL)pinned{
    [self updateBadgeForColor:color];
    [self updateBackForColor:color withPin:pinned];
    [self updateTimerForColor:color];
}

-(void)setPinIcon:(FUGEvent*)meetup{
    if ( meetup.isCanceled )
        _icon.image = [UIImage imageNamed:@"iconCanceled.png"];
    else if ( meetup.privacy == MEETUP_PRIVATE )
        _icon.image = [UIImage imageNamed:@"iconPrivate.png"];
    else /*if ( meetup.importedEvent )
    {
        {
            switch ( meetup.importedType )
            {
            case IMPORTED_FACEBOOK: _icon.image = [UIImage imageNamed:@"iconFacebook.png"]; break;
            case IMPORTED_EVENTBRITE: _icon.image = [UIImage imageNamed:@"iconEventbrite.png"]; break;
            case IMPORTED_MEETUP: _icon.image = [UIImage imageNamed:@"iconMeetup.png"]; break;
            }
        }
    }
    else*/
    {
        NSUInteger icon = meetup.iconNumber;
        if ( icon >= meetupIcons.count )
            icon = 0;
        NSString* strName = meetupIcons[icon];
        _icon.image = [UIImage imageNamed:strName];
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


-(void)setUnreadCount:(NSUInteger)count{
    [_badge setNumber:count];
}

-(void)prepareForAnnotation:(MeetupAnnotation*)ann withPin:(BOOL)pinned{
    [self setPinColor:ann.pinColor withPin:pinned];
    [self setPinIcon:ann.meetup];
    [self setTime:ann.time];
    [self setUnreadCount:[globalData unreadConversationCount:ann.meetup]];
    if (ann.attendedPersons.count) {
        Person *p = ann.attendedPersons[0];
        [self loadImageWithURL:p.smallAvatarUrl];
    }else{
        _personImage.image = nil;
    }
    
}

-(void)loadImageWithURL:(NSString*)url{
    if (!url) {
        _personImage.image = nil;
        return;
    }
    if (!_imageLoader) {
        _imageLoader = [[ImageLoader alloc]init];
        _imageLoader.cachPolicy = CFAsyncCachePolicyDiskAndMemory;
        _imageLoader.loadPolicy = CFAsyncReturnCacheDataAndUpdateCachedImageOnce;
    }
    [_imageLoader cancel];
    UIImage *im = [_imageLoader getImage:url rounded:TRUE];
    if (im) {
        _personImage.image = im;
        return;
    }
    _personImage.image = nil;
    [_imageLoader loadImageWithUrl:url handler:^(UIImage *image) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            UIImage* roundedImage = [UIImage appleMask:[UIImage imageNamed:@"mask25.png"]
                                              forImage:image];
            [_imageLoader setImage:roundedImage url:url];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _personImage.image = roundedImage;
            });
        });
    }];
}

@end




@implementation MeetupAnnotationView

- (id) initWithAnnotation: (id <MKAnnotation>) annotation reuseIdentifier: (NSString *) reuseIdentifier
{
    self = [super initWithAnnotation: annotation reuseIdentifier: reuseIdentifier];
    if (self != nil)
    {
        self.frame = CGRectMake(0, 0, 49, 60);
        self.opaque = NO;
        self.centerOffset = CGPointMake(0, -22);
        _contentView = [[MeetupPin alloc]initWithFrame:self.bounds];
        [self addSubview:_contentView];

        
    }
    return self;
}

- (void)setAnnotation:(id<MKAnnotation>)annotation {
    [super setAnnotation:annotation];
    [_contentView prepareForAnnotation:annotation withPin:TRUE];
}


@end


