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
#import "AsyncImageView.h"
#import "GlobalData.h"

@implementation PersonAnnotationCell

-(void)prepareForAnnotation:(PersonAnnotation*)annotation{
    self.title.text = annotation.title;
    self.subtitle.text = annotation.subtitle;
    [self.annotation prepareForAnnotation:annotation];
}


@end



@implementation MeetupAnnotationCell

-(void)prepareForAnnotation:(MeetupAnnotation*)annotation{
    
    [self initWithMeetup:annotation.meetup];
    
    [self.annotation prepareForAnnotation:annotation];
}

-(void)initWithMeetup:(Meetup*)meetup
{
    self.title.text = meetup.strSubject;
    self.subtitle.text = [NSString stringWithFormat:@"By: %@", meetup.strOwnerName];
    self.featured.text = meetup.strFeatured;
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDoesRelativeDateFormatting:TRUE];
    
    self.date.text = [formatter stringFromDate:meetup.dateTime];
    self.distance.text = [meetup distanceString:TRUE];
    
    MeetupAnnotation* tempAnnotation = [[MeetupAnnotation alloc] initWithMeetup:meetup];
    [self.annotation prepareForAnnotation:tempAnnotation];
    
    // Remove old persons (if cell was used before)
    if ( avatarList )
        for ( AsyncImageView* person in avatarList )
            [person removeFromSuperview];
    
    // Creating attending friends list
    avatarList = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray* personList = [NSMutableArray arrayWithCapacity:10];
    for ( NSString* strAttendee in meetup.attendees )
    {
        Person* person = [globalData getPersonById:strAttendee];
        if ( ! person || person.idCircle != CIRCLE_FB )
            continue;
        [personList addObject:person];
        if ( personList.count >= 5 )
            break;
    }
    
    // Attending text
    self.attending.hidden = FALSE;
    if ( personList.count > 0 )
    {
        if ( meetup.attendees.count-personList.count == 0 )
            self.attending.text = @"";
        else
            self.attending.text = [NSString stringWithFormat:@"+%d", meetup.attendees.count-personList.count];
    }
    else if ( meetup.attendees.count > 0 )
        self.attending.text = [NSString stringWithFormat:@"%d guests", meetup.attendees.count];
    else
        self.attending.hidden = TRUE;
    
    // Adding avatars
    NSUInteger offset = self.attending.text.length > 0 ? self.attending.originX + self.attending.width - [self.attending.text sizeWithFont:self.attending.font].width - 25 : self.frame.size.width-30;
    for ( Person* person in personList )
    {
        AsyncImageView* image = [[AsyncImageView alloc] initWithFrame:CGRectMake(offset-avatarList.count*22, 46, 20, 20)];
        [image loadImageFromURL:person.smallAvatarUrl];
        [avatarList addObject:image];
        [self addSubview:image];
    }
}

@end



@implementation ThreadAnnotationCell

-(void)prepareForAnnotation:(ThreadAnnotation*)annotation{
    self.title.text = annotation.title;
    self.subtitle.text = annotation.subtitle;
    [self.annotation prepareForAnnotation:annotation];
}


@end
