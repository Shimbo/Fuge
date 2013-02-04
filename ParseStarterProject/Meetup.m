//
//  Meetup.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "Meetup.h"

@implementation Meetup

@synthesize strId,strOwnerId,strOwnerName,strSubject,dateTime,privacy,location,strVenue,meetupData;

-(id) init
{
    if (self = [super init]) {
        meetupData = nil;
    }
    
    return self;
}

- (void) save
{
    NSNumber* timestamp = [[NSNumber alloc] initWithDouble:[dateTime timeIntervalSince1970]];
    
    if ( ! meetupData )
    {
        meetupData = [[PFObject alloc] initWithClassName:@"Meetup"];
        
        // Id, fromStr, fromId
        NSString* strMeetupId = [[NSString alloc] initWithFormat:@"%d_%@", [timestamp integerValue], strOwnerId];
        [meetupData setObject:strMeetupId forKey:@"meetupId"];
        [meetupData setObject:strOwnerId forKey:@"userFromId"];
        [meetupData setObject:strOwnerName forKey:@"userFromName"];
        
        // Is read? TODO: it is p2a so it won't work at all
        [meetupData setObject:[NSNumber numberWithBool:FALSE] forKey:@"isRead"];
    }
    
    // Subject, privacy, date, timestamp, location
    [meetupData setObject:strSubject forKey:@"subject"];
    [meetupData setObject:[NSNumber numberWithInt:privacy] forKey:@"privacy"];
    [meetupData setObject:dateTime forKey:@"meetupDate"];
    [meetupData setObject:timestamp forKey:@"meetupTimestamp"];
    [meetupData setObject:location forKey:@"location"];
    [meetupData setObject:strVenue forKey:@"venue"];
    
    // Save
    [meetupData saveInBackground];
}

-(void) unpack:(PFObject*)data
{
    meetupData = data;
    
    strId = [meetupData objectForKey:@"meetupId"];
    strOwnerId = [meetupData objectForKey:@"userFromId"];
    strOwnerName = [meetupData objectForKey:@"userFromName"];
    strSubject = [meetupData objectForKey:@"subject"];
    privacy = [[meetupData objectForKey:@"privacy"] integerValue];
    dateTime = [meetupData objectForKey:@"meetupDate"];
    location = [meetupData objectForKey:@"location"];
    strVenue = [meetupData objectForKey:@"venue"];
}

@end
