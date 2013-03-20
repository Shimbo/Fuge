//
//  AsyncAnnotationView.h
//  SecondCircle
//
//  Created by Constantine Fry on 3/20/13.
//
//

#import <MapKit/MapKit.h>
@class ImageLoader;
@interface AsyncAnnotationView : MKAnnotationView{
    ImageLoader *_imageLoader;
}

-(void)loadImageWithURL:(NSString*)url;
@end
