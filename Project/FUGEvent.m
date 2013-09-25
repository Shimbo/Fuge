//
//  FUGEvent.m
//  Fuge
//
//  Created by Mikhail Larionov on 9/25/13.
//
//

#import "FUGEvent.h"

@implementation FUGEvent

@synthesize meetupData=_meetupData, featureString=_featureString;

-(id) initWithParseEvent:(PFObject*)data;
{
    self = [self init];
    
    _meetupData = data;
    
    if ( ! [data objectForKey:@"type"] )
        return nil;
    _meetupType = [[data objectForKey:@"type"] integerValue];
    _strId = [data objectForKey:@"meetupId"];
    if ( ! _strId )
        return nil;
    _strOwnerId = [data objectForKey:@"userFromId"];
    _strOwnerName = [data objectForKey:@"userFromName"];
    _strSubject = [data objectForKey:@"subject"];
    _strDescription = [data objectForKey:@"description"];
    _strPrice = [data objectForKey:@"price"];
    _maxGuests = [data objectForKey:@"maxGuests"];
    _strImageURL = [data objectForKey:@"imageURL"];
    _strOriginalURL = [data objectForKey:@"originalURL"];
    _privacy = [[data objectForKey:@"privacy"] integerValue];
    _dateTime = [data objectForKey:@"meetupDate"];
    _dateTimeExp = [data objectForKey:@"meetupDateExp"];
    _location = [data objectForKey:@"location"];
    _venueString = [data objectForKey:@"venue"];
    _venueId = [data objectForKey:@"venueId"];
    _venueAddress = [data objectForKey:@"address"];
    _commentsCount = [[data objectForKey:@"numComments"] integerValue];
    _attendees = [data objectForKey:@"attendees"];
    _decliners = [data objectForKey:@"decliners"];
    _durationSeconds = [[data objectForKey:@"duration"] integerValue];
    _iconNumber = [[data objectForKey:@"icon"] integerValue];
    if ( [data objectForKey:@"canceled"] )
        _canceled = [[data objectForKey:@"canceled"] boolValue];
    _featureString = [data objectForKey:@"featured"];
    //_strGroupId = [data objectForKey:@"groupId"];
    
    // Imported type
    //if ( [[strId substringToIndex:4] compare:@"mtmt"] == NSOrderedSame )
    //    importedType = IMPORTED_MEETUP;
    
    return self;
}

- (Boolean) feature:(NSString*)feature
{
    _featureString = feature;
    if ( feature && feature.length > 0 )
    {
        [_meetupData setObject:feature forKey:@"featured"];
        [_meetupData setObject:pCurrentUser forKey:@"featuredBy"];
    }
    else
    {
        [_meetupData removeObjectForKey:@"featured"];
        [_meetupData removeObjectForKey:@"featuredBy"];
    }
    NSError* error = [[NSError alloc] init];
    [_meetupData save:&error];
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
    
    NSNumber* timestamp = [[NSNumber alloc] initWithDouble:[self.dateTime timeIntervalSince1970]];
    
    // For the first save we can't do it in the background because following objects
    // could use objectId of this meetup. Saving in background will make these objects
    // to use wrong id as it creates on server.
    Boolean bFirstSave = false;
    
    if ( ! _meetupData )
    {
        bFirstSave = true;
        _meetupData = [PFObject objectWithClassName:@"Meetup"];
        
        // Id, fromStr, fromId
        [_meetupData setObject:[NSNumber numberWithInt:self.meetupType] forKey:@"type"];
        if ( ! _strId )
            _strId = [[NSString alloc] initWithFormat:@"%d_%@", [timestamp integerValue], self.strOwnerId];
        [_meetupData setObject:self.strId forKey:@"meetupId"];
        [_meetupData setObject:self.strOwnerId forKey:@"userFromId"];
        [_meetupData setObject:self.strOwnerName forKey:@"userFromName"];
        [_meetupData setObject:pCurrentUser forKey:@"userFromData"];
    }
    
    // Subject, privacy, date, timestamp, location
    [_meetupData setObject:self.strSubject forKey:@"subject"];
    [_meetupData setObject:[NSNumber numberWithInt:self.privacy] forKey:@"privacy"];
    [_meetupData setObject:self.dateTime forKey:@"meetupDate"];
    NSDate* dateToHide = [NSDate dateWithTimeInterval:self.durationSeconds sinceDate:self.dateTime];
    [_meetupData setObject:dateToHide forKey:@"meetupDateExp"];
    [_meetupData setObject:self.location forKey:@"location"];
    [_meetupData setObject:self.venueString forKey:@"venue"];
    [_meetupData setObject:self.venueId forKey:@"venueId"];
    [_meetupData setObject:self.venueAddress forKey:@"address"];
    [_meetupData setObject:[NSNumber numberWithInt:self.durationSeconds] forKey:@"duration"];
    [_meetupData setObject:[NSNumber numberWithInt:self.iconNumber] forKey:@"icon"];
    
    if ( self.canceled )
        [_meetupData setObject:[NSNumber numberWithBool:TRUE] forKey:@"canceled"];
    if ( self.strDescription )
        [_meetupData setObject:self.strDescription forKey:@"description"];
    else
        [_meetupData removeObjectForKey:@"description"];
    if ( self.strPrice )
        [_meetupData setObject:self.strPrice forKey:@"price"];
    else
        [_meetupData removeObjectForKey:@"price"];
    if ( self.maxGuests )
        [_meetupData setObject:self.maxGuests forKey:@"maxGuests"];
    else
        [_meetupData removeObjectForKey:@"maxGuests"];
    if ( self.strImageURL)
        [_meetupData setObject:self.strImageURL forKey:@"imageURL"];
    else
        [_meetupData removeObjectForKey:@"imageURL"];
    if ( self.strOriginalURL )
        [_meetupData setObject:self.strOriginalURL forKey:@"originalURL"];
    else
        [_meetupData removeObjectForKey:@"originalURL"];
    
    //if ( self.strGroupId )
    //    [meetupData setObject:self.strGroupId forKey:@"groupId"];
    
    // Save
    if ( bFirstSave )
    {
        NSError* error = [[NSError alloc] init];
        [_meetupData save:&error];
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
        [_meetupData saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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

- (void) cancel:(id)target selector:(SEL)selector
{
    // Saving meetup
    _canceled = TRUE;
    [self save:target selector:selector];
}

-(void)populateWithVenue:(FSVenue*)venue{
    if ( venue )
    {
        self.location = [PFGeoPoint geoPointWithLatitude:[venue.lat doubleValue]
                                               longitude:[venue.lon doubleValue]];
        _venueString = venue.name;
        _venueId = venue.venueId;
        if ( venue.address )
            _venueAddress = venue.address;
        if ( venue.city )
        {
            _venueAddress = [_venueAddress stringByAppendingString:@" "];
            _venueAddress = [_venueAddress stringByAppendingString:venue.city];
        }
        if ( venue.state )
        {
            _venueAddress = [_venueAddress stringByAppendingString:@" "];
            _venueAddress = [_venueAddress stringByAppendingString:venue.state];
        }
        if ( venue.postalCode )
        {
            _venueAddress = [_venueAddress stringByAppendingString:@" "];
            _venueAddress = [_venueAddress stringByAppendingString:venue.postalCode];
        }
        if ( venue.country )
        {
            _venueAddress = [_venueAddress stringByAppendingString:@" "];
            _venueAddress = [_venueAddress stringByAppendingString:venue.country];
        }
    }
}

-(void)populateWithCoords:(PFGeoPoint*)newLocation
{
    if ( ! newLocation )
        return;
    _location = newLocation;
    _venueString = [[NSString alloc] initWithFormat:@"Lat: %.3f, lon: %.3f", newLocation.latitude, newLocation.longitude];
}


@end