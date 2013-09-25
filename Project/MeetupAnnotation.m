//
//  MeetupAnnotation.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "MeetupAnnotation.h"
#import "GlobalData.h"
#import "GlobalVariables.h"

@implementation MeetupAnnotation

@synthesize meetup;

- (void)configureAnnotation {
    switch ( self.meetup.privacy )
    {
        case MEETUP_PUBLIC:
            self.pinPrivacy = PinPublic;
            break;
            
        case MEETUP_PRIVATE:
            self.pinPrivacy = PinPrivate;
            break;
    }
    
    self.title = meetup.strSubject;
    if ( meetup.meetupType == TYPE_MEETUP )
    {
        // Check if we have any attendees
        NSUInteger nAttendeesCount = 0;
        if ( meetup.attendees )
            nAttendeesCount = meetup.attendees.count;
        
        // Don't trim name for imported events as organizers are not people
        NSString* strName = ( meetup.importedType != IMPORTED_NOT ) ? meetup.strOwnerName : [globalVariables trimName:meetup.strOwnerName];
        
        if ( self.attendedPersons.count )
            self.subtitle = [[NSString alloc] initWithFormat:@"By: %@ Attending: %d", strName, self.attendedPersons.count ];
        else
            self.subtitle = [[NSString alloc] initWithFormat:@"By: %@ Joined: %d", strName, nAttendeesCount ];
        //self.subtitle = [[NSString alloc] initWithFormat:@"Cass Business School, July 15, 10:30 PM", strName, nAttendeesCount ];
    }
    else
        self.subtitle = [[NSString alloc] initWithFormat:@"By: %@ Comments: %d", [globalVariables trimName:meetup.strOwnerName], meetup.commentsCount ];
    self.strId = meetup.strId;
    
    CLLocationCoordinate2D coord;
    coord.latitude = meetup.location.latitude;
    coord.longitude = meetup.location.longitude;
    self.coordinate = coord;
    
    BOOL passed = [meetup hasPassed];
    BOOL canceled = [meetup isCanceled];
    BOOL read = false;
    
    BOOL orange;
    if (!passed) {
        if ( self.meetup.meetupType == TYPE_MEETUP )
            orange = [globalData isAttendingMeetup:self.meetup.strId];
        else
            orange = [globalData isSubscribedToThread:self.meetup.strId];
        
        // Exported
        if ( self.meetup.importedEvent )
            orange = TRUE;
        
        // all read threads are passed as well
        if ( ! orange )
            if ( [currentPerson getConversationPresence:self.meetup.strId meetup:TRUE] )
                read = true;
    }
    
    if (passed || read || canceled)
        self.pinColor = PinGray;
    else if (orange)
        self.pinColor = PinOrange;
    else
        self.pinColor = PinBlue;
    
    Boolean typeMeetup = (self.meetup.meetupType == TYPE_MEETUP); // meetup or thread
    if ( typeMeetup && ! passed && ! canceled ) // Show timer from 0 to 1 where 1 is max, 0 is min
    {
        self.time = [self.meetup getTimerTill];
    }
}

- (id)initWithMeetup:(FUGEvent*)m
{
    self = [super init];
    if (self) {
        meetup = m;
        [self configureAnnotation];

    }
    return self;
}

/*-(NSUInteger)numUnreadCount{
    return self.meetup.getUnreadMessagesCount;
}*/

-(void)addPerson:(Person*)person{
    if (!self.attendedPersons) {
        self.attendedPersons = [NSMutableArray arrayWithCapacity:2];
    }
    
    // Changed priority from owner to user
//    if ([self.meetup.strOwnerId isEqualToString:person.strId]) {
    if ([strCurrentUserId isEqualToString:person.strId]) {
        if (self.attendedPersons.count) {
            [self.attendedPersons insertObject:person atIndex:0];
            return;
        }
    }
    
    [self.attendedPersons addObject:person];
}

-(NSUInteger)numAttendedPersons {
    return self.attendedPersons.count;
}

- (BOOL)canGroup{
    return CAN_GROUP_MEETUP;
}

@end




@implementation ThreadAnnotation

- (BOOL)canGroup{
    return CAN_GROUP_THREAD;
}

@end