//
//  AsyncAnnotationView.m
//  SecondCircle
//
//  Created by Constantine Fry on 3/20/13.
//
//

#import "AsyncAnnotationView.h"
#import "ImageLoader.h"

@implementation AsyncAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


-(void)loadImageWithURL:(NSString*)url{
    if (!_imageLoader) {
        _imageLoader = [[ImageLoader alloc]init];
    }
    [_imageLoader cancel];
    UIImage *im = [_imageLoader getImage:url];
    if (im) {
        self.image = im;
        return;
    }
    self.image = nil;
    [_imageLoader loadImageWithUrl:url handler:^(UIImage *image) {
        image = [UIImage imageWithCGImage:image.CGImage
                                    scale:2
                              orientation:image.imageOrientation];
        [_imageLoader setImage:image url:url];
        self.image = image;
    }];
}

@end
