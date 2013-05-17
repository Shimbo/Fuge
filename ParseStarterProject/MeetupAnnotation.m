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

- (id)initWithMeetup:(Meetup*)meetup
{
    self = [super init];
    if (self) {
        
        switch ( meetup.privacy )
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
            
            // Don't trim name for Facebook events as organizers are not people
            NSString* strName = meetup.bFacebookEvent ? meetup.strOwnerName : [globalVariables trimName:meetup.strOwnerName];
            
            self.subtitle = [[NSString alloc] initWithFormat:@"By: %@ Attending: %d", strName, nAttendeesCount ];
        }
        else
            self.subtitle = [[NSString alloc] initWithFormat:@"By: %@ Comments: %d", [globalVariables trimName:meetup.strOwnerName], meetup.numComments ];
        self.strId = meetup.strId;
        
        CLLocationCoordinate2D coord;
        coord.latitude = meetup.location.latitude;
        coord.longitude = meetup.location.longitude;
        self.coordinate = coord;
        
        self.meetup = meetup;
        
        BOOL passed = [meetup hasPassed]; // grey?
        BOOL attorsubsc; // orange or just blue?
        if (!passed) {
            if ( meetup.meetupType == TYPE_MEETUP )
                attorsubsc = [globalData isAttendingMeetup:meetup.strId];
            else {
                attorsubsc = [globalData isSubscribedToThread:meetup.strId];
                
                // all read threads are passed as well
                if ( [globalData getConversationPresence:meetup.strId] )
                {
                    NSUInteger nComments = [globalData getConversationCount:meetup.strId];
                    if ( nComments == meetup.numComments )
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
        
        Boolean typeMeetup = (meetup.meetupType == TYPE_MEETUP); // meetup or thread
        if ( typeMeetup && ! passed ) // Show timer from 0 to 1 where 1 is max, 0 is min
        {
            self.time = [meetup getTimerTill];
        }
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
@end




@implementation ThreadAnnotation

@end