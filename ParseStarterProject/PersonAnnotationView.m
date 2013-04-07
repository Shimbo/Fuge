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
#import "UIImage+Circled.h"
#import <QuartzCore/QuartzCore.h>
#import "MainStyle.h"

@implementation PersonAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id) initWithAnnotation: (id <MKAnnotation>) annotation reuseIdentifier: (NSString *) reuseIdentifier
{
    self = [super initWithAnnotation: annotation reuseIdentifier: reuseIdentifier];
    if (self != nil)
    {
        self.frame = CGRectMake(0, 0, 80, 50);
        self.opaque = NO;
        _badge = [CustomBadge badgeWithWhiteTextAndBackground:[MainStyle orangeColor]];
        [_badge setNumber:99];
        _badge.center = CGPointMake(8, 0);
        _back = [UIImage imageNamed:@"pinPerson.png"];
        [self setNeedsDisplay];
    }
    return self;
}



-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    [_back drawInRect:CGRectMake(16, 2, _back.size.width, _back.size.height)];
    [_personImage drawInRect:CGRectMake(22.5, 8, 35, 35)];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextTranslateCTM(context,
                          _badge.frame.origin.x+_badge.frame.size.width/2.0,
                          _badge.frame.origin.y+_badge.frame.size.height/2.0);
    [_badge.layer renderInContext:context];
    CGContextRestoreGState(context);
}

-(void)loadImageWithURL:(NSString*)url{
    if (!_imageLoader) {
        _imageLoader = [[ImageLoader alloc]initForCircleImages];
    }
    [_imageLoader cancel];
    UIImage *im = [_imageLoader getImage:url];
    if (im) {
        _personImage = im;
        [self setNeedsDisplay];
        return;
    }
    _personImage = nil;
    [_imageLoader loadImageWithUrl:url handler:^(UIImage *image) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            UIImage* roundedImage = [UIImage appleMask:[UIImage imageNamed:@"mask35.png"]
                                              forImage:image];
            roundedImage = [UIImage imageWithCGImage:roundedImage.CGImage
                                               scale:2
                                         orientation:roundedImage.imageOrientation];
            [_imageLoader setImage:roundedImage url:url];
            _personImage = roundedImage;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setNeedsDisplay];
            });
        });
    }];
}

@end
