//
//  AsyncAnnotationView.m
//  SecondCircle
//
//  Created by Constantine Fry on 3/20/13.
//
//

#import "AsyncAnnotationView.h"
#import "ImageLoader.h"
#import "CustomBadge.h"
#import <QuartzCore/QuartzCore.h>
@implementation AsyncAnnotationView

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
        self.frame = CGRectMake(0, 0, 80, 60);
        self.opaque = NO;
        _badge = [CustomBadge secondCircleCustomBadge];
        [_badge setNumber:99];
        _badge.center = CGPointMake(-10, -10);
        _back = [UIImage imageNamed:@"pinPerson.png"];
        [self setNeedsDisplay];
    }
    return self;
}

//http://blog.sallarp.com/iphone-uiimage-round-corners/
//http://iosdevelopertips.com/cocoa/how-to-mask-an-image.html
static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

-(UIImage *)makeRoundCornerImage : (UIImage*) img
                            width: (int) cornerWidth
                           height: (int) cornerHeight
{
	UIImage * newImage = nil;
    
	if( nil != img)
	{

		int w = img.size.width;
		int h = img.size.height;
        
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
        
		CGContextBeginPath(context);
		CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
		addRoundedRectToPath(context, rect, cornerWidth, cornerHeight);
		CGContextClosePath(context);
		CGContextClip(context);
        
		CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
        
		CGImageRef imageMasked = CGBitmapContextCreateImage(context);
        
        
        
		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);

        
		newImage = [UIImage imageWithCGImage:imageMasked] ;
		CGImageRelease(imageMasked);
        

	}
    
    return newImage;
}

-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    [_back drawInRect:CGRectMake(15, 0, _back.size.width, _back.size.height)];
    [_personImage drawInRect:CGRectMake(22, 6.5, 36, 36)];
    [_badge drawRect:CGRectMake(15, 0, _badge.frame.size.width,
                                _badge.frame.size.height)];
}

-(void)loadImageWithURL:(NSString*)url{
    if (!_imageLoader) {
        _imageLoader = [[ImageLoader alloc]init];
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
            UIImage* roundedImage = [self makeRoundCornerImage:image
                                         width:image.size.width/2
                                        height:image.size.height/2];
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
