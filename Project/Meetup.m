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

@synthesize strId,strOwnerId,strOwnerName,strSubject,strDescription,dateTime,privacy,meetupType,strVenue,strVenueId,strAddress,meetupData,numComments,attendees,decliners,dateTimeExp,durationSeconds,bImportedEvent,importedType,iconNumber,strPrice,strImageURL,strOriginalURL,strFeatured,maxGuests,strGroupId;

-(id) init
{
    if (self = [super init]) {
        meetupType = TYPE_MEETUP;
        meetupData = nil;
        attendees = nil;
        decliners = nil;
        numComments = 0;
        strId = nil;
        strAddress = @"";
        strVenueId = @"";
        bImportedEvent = FALSE;
        iconNumber = 0;
        isCanceled = FALSE;
        importedType = IMPORTED_NOT;
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
    
    strId = [NSString stringWithFormat:@"fbmt_%@", [eventData objectForKey:@"eid"]];
    strOwnerId = [eventData objectForKey:@"creator"];
    strOwnerName = [eventData objectForKey:@"host"];
    strSubject = [eventData objectForKey:@"name"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSString* strStartDate = [eventData objectForKey:@"start_time"];
    if ( ! strStartDate || ! [strStartDate isKindOfClass:[NSString class]] )
        return nil;
    dateTime = [dateFormatter dateFromString:strStartDate];
    NSString* strEndDate = [eventData objectForKey:@"end_time"];
    if ( strEndDate && [strEndDate isKindOfClass:[NSString class]] )
    {
        NSDate* endDate = [dateFormatter dateFromString:strEndDate];
        durationSeconds = [endDate timeIntervalSince1970] - [dateTime timeIntervalSince1970];
        dateTimeExp = endDate;
    }
    else
    {
        durationSeconds = 3600;
        dateTimeExp = [dateTime dateByAddingTimeInterval:durationSeconds];
    }
    
    NSDictionary* venueLocation = [venueData objectForKey:@"location"];
    if ( ! [venueLocation objectForKey:@"latitude"] || ! [venueLocation objectForKey:@"longitude"])
        return nil;
    double lat = [[venueLocation objectForKey:@"latitude"] doubleValue];
    double lon = [[venueLocation objectForKey:@"longitude"] doubleValue];
    location = [PFGeoPoint geoPointWithLatitude:lat longitude:lon];
    strVenue = [venueLocation objectForKey:@"name"];
    if ( ! strVenue )
        strVenue = [venueData objectForKey:@"name"];
    strAddress = [venueLocation objectForKey:@"street"];
    
    attendees = [NSMutableArray arrayWithObject:strCurrentUserId];
    
    return self;
}

-(id) initWithEbEvent:(NSDictionary*)data
{
    self = [self init];
    
    bImportedEvent = false;
    importedType = IMPORTED_EVENTBRITE;
    meetupType = TYPE_MEETUP;
    privacy = MEETUP_PUBLIC;
    
    strId = [ [NSString alloc] initWithFormat:@"ebmt_%@", [data objectForKey:@"id"]];
    strOwnerId = @"";

    NSDictionary* organizer = [data objectForKey:@"organizer"];
    if ( organizer )
    {
        if ( [organizer objectForKey:@"name"] )
            strOwnerName = [organizer objectForKey:@"name"];
    }
    else
        strOwnerName = @"Unknown";
    if ( ! [data objectForKey:@"title"] || ! [[data objectForKey:@"title"] isKindOfClass:[NSString class]] )
        return nil;
    strSubject = [[data objectForKey:@"title"] capitalizedString];
    if ( [data objectForKey:@"description"] )
        strDescription = [data objectForKey:@"description"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString* strStartDate = [data objectForKey:@"start_date"];
    if ( ! strStartDate || ! [strStartDate isKindOfClass:[NSString class]] )
        return nil;
    dateTime = [dateFormatter dateFromString:strStartDate];
    if ( ! dateTime )
        return nil;
    NSString* strEndDate = [data objectForKey:@"end_date"];
    if ( ! strEndDate )
        return nil;
    NSDate* endDate = [dateFormatter dateFromString:strEndDate];
    if ( ! endDate )
        return nil;
    // CHANGE THIS if you'd like to load old events!
    if ( [endDate compare:[NSDate date]] == NSOrderedAscending )
        return nil;
    durationSeconds = [endDate timeIntervalSince1970] - [dateTime timeIntervalSince1970];
    if ( durationSeconds > 3600*24*3 )  // Exclude events more than tree days in duration
        return nil;
    dateTimeExp = endDate;
    
    NSDictionary* venue = [data objectForKey:@"venue"];
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
    
    NSDictionary* ticketsDict = [data objectForKey:@"tickets"];
    NSArray* tickets = [ticketsDict objectForKey:@"ticket"];
    if ( [tickets isKindOfClass:[NSDictionary class]] ) // Evenbrite, my ass...
        tickets = [NSArray arrayWithObject:tickets];
    NSNumber *minPrice = nil, *maxPrice = nil;
    NSString* strCurrency = nil;
    Boolean atLeastOneTicketAvailable = false;
    for ( NSDictionary* ticket in tickets )
    {
        strEndDate = [ticket objectForKey:@"end_date"];
        if ( strEndDate && [strEndDate isKindOfClass:[NSString class]] )
        {
            endDate = [dateFormatter dateFromString:strEndDate];
            if ( [endDate compare:[NSDate date]] == NSOrderedDescending )
                atLeastOneTicketAvailable = true;
        }
        
        NSNumber* price = [ticket objectForKey:@"price"];
        
        if ( ! price )
            continue;
        
        if ( ! minPrice || [price floatValue] < [minPrice floatValue] )
            minPrice = price;
        
        if ( ! maxPrice || [price floatValue] > [maxPrice floatValue] )
            maxPrice = price;
        
        strCurrency = [ticket objectForKey:@"currency"];
    }
    if ( minPrice && maxPrice && [minPrice floatValue] != [maxPrice floatValue] )
        strPrice = [NSString stringWithFormat:@"%.2f to %.2f %@", [minPrice floatValue], [maxPrice floatValue], strCurrency ? strCurrency : @""];
    else if ( minPrice && [minPrice floatValue] == 0.0f )
        strPrice = nil;
    else if ( minPrice )
        strPrice = [NSString stringWithFormat:@"%.2f %@", [minPrice floatValue], strCurrency ? strCurrency : @""];
    
    if ( ! atLeastOneTicketAvailable )
        maxGuests = [NSNumber numberWithInteger:0];
    
    strOriginalURL = [data objectForKey:@"url"];
    
    return self;
}

-(id) initWithMtEvent:(NSDictionary*)data
{
    self = [self init];
    
    importedType = IMPORTED_MEETUP;
    meetupType = TYPE_MEETUP;
    privacy = MEETUP_PUBLIC;
    
    strId = [ [NSString alloc] initWithFormat:@"mtmt_%@", [data objectForKey:@"id"]];
    strOwnerId = strCurrentUserId;
    
    NSDictionary* organizer = [data objectForKey:@"group"];
    if ( organizer )
    {
        if ( [organizer objectForKey:@"name"] )
            strOwnerName = [organizer objectForKey:@"name"];
    }
    else
        strOwnerName = @"Unknown";
    if ( [data objectForKey:@"name"] )
        strSubject = [data objectForKey:@"name"];
    else
        strSubject = @"Unknown";
    
    // Description and how-to-find
    NSMutableString* description = nil;
    NSUInteger nYesRSVPs = 0;
    if ( [data objectForKey:@"yes_rsvp_count"] )
        nYesRSVPs = [[data objectForKey:@"yes_rsvp_count"] integerValue];
    if ( [data objectForKey:@"rsvp_limit"] )
        maxGuests = [NSNumber numberWithInteger:[[data objectForKey:@"rsvp_limit"] integerValue] - nYesRSVPs];
    if ( [data objectForKey:@"description"] )
    {
        description = [data objectForKey:@"description"];
        if ( nYesRSVPs > 0 )
            [description insertString:[NSString stringWithFormat:@"Meetup.com attendees: %d<BR>", nYesRSVPs] atIndex:0];
        if ( [data objectForKey:@"how_to_find_us"] )
            [description insertString:[NSString stringWithFormat:@"How to find: %@<BR>", [data objectForKey:@"how_to_find_us"]] atIndex:0];
    }
    strDescription = description;
    
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString* strStartDate = [data objectForKey:@"time"];
    if ( ! strStartDate )
        return nil;
    NSTimeInterval timeInterval = [strStartDate longLongValue];
    timeInterval /= 1000;
    dateTime = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    if ( ! dateTime )
        return nil;
    
    NSString* strDuration = [data objectForKey:@"duration"];
    if ( strDuration )
    {
        durationSeconds = [strDuration integerValue] / 1000;
        if ( durationSeconds > 3600*24*3 )  // Exclude events more than tree days in duration
            return nil;
    }
    else
        durationSeconds = 3600*3;
    dateTimeExp = [dateTime dateByAddingTimeInterval:durationSeconds];
    
    NSDictionary* venue = [data objectForKey:@"venue"];
    if ( ! venue )
        return nil;
    
    NSString* strLat = [venue objectForKey:@"lat"];
    NSString* strLon = [venue objectForKey:@"lon"];
    if ( ! strLat || ! strLon )
        return nil;
    
    double lat = [strLat doubleValue];
    double lon = [strLon doubleValue];
    location = [PFGeoPoint geoPointWithLatitude:lat longitude:lon];
    
    strVenue = [venue objectForKey:@"name"];
    if ( ! strVenue || ! [strVenue isKindOfClass:[NSString class]] )
        strVenue = [NSString stringWithFormat:@"%f : %f", lat, lon];
    if ( [venue objectForKey:@"address_1"] )
    {
        NSMutableString* address = [venue objectForKey:@"address_1"];
        if ( [venue objectForKey:@"city"] )
        {
            [address appendString:@", "];
            [address appendString:[venue objectForKey:@"city"]];
        }
        if ( [venue objectForKey:@"address_2"] )
        {
            [address appendString:@", "];
            [address appendString:[venue objectForKey:@"address_2"]];
        }
        strAddress = address;
    }
    
    NSDictionary* feeInfo = [data objectForKey:@"fee"];
    if ( feeInfo )
    {
        NSMutableString* price = [feeInfo objectForKey:@"amount"];
        if ( [feeInfo objectForKey:@"currency"] )
        {
            [price appendString:@" "];
            [price appendString:[feeInfo objectForKey:@"currency"]];
        }
        strPrice = price;
    }
    
    strOriginalURL = [data objectForKey:@"event_url"];
    
    return self;
}

- (Boolean) feature:(NSString*)feature
{
    strFeatured = feature;
    if ( feature && feature.length > 0 )
    {
        [meetupData setObject:strFeatured forKey:@"featured"];
        [meetupData setObject:pCurrentUser forKey:@"featuredBy"];
    }
    else
    {
        [meetupData removeObjectForKey:@"featured"];
        [meetupData removeObjectForKey:@"featuredBy"];
    }
    NSError* error = [[NSError alloc] init];
    [meetupData save:&error];
    if ( error.code != 0 )
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"No internet" message:[NSString stringWithFormat:@"Featuring failed, error: %@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return FALSE;
    }
    return TRUE;
}

- (Boolean) save:(id)target selector:(SEL)selector
{
    // We're not changing or saving Facebook events nor creating our own as a copy
    //if ( bImportedEvent )
    //    return true;
    // UPDATE: but we are saving these meetups as admins!
    
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
        if ( ! strId )
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
    
    if ( isCanceled )
        [meetupData setObject:[NSNumber numberWithBool:TRUE] forKey:@"canceled"];
    if ( strDescription )
        [meetupData setObject:strDescription forKey:@"description"];
    else
        [meetupData removeObjectForKey:@"description"];
    if ( strPrice)
        [meetupData setObject:strPrice forKey:@"price"];
    else
        [meetupData removeObjectForKey:@"price"];
    if ( maxGuests )
        [meetupData setObject:maxGuests forKey:@"maxGuests"];
    else
        [meetupData removeObjectForKey:@"maxGuests"];
    if ( strImageURL)
        [meetupData setObject:strImageURL forKey:@"imageURL"];
    else
        [meetupData removeObjectForKey:@"imageURL"];
    if ( strOriginalURL )
        [meetupData setObject:strOriginalURL forKey:@"originalURL"];
    else
        [meetupData removeObjectForKey:@"originalURL"];
    
    if ( strGroupId )
        [meetupData setObject:strGroupId forKey:@"groupId"];
    
    // Save
    if ( bFirstSave )
    {
        NSError* error = [[NSError alloc] init];
        [meetupData save:&error];
        if ( error.code != 0 )
        {
            NSLog(@"Meetup save error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"No internet" message:@"Save failed, check your connection and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            return false;
        }
        if ( target )
            [target performSelector:selector withObject:(error?nil:self)];
        
        return true;
    }
    else
    {
        [meetupData saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error)
            {
                NSLog(@"Meetup save error: %@", error);
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"No internet" message:@"Be aware: the meetup or thread you recently edited wasn't saved due to lack of connection!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
            if ( target )
                [target performSelector:selector withObject:(error?nil:self)];
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
    strDescription = [meetupData objectForKey:@"description"];
    strPrice = [meetupData objectForKey:@"price"];
    maxGuests = [meetupData objectForKey:@"maxGuests"];
    strImageURL = [meetupData objectForKey:@"imageURL"];
    strOriginalURL = [meetupData objectForKey:@"originalURL"];
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
    if ( [meetupData objectForKey:@"canceled"] )
        isCanceled = [[meetupData objectForKey:@"canceled"] boolValue];
    strFeatured = [meetupData objectForKey:@"featured"];
    strGroupId = [meetupData objectForKey:@"groupId"];
    
    // Imported type
    if ( [[strId substringToIndex:4] compare:@"mtmt"] == NSOrderedSame )
        importedType = IMPORTED_MEETUP;
}

-(NSUInteger)getUnreadMessagesCount
{
    if ( bImportedEvent )
        return 0;
    NSUInteger nOldCount = [currentPerson getConversationCount:strId meetup:TRUE];
    if ( numComments < nOldCount )
        return 0;
    return numComments - nOldCount;
}

-(Boolean)hasPassed
{
    return [dateTime compare:[NSDate dateWithTimeIntervalSinceNow:
                              -(NSTimeInterval)durationSeconds]] == NSOrderedAscending;
}

-(Boolean)isWithinTimeFrame:(NSDate*)windowStart till:(NSDate*)windowEnd
{
    NSDate* dateEnds = [dateTime dateByAddingTimeInterval:durationSeconds];
    if ( [dateTime compare:windowStart] == NSOrderedAscending &&
            [dateEnds compare:windowStart] == NSOrderedAscending )
        return false;
    if ( [dateTime compare:windowEnd] == NSOrderedDescending &&
        [dateEnds compare:windowEnd] == NSOrderedDescending )
        return false;
    return true;
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
    
    FugeAppDelegate *delegate = AppDelegate;
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
    if ( alertView.tag == 1 )
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
}

-(void) addToCalendar
{
    // Already added
    if ( [self addedToCalendar] )
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Calendar" message:@"This meetup is already added to your calendar." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
        message.tag = 1;
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
    /*EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    NSDate* dateEnd = [[NSDate alloc] initWithTimeInterval:durationSeconds sinceDate:dateTime];
    NSPredicate *predicateForEvents = [eventStore predicateForEventsWithStartDate:dateTime endDate:dateEnd calendars:nil];
    
    NSArray *eventsFound = [eventStore eventsMatchingPredicate:predicateForEvents];
    
    for (EKEvent *eventToCheck in eventsFound)
    {
        if ([eventToCheck.location isEqualToString:strAddress])
            if ( [eventToCheck.title isEqualToString:[strSubject stringByAppendingFormat:@" at %@", strVenue]])
            return true;
    }*/
    
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

-(Boolean)hasAttendee:(NSString*)str
{
    if ( [attendees indexOfObject:str] == NSNotFound )
        return FALSE;
    return TRUE;
}

-(void)addAttendee:(NSString*)str
{
    if ( ! attendees )
        attendees = [[NSMutableArray alloc] initWithObjects:strId,nil];
    else
    {
        [attendees removeObjectIdenticalTo:str];
        [attendees addObject:str];
    }
}

-(void)removeAttendee:(NSString*)str
{
    if ( attendees )
        [attendees removeObjectIdenticalTo:str];
}

-(void)setCanceled
{
    isCanceled = TRUE;
}
-(Boolean)isCanceled
{
    return isCanceled;
}

-(Boolean)willStartSoon
{
    if ( [self isCanceled] )
        return FALSE;
    if ( [self hasPassed] )
        return FALSE;
    if ( meetupType != TYPE_MEETUP )
        return FALSE;
    
    if ( [self getTimerTill] > TIME_FOR_JOIN_PERSON_AND_MEETUP)
        return TRUE;
    return FALSE;
}

-(Boolean)isPersonNearby:(Person*)person
{
    CLLocation *loc1 = [[CLLocation alloc]initWithLatitude:person.location.latitude longitude:person.location.longitude];
    CLLocation *loc2 = [[CLLocation alloc]initWithLatitude:location.latitude longitude:location.longitude];
    if ([loc1 distanceFromLocation:loc2] < DISTANCE_FOR_JOIN_PERSON_AND_MEETUP) {
        return YES;
    }
    return NO;
}

-(NSInteger)spotsAvailable
{
    if ( ! maxGuests )
        return 999;
    NSInteger nSpots = [maxGuests integerValue] - (NSInteger)attendees.count;
    if ( nSpots < 0 ) nSpots = 0;
    return nSpots;
}

@end
