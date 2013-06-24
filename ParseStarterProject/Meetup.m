//
//  Meetup.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "Meetup.h"
#import "GlobalData.h"
#import "GlobalVariables.h"
#import "FSVenue.h"
#import "LocationManager.h"
#import "AppDelegate.h"
#import "PushManager.h"

@implementation Meetup

@synthesize strId,strOwnerId,strOwnerName,strSubject,strDescription,dateTime,privacy,meetupType,location,strVenue,strVenueId,strAddress,meetupData,numComments,attendees,decliners,dateTimeExp,durationSeconds,bImportedEvent,importedType,iconNumber;

-(id) init
{
    if (self = [super init]) {
        meetupType = TYPE_THREAD;
        meetupData = nil;
        attendees = nil;
        decliners = nil;
        numComments = 0;
        strAddress = @"";
        strVenueId = @"";
        bImportedEvent = false;
        iconNumber = 0;
    }
    
    return self;
}

-(id) initWithFbEvent:(NSDictionary*)data
{
    self = [self init];
    
    NSDictionary* eventData = [data objectForKey:@"event"];
    if ( ! eventData )
        return nil;
    NSDictionary* venueData = [data objectForKey:@"venue"];
    if ( ! venueData )
        return nil;
    
    bImportedEvent = true;
    importedType = IMPORTED_FACEBOOK;
    meetupType = TYPE_MEETUP;
    privacy = MEETUP_PUBLIC;
    
    strId = [ [NSString alloc] initWithFormat:@"fbmt_%@", [eventData objectForKey:@"eid"] ];
    strOwnerId = [eventData objectForKey:@"creator"];
    strOwnerName = [eventData objectForKey:@"host"];
    strSubject = [eventData objectForKey:@"name"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSString* strStartDate = [eventData objectForKey:@"start_time"];
    dateTime = [dateFormatter dateFromString:strStartDate];
    NSString* strEndDate = [eventData objectForKey:@"end_time"];
    NSDate* endDate = [dateFormatter dateFromString:strEndDate];
    durationSeconds = [endDate timeIntervalSince1970] - [dateTime timeIntervalSince1970];
    
    NSDictionary* venueLocation = [venueData objectForKey:@"location"];
    if ( [venueLocation objectForKey:@"latitude"] && [venueLocation objectForKey:@"longitude"])
    {
        double lat = [[venueLocation objectForKey:@"latitude"] doubleValue];
        double lon = [[venueLocation objectForKey:@"longitude"] doubleValue];
        location = [PFGeoPoint geoPointWithLatitude:lat longitude:lon];
    }
    strVenue = [venueLocation objectForKey:@"name"];
    if ( ! strVenue )
        strVenue = [venueData objectForKey:@"name"];
    strAddress = [venueLocation objectForKey:@"street"];
    
    dateTimeExp = endDate;
    
    return self;
}

-(id) initWithEbEvent:(NSDictionary*)eventData
{
    self = [self init];
    
    bImportedEvent = true;
    importedType = IMPORTED_EVENTBRITE;
    meetupType = TYPE_MEETUP;
    privacy = MEETUP_PUBLIC;
    
    strId = [ [NSString alloc] initWithFormat:@"ebmt_%@", [eventData objectForKey:@"id"]];
    strOwnerId = @"";

    NSDictionary* organizer = [eventData objectForKey:@"organizer"];
    if ( organizer )
    {
        if ( [organizer objectForKey:@"name"] )
            strOwnerName = [organizer objectForKey:@"name"];
    }
    else
        strOwnerName = @"Unknown";
    if ( [eventData objectForKey:@"title"] )
        strSubject = [eventData objectForKey:@"title"];
    else
        strSubject = @"Unknown";
    if ( [eventData objectForKey:@"description"] )
        strDescription = [eventData objectForKey:@"description"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString* strStartDate = [eventData objectForKey:@"start_date"];
    if ( ! strStartDate )
        return nil;
    dateTime = [dateFormatter dateFromString:strStartDate];
    if ( ! dateTime )
        return nil;
    NSString* strEndDate = [eventData objectForKey:@"end_date"];
    if ( ! strEndDate )
        return nil;
    NSDate* endDate = [dateFormatter dateFromString:strEndDate];
    if ( ! endDate )
        return nil;
    durationSeconds = [endDate timeIntervalSince1970] - [dateTime timeIntervalSince1970];
    if ( durationSeconds > 3600*24*3 )  // Exclude events more than tree days in duration
        return nil;
    dateTimeExp = endDate;
    
    NSDictionary* venue = [eventData objectForKey:@"venue"];
    if ( ! venue )
        return nil;
    if ( ! [venue objectForKey:@"Lat-Long"] )
        return nil;
    
    NSString* strLat = [venue objectForKey:@"latitude"];
    NSString* strLon = [venue objectForKey:@"longitude"];
    if ( ! strLat || ! strLon )
        return nil;
    
    double lat = [strLat doubleValue];
    double lon = [strLon doubleValue];
    location = [PFGeoPoint geoPointWithLatitude:lat longitude:lon];
    
    strVenue = [venue objectForKey:@"name"];
    if ( ! strVenue || ! [strVenue isKindOfClass:[NSString class]] )
        strVenue = [venue objectForKey:@"Lat-Long"];
    strAddress = [venue objectForKey:@"address"];
    
    return self;
}


- (Boolean) save
{
    // We're not changing or saving Facebook events nor creating our own as a copy
    if ( bImportedEvent )
        return true;
    
    NSNumber* timestamp = [[NSNumber alloc] initWithDouble:[dateTime timeIntervalSince1970]];
    
    // For the first save we can't do it in the background because following objects
    // could use objectId of this meetup. Saving in background will make these objects
    // to use wrong id as it creates on server.
    Boolean bFirstSave = false;
    
    if ( ! meetupData )
    {
        bFirstSave = true;
        meetupData = [PFObject objectWithClassName:@"Meetup"];
        
        // Id, fromStr, fromId
        [meetupData setObject:[NSNumber numberWithInt:meetupType] forKey:@"type"];
        strId = [[NSString alloc] initWithFormat:@"%d_%@", [timestamp integerValue], strOwnerId];
        [meetupData setObject:strId forKey:@"meetupId"];
        [meetupData setObject:strOwnerId forKey:@"userFromId"];
        [meetupData setObject:strOwnerName forKey:@"userFromName"];
        [meetupData setObject:pCurrentUser forKey:@"userFromData"];
    }
    
    // Subject, privacy, date, timestamp, location
    [meetupData setObject:strSubject forKey:@"subject"];
    [meetupData setObject:[NSNumber numberWithInt:privacy] forKey:@"privacy"];
    [meetupData setObject:dateTime forKey:@"meetupDate"];
    NSDate* dateToHide = [NSDate dateWithTimeInterval:durationSeconds sinceDate:dateTime];
    [meetupData setObject:dateToHide forKey:@"meetupDateExp"];
    [meetupData setObject:location forKey:@"location"];
    [meetupData setObject:strVenue forKey:@"venue"];
    [meetupData setObject:strVenueId forKey:@"venueId"];
    [meetupData setObject:strAddress forKey:@"address"];
    [meetupData setObject:[NSNumber numberWithInt:durationSeconds] forKey:@"duration"];
    [meetupData setObject:[NSNumber numberWithInt:iconNumber] forKey:@"icon"];
    
    // Save
    if ( bFirstSave )
    {
        NSError* error = [[NSError alloc] init];
        [meetupData save:&error];
        if ( error.code != 0 )
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"No internet" message:@"Save failed, check your connection and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            return false;
        }
        
        return true;
    }
    else
    {
        [meetupData saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error)
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"No internet" message:@"Be aware: the meetup or thread you recently edited wasn't saved due to lack of connection!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
        }];
        return true;
    }
}

-(void) unpack:(PFObject*)data
{
    meetupData = data;
    
    meetupType = [[meetupData objectForKey:@"type"] integerValue];
    strId = [meetupData objectForKey:@"meetupId"];
    strOwnerId = [meetupData objectForKey:@"userFromId"];
    strOwnerName = [meetupData objectForKey:@"userFromName"];
    strSubject = [meetupData objectForKey:@"subject"];
    privacy = [[meetupData objectForKey:@"privacy"] integerValue];
    dateTime = [meetupData objectForKey:@"meetupDate"];
    dateTimeExp = [meetupData objectForKey:@"meetupDateExp"];
    location = [meetupData objectForKey:@"location"];
    strVenue = [meetupData objectForKey:@"venue"];
    strVenueId = [meetupData objectForKey:@"venueId"];
    strAddress = [meetupData objectForKey:@"address"];
    numComments = [[meetupData objectForKey:@"numComments"] integerValue];
    attendees = [meetupData objectForKey:@"attendees"];
    decliners = [meetupData objectForKey:@"decliners"];
    durationSeconds = [[meetupData objectForKey:@"duration"] integerValue];
    iconNumber = [[meetupData objectForKey:@"icon"] integerValue];
}

-(NSUInteger)getUnreadMessagesCount
{
    if ( bImportedEvent )
        return 0;
    NSUInteger nOldCount = [globalData getConversationCount:strId];
    return numComments - nOldCount;
}

-(Boolean)hasPassed
{
    NSDate* currentTime = [NSDate date];
    NSDate* meetupEnd = [dateTime dateByAddingTimeInterval:durationSeconds];
    return [currentTime compare:meetupEnd] == NSOrderedDescending;
}

-(float)getTimerTill
{
    NSTimeInterval meetupInterval = [dateTime timeIntervalSinceNow];
    
    if ( meetupInterval < 3600*12 && meetupInterval > - (float) durationSeconds )
    {
        float fTimer = 1.0 - ( (float) ( meetupInterval ) ) / (3600.0f*12.0f);
        if ( fTimer > 1.0 )
            fTimer = 1.0f;
        if ( fTimer < 0.0 )
            fTimer = 0.0f;
        
        return fTimer;
    }
    
    return 0.0f;
}

- (void)presentEventEditViewControllerWithEventStore:(EKEventStore*)eventStore
{
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    event.title     = [strSubject stringByAppendingFormat:@" at %@", strVenue];
    event.startDate = dateTime;
    event.endDate   = [[NSDate alloc] initWithTimeInterval:durationSeconds sinceDate:event.startDate];
    event.location = strAddress;
    
    EKEventEditViewController* eventView = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
    [eventView setEventStore:eventStore];
    [eventView setEvent:event];
    
    ParseStarterProjectAppDelegate *delegate = AppDelegate;
    UIViewController* controller = delegate.revealController;
    
    [controller presentViewController:eventView animated:YES completion:nil];
    
    eventView.editViewDelegate = self;
}

#pragma mark -
#pragma mark EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions.
- (void)eventEditViewController:(EKEventEditViewController *)controller
          didCompleteWithAction:(EKEventEditViewAction)action {
    
    NSError *error = nil;
    EKEvent *thisEvent = controller.event;
    
    switch (action) {
        case EKEventEditViewActionCanceled:
            break;
            
        case EKEventEditViewActionSaved:
            [controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
            break;
            
        case EKEventEditViewActionDeleted:
            [controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
            break;
            
        default:
            break;
    }
    // Dismiss the modal view controller
    [controller dismissViewControllerAnimated:YES
                                   completion:nil];
}


// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
/*- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller {
 //EKCalendar *calendarForEdit = self.defaultCalendar;
 return calendarForEdit;
 }*/

- (void) addToCalendarInternal
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    // iOS 6 introduced a requirement where the app must
    // explicitly request access to the user's calendar. This
    // function is built to support the new iOS 6 requirement,
    // as well as earlier versions of the OS.
    if([eventStore respondsToSelector:
        @selector(requestAccessToEntityType:completion:)]) {
        // iOS 6 and later
        [eventStore
         requestAccessToEntityType:EKEntityTypeEvent
         completion:^(BOOL granted, NSError *error) {
             // If you don't perform your presentation logic on the
             // main thread, the app hangs for 10 - 15 seconds.
             [self performSelectorOnMainThread:
              @selector(presentEventEditViewControllerWithEventStore:)
                                    withObject:eventStore
                                 waitUntilDone:NO];
         }];
    } else {
        // iOS 5
        [self presentEventEditViewControllerWithEventStore:eventStore];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // No
    if ( buttonIndex == 2 )
        return;
    
    // Always
    if ( buttonIndex == 0 )
        [globalVariables setToAlwaysAddToCalendar];
    
    // Yes
    [self addToCalendarInternal];
}

-(void) addToCalendar
{
    // Already added
    if ( [self addedToCalendar] )
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Calendar" message:@"This meetup is already added to your calendar." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
        [message show];
        return;
    }
    
    // Ask yes/no/always question
    if ( ! [globalVariables shouldAlwaysAddToCalendar] )
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Calendar" message:@"Would you like to add this event to your calendar?" delegate:self cancelButtonTitle:@"Always" otherButtonTitles:@"Yes",@"No",nil];
        [message show];
    }
    else
        [self addToCalendarInternal];
}

-(Boolean) addedToCalendar
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    NSDate* dateEnd = [[NSDate alloc] initWithTimeInterval:durationSeconds sinceDate:dateTime];
    NSPredicate *predicateForEvents = [eventStore predicateForEventsWithStartDate:dateTime endDate:dateEnd calendars:nil];
    
    NSArray *eventsFound = [eventStore eventsMatchingPredicate:predicateForEvents];
    
    for (EKEvent *eventToCheck in eventsFound)
    {
        if ([eventToCheck.location isEqualToString:strAddress])
            if ( [eventToCheck.title isEqualToString:[strSubject stringByAppendingFormat:@" at %@", strVenue]])
            return true;
    }
    
    return false;
}

-(void)populateWithVenue:(FSVenue*)venue{
    if ( venue )
    {
        self.location = [PFGeoPoint geoPointWithLatitude:[venue.lat doubleValue]
                                                 longitude:[venue.lon doubleValue]];
        self.strVenue = venue.name;
        self.strVenueId = venue.venueId;
        if ( venue.address )
            self.strAddress = venue.address;
        if ( venue.city )
        {
            self.strAddress = [self.strAddress stringByAppendingString:@" "];
            self.strAddress = [self.strAddress stringByAppendingString:venue.city];
        }
        if ( venue.state )
        {
            self.strAddress = [self.strAddress stringByAppendingString:@" "];
            self.strAddress = [self.strAddress stringByAppendingString:venue.state];
        }
        if ( venue.postalCode )
        {
            self.strAddress = [self.strAddress stringByAppendingString:@" "];
            self.strAddress = [self.strAddress stringByAppendingString:venue.postalCode];
        }
        if ( venue.country )
        {
            self.strAddress = [self.strAddress stringByAppendingString:@" "];
            self.strAddress = [self.strAddress stringByAppendingString:venue.country];
        }
    }
}

-(void)populateWithCoords{
    PFGeoPoint* ptLocation = [locManager getPosition];
    if ( ! ptLocation )
        return;
    self.location = ptLocation;
    self.strVenue = [[NSString alloc] initWithFormat:@"Lat: %.3f, lon: %.3f", ptLocation.latitude, ptLocation.longitude];
}

-(void)addAttendee:(NSString*)str
{
    if ( ! attendees )
        attendees = [[NSMutableArray alloc] initWithObjects:strId,nil];
    else
        [attendees addObject:str];
}

-(void)removeAttendee:(NSString*)str
{
    if ( attendees )
        [attendees removeObjectIdenticalTo:str];
}

-(Boolean) passed
{
    return [dateTime compare:[NSDate dateWithTimeIntervalSinceNow:
                              -(NSTimeInterval)durationSeconds]] == NSOrderedAscending;
}

@end
