//
//  AsyncAnnotationView.h
//  SecondCircle
//
//  Created by Constantine Fry on 3/20/13.
//
//

#import <MapKit/MapKit.h>
#import "SCAnnotationView.h"

@class PersonAnnotation;
@class ImageLoader;
@class CustomBadge;

@interface PersonPin : UIView{
    ImageLoader *_imageLoader;
    CustomBadge *_badge;
    UIImageView *_back;
    UIImageView *_personImage;
}

-(void)loadImageWithURL:(NSString*)url;
-(void)prepareForAnnotation:(PersonAnnotation*)annotation;
- (void)prepareForReuse;
@end


@interface PersonAnnotationView : SCAnnotationView{
    PersonPin *_contentView;
}

-(void)prepareForAnnotation:(PersonAnnotation*)annotation;
@end
