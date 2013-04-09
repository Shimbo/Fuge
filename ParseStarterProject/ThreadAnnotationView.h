//
//  ThreadAnnotationView.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/7/13.
//
//

#import <MapKit/MapKit.h>
#import "SCAnnotationView.h"

@class ThreadAnnotation;
@class CustomBadge;
@interface ThreadAnnotationView : SCAnnotationView{
    CustomBadge *_badge;
    UIImageView *_back;
    UIImageView *_icon;
}

-(void)prepareForAnnotation:(ThreadAnnotation*)ann;
@end
