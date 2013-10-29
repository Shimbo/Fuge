
#import "Person.h"
#import "AppDelegate.h"
#import "PersonView.h"
#import "Circle.h"
#import "LocationManager.h"
#import "GlobalData.h"
#import "GlobalVariables.h"
#import "FacebookLoader.h"
#import "FUGOpportunitiesView.h"

@implementation FUGOpportunity
-(NSDictionary*)serialized
{
    return [NSDictionary dictionaryWithObjectsAndKeys:_text, @"text", _dateCreated, @"date", _dateUpdated, @"dateUpdated", nil];
}
-(BOOL)isOutdated
{
    return [_dateUpdated compare:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)-7*86400] ] == NSOrderedAscending;
}
@end

@implementation Person

+ (void)initialize {
	if (self == [Person class]) {
	}
}

static Person *currentInstance = nil;

+ (Person*)currentInstance {
    if ( ! currentInstance )
        currentInstance = [[Person alloc] init:pCurrentUser circle:0];
    return currentInstance;
}

- (id)init:(PFUser*)user circle:(NSUInteger)nCircle{
	
	if (self = [super init]) {
        
        _personData = user;
        
        // Data parsing
        _strId = [user objectForKey:@"fbId"];
        _strFirstName = [user objectForKey:@"fbNameFirst"];
        _strLastName = [user objectForKey:@"fbNameLast"];
        _strGender = [user objectForKey:@"fbGender"];
        _strCircle = [Circle getPersonType:nCircle];
        _idCircle = nCircle;
        if ( [user objectForKey:@"discoverable"] )
            _discoverable = [[user objectForKey:@"discoverable"] boolValue];
        else
            _discoverable = TRUE;
        
        // Friends and likes
        _friendsFb = [user objectForKey:@"fbFriends"];
        _friends2O = [user objectForKey:@"fbFriends2O"];
        _likes = [user objectForKey:@"fbLikes"];
        
        // Age calculations
        NSDateFormatter* myFormatter = [[NSDateFormatter alloc] init];
        [myFormatter setDateFormat:@"MM/dd/yyyy"];
        NSDate* birthday = [myFormatter dateFromString:[user objectForKey:@"fbBirthday"]];
        if ( birthday )
        {
            NSDate* now = [NSDate date];
            NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                               components:NSYearCalendarUnit
                                               fromDate:birthday
                                               toDate:now
                                               options:0];
            NSInteger age = [ageComponents year];
            _strAge = [NSString stringWithFormat:@"%d y/o", age];
        }
        else
            _strAge = @"";
        
        _numUnreadMessages = 0;
        
        // Current user
        if ( [[user objectForKey:@"fbId"] compare:strCurrentUserId] == NSOrderedSame )
            _isCurrentUser = YES;
        
        // Dynamic data
        [self update:user];
	}
	return self;
}

- (void)update:(PFUser*)newData
{
    if ( newData )
        _personData = newData;
    
    _location = [_personData objectForKey:@"location"];
    
    _strEmployer = [_personData objectForKey:@"profileEmployer"];
    _strPosition = [_personData objectForKey:@"profilePosition"];
    _strStatus = [_personData objectForKey:@"profileStatus"];
    
    // Opportunities
    NSDictionary* ops = [_personData objectForKey:@"opportunities"];
    if ( ops )
    {
        _allOpportunities = [NSMutableArray arrayWithCapacity:ops.count];
        _visibleOpportunities = [NSMutableArray arrayWithCapacity:ops.count];
        for ( NSString* strId in ops.allKeys )
        {
            NSDictionary* op = [ops objectForKey:strId];
            FUGOpportunity* opportunity = [[FUGOpportunity alloc] init];
            opportunity.opId = strId;
            opportunity.text = [op objectForKey:@"text"];
            opportunity.dateCreated = [op objectForKey:@"date"];
            opportunity.dateUpdated = [op objectForKey:@"dateUpdated"];
            
            // Exclude hidden
            BOOL visible = TRUE;
            if ( ! self.isCurrentUser )
            {
                NSDate* lastDate = [globalData getPersonOpportunityHideDate:_strId];
                if ( lastDate )
                    if ( [lastDate compare:opportunity.dateCreated] == NSOrderedDescending )
                        visible = FALSE;
            }
            opportunity.read = ! visible;
            
            // Add own and not outdated and not hidden
            if ( self.isCurrentUser || ( ! opportunity.isOutdated && visible ) )
                [_visibleOpportunities addObject:opportunity];
            if ( self.isCurrentUser || ! opportunity.isOutdated )
                [_allOpportunities addObject:opportunity];
        }
        [_allOpportunities sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            FUGOpportunity* o1 = obj1;
            FUGOpportunity* o2 = obj2;
            return [o2.dateCreated compare:o1.dateCreated];
        }];
        [_visibleOpportunities sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            FUGOpportunity* o1 = obj1;
            FUGOpportunity* o2 = obj2;
            return [o2.dateCreated compare:o1.dateCreated];
        }];
        _visibleOpportunitiesHeight = [FUGOpportunitiesView estimateOpportunitiesHeight:_visibleOpportunities];
    }
}

- (void)changeCircle:(NSUInteger)nCircle
{
    _strCircle = [Circle getPersonType:nCircle];
    _idCircle = nCircle;
}

- (id)initEmpty:(NSUInteger)nCircle{
    
    if (self = [super init]) {
        
        _personData = nil;
        _numUnreadMessages = 0;
        _strCircle = [Circle getPersonType:nCircle];
        _idCircle = nCircle;
    }
    
    return self;
}

- (Boolean)isNotActive
{
    if ( [_personData.updatedAt compare:[NSDate dateWithTimeIntervalSinceNow:-(NSTimeInterval)PERSON_NOTACTIVE_TIME]] == NSOrderedAscending )
        return true;
    return false;
}

- (Boolean)isOutdated
{
    if ( [_personData.updatedAt compare:[NSDate dateWithTimeIntervalSinceNow:-(NSTimeInterval)PERSON_OUTDATED_TIME]] == NSOrderedAscending )
        return true;
    return false;
}

- (NSDate*)updateDate
{
    return _personData.updatedAt;
}

-(NSString*)timeString
{
    if ( ! _personData )
        return @"";
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - [_personData.updatedAt timeIntervalSince1970];
    
    // Multiplying by 2 to get at least 2 hours, 2 days, etc. (to get rid of singular forms)
    if ( interval < 60.0f*2.0f )
        return [[NSString alloc] initWithFormat:@"%.0f secs", interval];
    else if ( interval < 60.0f*60.0f*2.0f )
        return [[NSString alloc] initWithFormat:@"%.0f mins", interval/60.0f];
    else if ( interval < 60.0f*60.0f*24.0f*2.0f )
        return [[NSString alloc] initWithFormat:@"%.0f hours", interval/(60.0f*60.0f)];
    else if ( interval < 60.0f*60.0f*24.0f*7.0f*2.0f )
        return [[NSString alloc] initWithFormat:@"%.0f days", interval/(60.0f*60.0f*24.0f)];
    else if ( interval < 60.0f*60.0f*24.0f*30.0f*2.0f )
        return [[NSString alloc] initWithFormat:@"%.0f weeks", interval/(60.0f*60.0f*24.0f*7.0f)];
    else if ( interval < 60.0f*60.0f*24.0f*30.0f*12.0f*2.0f )
        return [[NSString alloc] initWithFormat:@"%.0f months", interval/(60.0f*60.0f*24.0f*30.0f)];
    else
        return [[NSString alloc] initWithFormat:@"%.0f years", interval/(60.0f*60.0f*24.0f*30.0f*12.0f)];
}

-(NSString*)smallAvatarUrl{
#ifdef TARGET_FUGE
    return [fbLoader getSmallAvatarUrl:_strId];
#elif defined TARGET_S2C
    if ( _personData )
        return [_personData objectForKey:@"urlAvatar"];
    else
        return nil;
#endif
}

-(NSString*)largeAvatarUrl{
#ifdef TARGET_FUGE
    return [fbLoader getLargeAvatarUrl:_strId];
#elif defined TARGET_S2C
    if ( ! _personData )
        return nil;
    NSArray* photos = [_personData objectForKey:@"urlPhotos"];
    if ( photos && photos.count > 0 )
        return photos[0];
    else
        return [_personData objectForKey:@"urlAvatar"];
#endif
}

-(NSString*)shortName
{
    return [globalVariables shortName:_strFirstName last:_strLastName];
}

-(NSString*)fullName
{
    return [globalVariables fullName:_strFirstName last:_strLastName];
}

-(NSString*)jobInfo
{
    NSString* strResult = @"";
    if (_strEmployer && _strPosition && _strEmployer.length > 0 && _strPosition.length > 0 )
        strResult = [NSString stringWithFormat:@"%@, %@", _strPosition, _strEmployer];
    else if (_strEmployer && _strEmployer.length)
        strResult = _strEmployer;
    else
        strResult = _strPosition;
    return strResult;
}

-(NSString*)industryInfo
{
    return [_personData objectForKey:@"profileIndustry"];
}

-(void)openProfileInBrowser
{
#ifdef TARGET_FUGE
    NSString *url = [fbLoader getProfileUrl:_strId];
#elif defined TARGET_S2C
    NSString *url = [_personData objectForKey:@"urlProfile"];
    if ( ! url )
        return;
#endif
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}


/*
- (UIImage *)getImage {
    if (image == nil && imageData == nil && urlConnection == nil )
    {
        // Download the user's facebook profile picture
        imageData = [[NSMutableData alloc] init]; // the data will be loaded in here
        
        // URL should point to https://graph.facebook.com/{facebookId}/picture?type=large&return_ssl_resources=1
        pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&return_ssl_resources=1", strId]];
        
        urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f];
        
        // Run network request asynchronously
        urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    }

    // Return profile image
	return image;
}
 

// Called every time a chunk of the data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [imageData appendData:data]; // Build the image
}

// Called when the entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Set the image in the header imageView
    image = [UIImage imageWithData:imageData];
    [pParent setNeedsDisplay];
}

- (void)dealloc {
}*/

/*- (void) setLocation:(CLLocationCoordinate2D) loc
{
    location = loc;
}*/

// How many of my friends are her friends
- (NSArray*) matchedFriendsToFriends
{
    NSArray* myFriends = [pCurrentUser objectForKey:@"fbFriends"];
    if ( ! myFriends )
        return [NSArray array];
    if ( ! _friendsFb )
        return [NSArray array];
    
    NSMutableSet* intersection = [NSMutableSet setWithArray:myFriends];
    [intersection intersectSet:[NSSet setWithArray:_friendsFb]];
    return [intersection allObjects];
}

// How many of my friends are her 2O friends
- (NSArray*) matchedFriendsTo2O
{
    // All my friends have my other friends in 2O friends, obviously, so return 0
    if ( _idCircle == CIRCLE_FB )
        return [NSArray array];
        
    NSArray* myFriends = [pCurrentUser objectForKey:@"fbFriends"];
    if ( ! myFriends )
        return [NSArray array];
    if ( ! _friends2O )
        return [NSArray array];
    
    NSMutableSet* intersection = [NSMutableSet setWithArray:myFriends];
    [intersection intersectSet:[NSSet setWithArray:_friends2O]];
    
    return [intersection allObjects];
}

// How many of my 2O friends are her friends
- (NSArray*) matched2OToFriends
{
    // All her friends are my 2O friends in case we're friends, return 0
    if ( _idCircle == CIRCLE_FB )
        return [NSArray array];
    
    NSArray* myFriends2O = [pCurrentUser objectForKey:@"fbFriends2O"];
    if ( ! myFriends2O )
        return [NSArray array];
    if ( ! _friendsFb )
        return [NSArray array];
    
    NSMutableSet* intersection = [NSMutableSet setWithArray:myFriends2O];
    [intersection intersectSet:[NSSet setWithArray:_friendsFb]];
    return [intersection allObjects];
}

// How many of my 2O friends are her 2O friends
/*- (NSArray*) matched2OTo2O
{
    NSMutableArray* arrayFriends2O = [NSMutableArray arrayWithArray:friends2O];
     
     // Removing 2O friends added from mutual friends
     Circle* friends = [globalData getCircle:CIRCLE_FB];
     for ( Person* person in friends.getPersons )
     [arrayFriends2O removeObjectsInArray:person.friends2O];
     
     NSMutableSet* intersection = [NSMutableSet setWithArray:arrayFriends2O];
     
     // Intersection
     NSArray* myFriends2O = [pCurrentUser objectForKey:@"fbFriends2O"];
     [intersection intersectSet:[NSSet setWithArray:myFriends2O]];
     
     return [intersection allObjects];
}*/

- (NSArray*) matchedLikes
{
    NSArray* myLikes = [pCurrentUser objectForKey:@"fbLikes"];
    if ( ! myLikes )
        return [NSArray array];
    if ( ! _likes )
        return [NSArray array];
    
    NSArray* strLikes = [_likes valueForKeyPath:@"id"];
    NSArray* strMyLikes = [myLikes valueForKeyPath:@"id"];
    
    NSMutableSet* intersection = [NSMutableSet setWithArray:strMyLikes];
    [intersection intersectSet:[NSSet setWithArray:strLikes]];
    
    return [intersection allObjects];
}

- (NSUInteger) matchesTotal
{
    return self.matchedFriendsToFriends.count
            +self.matchedFriendsTo2O.count
            +self.matchedLikes.count;
}

- (NSUInteger) matchesAdminBonus
{
    if ( bIsAdmin )
        return self.matched2OToFriends.count;
    else
        return 0;
}

- (NSUInteger) matchesRank
{
    NSUInteger bonusFriends = self.matchedFriendsToFriends.count*MATCHING_BONUS_FRIEND;
    
    NSUInteger bonusLikes = self.matchedLikes.count*MATCHING_BONUS_LIKE;
    
    NSUInteger bonus2O = self.matchedFriendsTo2O.count*MATCHING_BONUS_2O;
    if ( bonus2O > MATCHING_BONUS_2O_CAP )
        bonus2O = MATCHING_BONUS_2O_CAP;
    
    return bonusFriends + bonusLikes + bonus2O;
}

- (NSDictionary*) getLikeById:(NSString*)like
{
    for ( NSDictionary* item in _likes )
        if ( [(NSString*)[item objectForKey:@"id"] compare:like] == NSOrderedSame )
            return item;
    return nil;
}

- (NSUInteger) getConversationCountStats:(Boolean)onlyNotEmpty onlyMessages:(Boolean)bOnlyMessages
{
    NSUInteger nResult = 0;
    
    if ( [_personData objectForKey:@"messageCounts"] )
    {
        if ( onlyNotEmpty )
        {
            for ( NSNumber* counter in ((NSDictionary*)[_personData objectForKey:@"messageCounts"]).allValues)
                if ( [counter integerValue] != 0 )
                    nResult++;
        }
        else
            nResult += ((NSDictionary*)[_personData objectForKey:@"messageCounts"]).count;
    }
    
    if ( ! bOnlyMessages )
    if ( [_personData objectForKey:@"threadCounts"] )
    {
        if ( onlyNotEmpty )
        {
            for ( NSNumber* counter in ((NSDictionary*)[_personData objectForKey:@"threadCounts"]).allValues)
                if ( [counter integerValue] != 0 )
                    nResult++;
        }
        else
            nResult += ((NSDictionary*)[_personData objectForKey:@"threadCounts"]).count;
    }
    
    return nResult;
}

- (Boolean) getConversationPresence:(NSString*)strThread meetup:(Boolean)bMeetup
{
    NSString* strKeyCounts = bMeetup ? @"threadCounts" : @"messageCounts";
    
    NSMutableDictionary* conversations = [_personData objectForKey:strKeyCounts];
    if ( ! conversations )
        return false;
    NSNumber* num = [conversations valueForKey:strThread];
    if ( ! num )
        return false;
    return true;
}

- (NSDate*) getConversationDate:(NSString*)strThread meetup:(Boolean)bMeetup
{
    NSString* strKeyDates = bMeetup ? @"threadDates" : @"messageDates";
    
    NSMutableDictionary* conversations = [_personData objectForKey:strKeyDates];
    if ( ! conversations )
        return nil;
    return [conversations valueForKey:strThread];
}

- (NSUInteger) getConversationCount:(NSString*)strThread meetup:(Boolean)bMeetup
{
    NSString* strKeyCounts = bMeetup ? @"threadCounts" : @"messageCounts";
    
    NSMutableDictionary* conversations = [_personData objectForKey:strKeyCounts];
    if ( ! conversations )
        return 0;
    NSNumber* num = [conversations valueForKey:strThread];
    if ( ! num )
        return 0;
    return [num intValue];
}

- (NSUInteger) searchRating:(NSString*)searchString
{
    if ( self.fullName )
        if ( [[self.fullName lowercaseString] rangeOfString:searchString].location != NSNotFound )
            return 4;
    if ( self.strStatus )
        if ( [[self.strStatus lowercaseString] rangeOfString:searchString].location != NSNotFound )
            return 3;
    if ( self.profileSummary )
        if ( [[self.profileSummary lowercaseString] rangeOfString:searchString].location != NSNotFound )
            return 2;
    if ( self.profilePositions )
    {
        for ( NSDictionary* position in self.profilePositions )
            if ( [[position.description lowercaseString] rangeOfString:searchString].location != NSNotFound )
                return 1;
    }
    return 0;
}

-(NSString*)profileSummary
{
    return [_personData objectForKey:@"profileSummary"];
}

-(NSArray*)profilePositions
{
     return [_personData objectForKey:@"profilePositions"];
}

- (void) deleteOpportunity:(FUGOpportunity*)op
{
    if ( ! op )
        return;
    if ( ! _isCurrentUser )
        return;
    
    NSMutableDictionary* opsToSave = [pCurrentUser objectForKey:@"opportunities"];
    if ( ! opsToSave )
        return;
    
    // Serialize this op and save current user
    [opsToSave removeObjectForKey:op.opId];
    [pCurrentUser setObject:opsToSave forKey:@"opportunities"];
    [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
        {
            NSLog(@"Opportunity save error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"No internet" message:@"Opportunity save failed, no internet connection. Please, try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    [_allOpportunities removeObject:op];
    [_visibleOpportunities removeObject:op];
    
    _visibleOpportunitiesHeight = [FUGOpportunitiesView estimateOpportunitiesHeight:_visibleOpportunities];
}

- (void) saveOpportunity:(FUGOpportunity*)op
{
    if ( ! op )
        return;
    if ( ! _isCurrentUser )
        return;
    
    NSMutableDictionary* opsToSave = [pCurrentUser objectForKey:@"opportunities"];
    if ( ! opsToSave )
        return;
    
    // Serialize this op and save current user
    [opsToSave setObject:op.serialized forKey:op.opId];
    [pCurrentUser setObject:opsToSave forKey:@"opportunities"];
    [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
        {
            NSLog(@"Opportunity save error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"No internet" message:@"Opportunity save failed, no internet connection. Please, try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    _visibleOpportunitiesHeight = [FUGOpportunitiesView estimateOpportunitiesHeight:_visibleOpportunities];
}

- (FUGOpportunity*) addOpportunity:(NSString*)text
{
    if ( ! text )
        return nil;
    if ( ! _isCurrentUser )
        return nil;
    
    // Load/create arrays
    NSMutableDictionary* opsToSave;
    if ( ! _allOpportunities )
    {
        _allOpportunities = [NSMutableArray array];
        _visibleOpportunities = [NSMutableArray array];
        opsToSave = [NSMutableDictionary dictionary];
    }
    else
        opsToSave = [pCurrentUser objectForKey:@"opportunities"];
    
    // Add opportunity to the list
    NSString* opId = [NSString stringWithFormat:@"%@_%d", strCurrentUserId, (NSUInteger)[NSDate date].timeIntervalSince1970];
    FUGOpportunity* opportunity = [[FUGOpportunity alloc] init];
    opportunity.opId = opId;
    opportunity.text = text;
    opportunity.dateCreated = [NSDate date];
    opportunity.dateUpdated = [NSDate date];
    [_allOpportunities insertObject:opportunity atIndex:_allOpportunities.count];
    [_visibleOpportunities insertObject:opportunity atIndex:_visibleOpportunities.count];
    //[_opportunities addObject:opportunity];
    
    // Serialize this op and save current user
    [opsToSave setObject:opportunity.serialized forKey:opId];
    [pCurrentUser setObject:opsToSave forKey:@"opportunities"];
    [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
        {
            NSLog(@"Opportunity save error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"No internet" message:@"Opportunity save failed, no internet connection. Please, try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    _visibleOpportunitiesHeight = [FUGOpportunitiesView estimateOpportunitiesHeight:_visibleOpportunities];
    
    return opportunity;
}

@end