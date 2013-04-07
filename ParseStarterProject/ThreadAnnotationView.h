//
//  ThreadAnnotationView.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/7/13.
//
//

#import <MapKit/MapKit.h>

@class ThreadAnnotation;
@class CustomBadge;
@interface ThreadAnnotationView : MKAnnotationView{
    CustomBadge *_badge;
    UIImage *_back;
    UIImage *_icon;
}

-(void)prepareForAnnotation:(ThreadAnnotation*)ann;
@end
