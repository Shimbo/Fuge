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
    
    [self initWithMeetup:annotation.meetup continuous:false];
    
    [self.annotation prepareForAnnotation:annotation];
}

-(void)initWithMeetup:(FUGEvent*)meetup continuous:(Boolean)continuous
{
    self.title.text = meetup.strSubject;
    self.subtitle.text = [NSString stringWithFormat:@"By: %@", meetup.strOwnerName];
    
    self.featured.text = continuous ? @"" : meetup.featureString;
    self.featuredImage.hidden = ( meetup.featureString && ! continuous ) ? FALSE : TRUE;
    
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
        if ( personList.count >= MINI_AVATAR_COUNT_CELL )
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
    NSUInteger offset = self.attending.text.length > 0 ? self.attending.originX + self.attending.width - [self.attending.text sizeWithFont:self.attending.font].width - MINI_AVATAR_SIZE - 3 : self.attending.originX + self.attending.width - MINI_AVATAR_SIZE;
    for ( Person* person in personList )
    {
        AsyncImageView* image = [[AsyncImageView alloc] initWithFrame:CGRectMake(offset-avatarList.count*(MINI_AVATAR_SIZE+1), 46, MINI_AVATAR_SIZE, MINI_AVATAR_SIZE)];
        [image loadImageFromURL:person.smallAvatarUrl];
        [avatarList addObject:image];
        if ( continuous )
            image.alpha = 0.5f;
        [self addSubview:image];
    }
    
    // Continuous
    if ( continuous )
    {
        self.annotation.alpha = 0.5f;
        self.title.alpha = 0.5f;
        self.subtitle.alpha = 0.5f;
        self.date.alpha = 0.5f;
        self.distance.alpha = 0.5f;
        self.attending.alpha = 0.5f;
        self.date.text = @"Event continues";
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
