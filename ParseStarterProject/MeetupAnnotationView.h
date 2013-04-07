//
//  MeetupAnnotationView.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/6/13.
//
//

#import <MapKit/MapKit.h>
#import "MeetupAnnotation.h"


@class CustomBadge;
@interface MeetupAnnotationView : MKAnnotationView{
    CustomBadge *_badge;
    UIImage *_back;
    UIImage *_icon;
    UIColor *_timerColor;
    CGFloat _time;
}

/*
-(void)setPinColor:(PinColor)color;
-(void)setPinPrivacy:(PinPrivacy)privacy;
-(void)setTime:(CGFloat)time;
-(void)setUnreaCount:(NSUInteger)count;
*/


-(void)prepareForAnnotation:(MeetupAnnotation*)ann;
@end
