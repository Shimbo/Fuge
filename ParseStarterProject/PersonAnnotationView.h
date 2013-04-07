//
//  AsyncAnnotationView.h
//  SecondCircle
//
//  Created by Constantine Fry on 3/20/13.
//
//

#import <MapKit/MapKit.h>
@class ImageLoader;
@class CustomBadge;
@interface PersonAnnotationView : MKAnnotationView{
    ImageLoader *_imageLoader;
    CustomBadge *_badge;
    UIImage *_back;
    UIImage *_personImage;
}

-(void)loadImageWithURL:(NSString*)url;
@end
