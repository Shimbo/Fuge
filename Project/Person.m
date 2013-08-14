
#import "Person.h"
#import "AppDelegate.h"
#import "PersonView.h"
#import "Circle.h"
#import "LocationManager.h"
#import "GlobalData.h"
#import "GlobalVariables.h"
#import "FacebookLoader.h"

@implementation Person

@synthesize strId, strFirstName, strLastName, strAge, strGender, /*role, strArea,*/ strEmployer, strPosition, strCircle, strStatus, idCircle, personData, numUnreadMessages, friendsFb, friends2O, likes, isCurrentUser, discoverable;

+ (void)initialize {
	if (self == [Person class]) {
	}
}

- (id)init:(PFUser*)user circle:(NSUInteger)nCircle{
	
	if (self = [super init]) {
        
        personData = user;
        
        // Data parsing
        strId = [user objectForKey:@"fbId"];
        strFirstName = [user objectForKey:@"fbNameFirst"];
        strLastName = [user objectForKey:@"fbNameLast"];
        strGender = [user objectForKey:@"fbGender"];
        strCircle = [Circle getPersonType:nCircle];
        strEmployer = [user objectForKey:@"profileEmployer"];
        strPosition = [user objectForKey:@"profilePosition"];
        strStatus = [user objectForKey:@"profileStatus"];
        idCircle = nCircle;
        if ( [user objectForKey:@"discoverable"] )
            discoverable = [[user objectForKey:@"discoverable"] boolValue];
        else
            discoverable = TRUE;
        
        // Location
        location = [user objectForKey:@"location"];
        
        // Friends and likes
        friendsFb = [user objectForKey:@"fbFriends"];
        friends2O = [user objectForKey:@"fbFriends2O"];
        likes = [user objectForKey:@"fbLikes"];
        
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
            strAge = [NSString stringWithFormat:@"%d y/o", age];
        }
        else
            strAge = @"";
        
        numUnreadMessages = 0;
        
        // Current user
        if ( user == pCurrentUser )
            isCurrentUser = YES;
	}
	return self;
}

- (void)update:(PFUser*)newData
{
    PFGeoPoint* newLocation = [newData objectForKey:@"location"];
    if ( newLocation )
        location = newLocation;
    
    strStatus = [newData objectForKey:@"profileStatus"];
    
    personData = newData;
}

- (void)changeCircle:(NSUInteger)nCircle
{
    strCircle = [Circle getPersonType:nCircle];
    idCircle = nCircle;
}

- (id)initEmpty:(NSUInteger)nCircle{
    
    if (self = [super init]) {
        
        personData = nil;
        numUnreadMessages = 0;
        strCircle = [Circle getPersonType:nCircle];
        idCircle = nCircle;
    }
    
    return self;
}

- (Boolean)isOutdated
{
    if ( [personData.updatedAt compare:[NSDate dateWithTimeIntervalSinceNow:-PERSON_OUTDATED_TIME]] == NSOrderedAscending )
        return true;
    return false;
}

-(NSString*)timeString
{
    if ( ! personData )
        return @"";
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - [personData.updatedAt timeIntervalSince1970];
    
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
    return [fbLoader getSmallAvatarUrl:strId];
#elif defined TARGET_S2C
    if ( personData )
        return [personData objectForKey:@"urlAvatar"];
    else
        return nil;
#endif
}

-(NSString*)largeAvatarUrl{
#ifdef TARGET_FUGE
    return [fbLoader getLargeAvatarUrl:strId];
#elif defined TARGET_S2C
    if ( ! personData )
        return nil;
    NSArray* photos = [personData objectForKey:@"urlPhotos"];
    if ( photos && photos.count > 0 )
        return photos[0];
    else
        return [personData objectForKey:@"urlAvatar"];
#endif
}

-(NSString*)shortName
{
    return [globalVariables shortName:strFirstName last:strLastName];
}

-(NSString*)fullName
{
    return [globalVariables fullName:strFirstName last:strLastName];
}

-(NSString*)jobInfo
{
    NSString* strResult = @"";
    if (strEmployer && strPosition && strEmployer.length > 0 && strPosition.length > 0 )
        strResult = [NSString stringWithFormat:@"%@, %@", strPosition, strEmployer];
    else if (strEmployer && strEmployer.length)
        strResult = strEmployer;
    else
        strResult = strPosition;
    return strResult;
}

#ifdef TARGET_S2C
-(NSString*)industryInfo
{
    return [personData objectForKey:@"profileIndustry"];
}
#endif

-(void)showInviteDialog
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys: strId, @"to", nil];
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:NSLocalizedString(@"FB_INVITE_MESSAGE_SIMPLE",nil) title:nil parameters:params handler:nil];
}

-(void)openProfileInBrowser
{
#ifdef TARGET_FUGE
    NSString *url = [fbLoader getProfileUrl:strId];
#elif defined TARGET_S2C
    NSString *url = [personData objectForKey:@"urlProfile"];
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
    if ( ! friendsFb )
        return [NSArray array];
    
    NSMutableSet* intersection = [NSMutableSet setWithArray:myFriends];
    [intersection intersectSet:[NSSet setWithArray:friendsFb]];
    return [intersection allObjects];
}

// How many of my friends are her 2O friends
- (NSArray*) matchedFriendsTo2O
{
    // All my friends have my other friends in 2O friends, obviously, so return 0
    if ( idCircle == CIRCLE_FB )
        return [NSArray array];
        
    NSArray* myFriends = [pCurrentUser objectForKey:@"fbFriends"];
    if ( ! myFriends )
        return [NSArray array];
    if ( ! friends2O )
        return [NSArray array];
    
    NSMutableSet* intersection = [NSMutableSet setWithArray:myFriends];
    [intersection intersectSet:[NSSet setWithArray:friends2O]];
    
    return [intersection allObjects];
}

// How many of my 2O friends are her friends
- (NSArray*) matched2OToFriends
{
    // All her friends are my 2O friends in case we're friends, return 0
    if ( idCircle == CIRCLE_FB )
        return [NSArray array];
    
    NSArray* myFriends2O = [pCurrentUser objectForKey:@"fbFriends2O"];
    if ( ! myFriends2O )
        return [NSArray array];
    if ( ! friendsFb )
        return [NSArray array];
    
    NSMutableSet* intersection = [NSMutableSet setWithArray:myFriends2O];
    [intersection intersectSet:[NSSet setWithArray:friendsFb]];
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
    if ( ! likes )
        return [NSArray array];
    
    NSArray* strLikes = [likes valueForKeyPath:@"id"];
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
    for ( NSDictionary* item in likes )
        if ( [(NSString*)[item objectForKey:@"id"] compare:like] == NSOrderedSame )
            return item;
    return nil;
}

- (NSUInteger) getConversationCountStats:(Boolean)onlyNotEmpty onlyMessages:(Boolean)bOnlyMessages
{
    NSUInteger nResult = 0;
    
    if ( [personData objectForKey:@"messageCounts"] )
    {
        if ( onlyNotEmpty )
        {
            for ( NSNumber* counter in ((NSDictionary*)[personData objectForKey:@"messageCounts"]).allValues)
                if ( [counter integerValue] != 0 )
                    nResult++;
        }
        else
            nResult += ((NSDictionary*)[personData objectForKey:@"messageCounts"]).count;
    }
    
    if ( ! bOnlyMessages )
    if ( [personData objectForKey:@"threadCounts"] )
    {
        if ( onlyNotEmpty )
        {
            for ( NSNumber* counter in ((NSDictionary*)[personData objectForKey:@"threadCounts"]).allValues)
                if ( [counter integerValue] != 0 )
                    nResult++;
        }
        else
            nResult += ((NSDictionary*)[personData objectForKey:@"threadCounts"]).count;
    }
    
    return nResult;
}

- (Boolean) getConversationPresence:(NSString*)strThread meetup:(Boolean)bMeetup
{
    NSString* strKeyCounts = bMeetup ? @"threadCounts" : @"messageCounts";
    
    NSMutableDictionary* conversations = [personData objectForKey:strKeyCounts];
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
    
    NSMutableDictionary* conversations = [personData objectForKey:strKeyDates];
    if ( ! conversations )
        return nil;
    return [conversations valueForKey:strThread];
}

- (NSUInteger) getConversationCount:(NSString*)strThread meetup:(Boolean)bMeetup
{
    NSString* strKeyCounts = bMeetup ? @"threadCounts" : @"messageCounts";
    
    NSMutableDictionary* conversations = [personData objectForKey:strKeyCounts];
    if ( ! conversations )
        return 0;
    NSNumber* num = [conversations valueForKey:strThread];
    if ( ! num )
        return 0;
    return [num intValue];
}

@end