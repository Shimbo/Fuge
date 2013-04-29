//
//  AsyncAnnotationView.m
//  SecondCircle
//
//  Created by Constantine Fry on 3/20/13.
//
//

#import "PersonAnnotationView.h"
#import "ImageLoader.h"
#import "CustomBadge.h"
#import <QuartzCore/QuartzCore.h>
#import "MainStyle.h"
#import "PersonAnnotation.h"

@implementation PersonPin

-(void)setup{
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    _back = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"pinPerson.png"]];
    [self addSubview:_back];
    
    _personImage = [[UIImageView alloc]initWithFrame:CGRectMake(6.5, 6.5, 35, 35)];
    [self addSubview:_personImage];
    
    _badge = [CustomBadge badgeWithWhiteTextAndBackground:[MainStyle orangeColor]];
    _badge.center = CGPointMake(6, 6);
    [self addSubview:_badge];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}

-(void)prepareForAnnotation:(PersonAnnotation*)annotation{
    [self loadImageWithURL:annotation.imageURL];
    [_badge setNumber:annotation.numUnreadCount];
}


-(void)loadImageWithURL:(NSString*)url{
    if (!_imageLoader) {
        _imageLoader = [[ImageLoader alloc]initForCircleImages];
    }
    [_imageLoader cancel];
    UIImage *im = [_imageLoader getImage:url];
    if (im) {
        _personImage.image = im;
        return;
    }
    _personImage.image = nil;
    [_imageLoader loadImageWithUrl:url handler:^(UIImage *image) {
        _personImage.image = image;
    }];
}


@end







@implementation PersonAnnotationView
- (id) initWithAnnotation: (id <MKAnnotation>) annotation reuseIdentifier: (NSString *) reuseIdentifier
{
    self = [super initWithAnnotation: annotation reuseIdentifier: reuseIdentifier];
    if (self != nil){
        self.calloutOffset = CGPointMake(0, 0);
        self.frame = CGRectMake(0, 0, 48, 48);
        _contentView = [[PersonPin alloc]initWithFrame:self.bounds];
        [self addSubview:_contentView];
    }
    return self;
}
-(void)loadImageWithURL:(NSString*)url{
    [_contentView loadImageWithURL:url];
}
-(void)prepareForAnnotation:(PersonAnnotation*)annotation{
    [_contentView prepareForAnnotation:annotation];
}


@end
