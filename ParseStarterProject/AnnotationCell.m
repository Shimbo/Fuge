//
//  PersonAnnotationCell.m
//  SecondCircle
//
//  Created by Constantine Fry on 4/27/13.
//
//

#import "AnnotationCell.h"
#import "PersonAnnotationView.h"
#import "MeetupAnnotationView.h"
#import "ThreadAnnotationView.h"
#import "PersonAnnotation.h"

@implementation PersonAnnotationCell

-(void)prepareForAnnotation:(PersonAnnotation*)annotation{
    self.title.text = annotation.title;
    self.subtitle.text = annotation.subtitle;
    [self.annotation prepareForAnnotation:annotation];
}


@end



@implementation MeetupAnnotationCell

-(void)prepareForAnnotation:(MeetupAnnotation*)annotation{
    self.title.text = annotation.title;
    self.subtitle.text = annotation.subtitle;
    [self.annotation prepareForAnnotation:annotation];
}


@end



@implementation ThreadAnnotationCell

-(void)prepareForAnnotation:(ThreadAnnotation*)annotation{
    self.title.text = annotation.title;
    self.subtitle.text = annotation.subtitle;
    [self.annotation prepareForAnnotation:annotation];
}


@end
