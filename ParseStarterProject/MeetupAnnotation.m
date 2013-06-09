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
    
    self.title = self.meetup.strSubject;
    if ( self.meetup.meetupType == TYPE_MEETUP )
    {
        // Check if we have any attendees
        NSUInteger nAttendeesCount = 0;
        if ( self.meetup.attendees )
            nAttendeesCount = self.meetup.attendees.count;
        
        // Don't trim name for Facebook events as organizers are not people
        NSString* strName = self.meetup.bFacebookEvent ? self.meetup.strOwnerName : [globalVariables trimName:self.meetup.strOwnerName];
        
        self.subtitle = [[NSString alloc] initWithFormat:@"By: %@ Attending: %d", strName, nAttendeesCount ];
    }
    else
        self.subtitle = [[NSString alloc] initWithFormat:@"By: %@ Comments: %d", [globalVariables trimName:self.meetup.strOwnerName], self.meetup.numComments ];
    self.strId = self.meetup.strId;
    
    CLLocationCoordinate2D coord;
    coord.latitude = self.meetup.location.latitude;
    coord.longitude = self.meetup.location.longitude;
    self.coordinate = coord;
    
    
    
    BOOL passed = [self.meetup hasPassed]; // grey?
    BOOL attorsubsc; // orange or just blue?
    if (!passed) {
        if ( self.meetup.meetupType == TYPE_MEETUP )
            attorsubsc = [globalData isAttendingMeetup:self.meetup.strId];
        else {
            attorsubsc = [globalData isSubscribedToThread:self.meetup.strId];
            
            // all read threads are passed as well
            if ( [globalData getConversationPresence:self.meetup.strId] )
            {
                NSUInteger nComments = [globalData getConversationCount:self.meetup.strId];
                if ( nComments == self.meetup.numComments )
                    passed = true;
            }
        }
    }
    
    self.pinColor = PinBlue;
    if (passed) {
        self.pinColor = PinGray;
    }else if (attorsubsc){
        self.pinColor = PinOrange;
    }
    
    Boolean typeMeetup = (self.meetup.meetupType == TYPE_MEETUP); // meetup or thread
    if ( typeMeetup && ! passed ) // Show timer from 0 to 1 where 1 is max, 0 is min
    {
        self.time = [self.meetup getTimerTill];
    }
}

- (id)initWithMeetup:(Meetup*)meetup
{
    self = [super init];
    if (self) {
        self.meetup = meetup;
        [self configureAnnotation];

    }
    return self;
}

-(NSUInteger)numUnreadCount{
    return self.meetup.getUnreadMessagesCount;
}

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