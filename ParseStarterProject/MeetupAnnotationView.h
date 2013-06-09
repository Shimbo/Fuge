//
//  MeetupAnnotationView.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/6/13.
//
//

#import <MapKit/MapKit.h>
#import "MeetupAnnotation.h"
#import "SCAnnotationView.h"

@class CustomBadge;
@class TimerView;
@class ImageLoader;

@interface MeetupPin : UIView{
    CustomBadge *_badge;
    UIImageView *_back;
    UIImageView *_icon;
    UIImageView *_personImage;
    TimerView *_timerView;
    ImageLoader *_imageLoader;
}
-(void)prepareForAnnotation:(MeetupAnnotation*)ann;

@end

@interface MeetupAnnotationView : SCAnnotationView{
    MeetupPin *_contentView;
}

@end
