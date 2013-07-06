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
    
    Meetup* meetup = annotation.meetup;
    
    self.title.text = meetup.strSubject;
    self.subtitle.text = [NSString stringWithFormat:@"By: %@", meetup.strOwnerName];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDoesRelativeDateFormatting:TRUE];
    
    self.date.text = [formatter stringFromDate:meetup.dateTime];
    if ( annotation.attendedPersons.count )
        self.attending.text = [NSString stringWithFormat:@"Attending: %d", annotation.attendedPersons.count];
    else
        self.attending.text = [NSString stringWithFormat:@"Joined: %d", annotation.meetup.attendees.count];
     
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
