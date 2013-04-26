//
//  SCAnnotationView.m
//  SecondCircle
//
//  Created by Constantine Fry on 4/9/13.
//
//

#import "SCAnnotationView.h"

#import "ThreadAnnotationView.h"
#import "MeetupAnnotationView.h"
#import "PersonAnnotationView.h"
#import "MeetupAnnotation.h"
#import "PersonAnnotation.h"

@implementation SCAnnotationView

+(SCAnnotationView*)constructAnnotationViewForAnnotation:(id)annotation
                                                  forMap:(MKMapView*)mapView{
    static NSString *personPin = @"person.pin";
    static NSString *threadPin = @"thread.pin";
    static NSString *meetupPin = @"meetup.pin";
    
    SCAnnotationView *pinView = nil;
    NSString *identifier = nil;
    BOOL isPerson = NO;
    BOOL isMeetup = NO;
    BOOL isThread = NO;
    if ([annotation isMemberOfClass:[PersonAnnotation class]]) {
        isPerson = YES;
        identifier = personPin;
    }else if([annotation isMemberOfClass:[MeetupAnnotation class]]){
        isMeetup = YES;
        identifier = meetupPin;
    }else if ([annotation isMemberOfClass:[ThreadAnnotation class]]){
        isThread = YES;
        identifier = threadPin;
    }
    pinView = (SCAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if ( pinView == nil ){
        if (isPerson) {
            pinView = (SCAnnotationView*)
            [[PersonAnnotationView alloc]initWithAnnotation:annotation
                                            reuseIdentifier:identifier];
        }else if(isMeetup){
            pinView = (SCAnnotationView*)
            [[MeetupAnnotationView alloc] initWithAnnotation:annotation
                                             reuseIdentifier:identifier];
        } else if (isThread){
            pinView = (SCAnnotationView*)
            [[ThreadAnnotationView alloc] initWithAnnotation:annotation
                                             reuseIdentifier:identifier];
        }
    }
    return pinView;
}

-(void)prepareForAnnotation:(id)ann{
}


@end
