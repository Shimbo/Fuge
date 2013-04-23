//
//  MeetupAnnotation.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "MeetupAnnotation.h"
#import "GlobalData.h"
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
        self.subtitle = [[NSString alloc] initWithFormat:@"Organizer: %@", meetup.strOwnerName ];
        self.strId = meetup.strId;
        
        CLLocationCoordinate2D coord;
        coord.latitude = meetup.location.latitude;
        coord.longitude = meetup.location.longitude;
        self.coordinate = coord;
        
        self.meetup = meetup;
        
        // Useful!!!
        BOOL passed = [meetup hasPassed]; // grey?
        BOOL attorsubsc; // orange or just blue?
        if (!passed) {
            if ( meetup.meetupType == TYPE_MEETUP )
                attorsubsc = [globalData isAttendingMeetup:meetup.strId];
            else
                attorsubsc = [globalData isSubscribedToThread:meetup.strId];
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