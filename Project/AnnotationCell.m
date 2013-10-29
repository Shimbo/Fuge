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
#import "ULDeezerWrapper.h"

@implementation PersonAnnotationCell

-(void)prepareForAnnotation:(PersonAnnotation*)annotation{
    self.title.text = annotation.title;
    self.subtitle.text = annotation.subtitle;
    [_annotationPin prepareForAnnotation:annotation];
}


@end



@implementation MeetupAnnotationCell

-(void)prepareForAnnotation:(MeetupAnnotation*)annotation{
    
    [self initWithMeetup:annotation.meetup continuous:false];
    
    [_annotationPin prepareForAnnotation:annotation withPin:FALSE];
}

-(void)initWithMeetup:(FUGEvent*)meetup continuous:(Boolean)continuous
{
    _meetup = meetup;
    
    // Main stuff
    self.title.text = meetup.strSubject;
    if ( meetup.importedType == IMPORTED_SONGKICK )
        self.subtitle.text = [NSString stringWithFormat:@"At: %@", meetup.venueString];
    else
        self.subtitle.text = [NSString stringWithFormat:@"By: %@", meetup.strOwnerName];
    
    // Featuring
    NSString* featureString = meetup.featureString;
    self.featured.text = continuous ? @"" : featureString;
    self.featuredImage.hidden = ( featureString && ! continuous ) ? FALSE : TRUE;
    if ( featureString )
        self.backgroundColor = [UIColor colorWithHexString:INBOX_UNREAD_CELL_BG_COLOR];
    else
        self.backgroundColor = [UIColor whiteColor];
    
    // Date and distance
    static NSDateFormatter* formatter;
    if ( ! formatter )
    {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDoesRelativeDateFormatting:TRUE];
    }
    self.date.text = [formatter stringFromDate:meetup.dateTime];
    if ( meetup.strNotes )
        self.date.text = meetup.strNotes;
    self.distance.text = [meetup distanceString:TRUE];
    
    // Annotation
    static MeetupAnnotation* tempAnnotation;
    if ( ! tempAnnotation )
        tempAnnotation = [MeetupAnnotation alloc];
    tempAnnotation = [tempAnnotation initWithMeetup:meetup];
    [_annotationPin prepareForAnnotation:tempAnnotation withPin:FALSE];
    
    // Remove old persons (if cell was used before)
    if ( _avatarList )
        for ( AsyncImageView* person in _avatarList )
            [person removeFromSuperview];
    
    // Creating attending friends list
    _avatarList = [NSMutableArray arrayWithCapacity:10];
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
        AsyncImageView* image = [[AsyncImageView alloc] initWithFrame:CGRectMake(offset-_avatarList.count*(MINI_AVATAR_SIZE+1), 46, MINI_AVATAR_SIZE, MINI_AVATAR_SIZE)];
        [image loadImageFromURL:person.smallAvatarUrl];
        [_avatarList addObject:image];
        if ( continuous )
            image.alpha = 0.5f;
        [self addSubview:image];
    }
    
    // Continuous
    if ( continuous )
    {
        _annotationPin.alpha = 0.5f;
        self.title.alpha = 0.5f;
        self.subtitle.alpha = 0.5f;
        self.date.alpha = 0.5f;
        self.distance.alpha = 0.5f;
        self.attending.alpha = 0.5f;
        self.date.text = @"Event continues";
    }
    
    // Removing pin icon for musical events
    if ( meetup.importedType == IMPORTED_SONGKICK )
        _annotationPin.icon.hidden = TRUE;
    else
        _annotationPin.icon.hidden = FALSE;
}

- (void)previewTapped:(id)sender {
    if ( _meetup )
        if ( _meetup.strOwnerName )
        {
            // Mark grey if blue
            MeetupAnnotation* tempAnnotation = [[MeetupAnnotation alloc] initWithMeetup:_meetup];
            if (tempAnnotation.pinColor == PinBlue )
            {
                [_annotationPin setPinColor:PinGray withPin:FALSE];
                
                // Mark as read
                [globalData setEventRead:_meetup.strId withExpirationDate:_meetup.dateTimeExp];
            }
        }
}

@end



@implementation ThreadAnnotationCell

-(void)prepareForAnnotation:(ThreadAnnotation*)annotation{
    self.title.text = annotation.title;
    self.subtitle.text = annotation.subtitle;
    [_annotationPin prepareForAnnotation:annotation];
}


@end
