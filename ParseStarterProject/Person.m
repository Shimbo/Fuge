
#import "Person.h"
#import "AppDelegate.h"
#import "PersonView.h"
#import "Circle.h"
#import "LocationManager.h"
#import "GlobalVariables.h"

@implementation Person

@synthesize strId, strFirstName, strLastName, strAge, strGender, distance, role, strArea, strCircle, idCircle, personData,numUnreadMessages;

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
        role = [user objectForKey:@"profileRole"];
        strArea = [user objectForKey:@"profileArea"];
        strCircle = [Circle getPersonType:nCircle];
        idCircle = nCircle;
        
        // Location
        location = nil;
        distance = nil;
        [self updateLocation:[user objectForKey:@"location"]];
        
        // Age calculations
        NSDateFormatter* myFormatter = [[NSDateFormatter alloc] init];
        [myFormatter setDateFormat:@"MM/dd/yyyy"];
        NSDate* birthday = [myFormatter dateFromString:[user objectForKey:@"fbBirthday"]];
        NSDate* now = [NSDate date];
        NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                           components:NSYearCalendarUnit
                                           fromDate:birthday
                                           toDate:now
                                           options:0];
        NSInteger age = [ageComponents year];
        strAge = [NSString stringWithFormat:@"%d y/o", age];
        
        numUnreadMessages = 0;
	}
	return self;
}

- (void)calculateDistance
{
    // Distance calculation
    PFGeoPoint* geoPointUser = [locManager getPosition];
    
    if ( ! location || ! geoPointUser )
    {
        distance = nil;
        return;
    }
    
    distance = [NSNumber numberWithDouble:
                [geoPointUser distanceInKilometersTo:location]*1000.0f];
}

- (void)updateLocation:(PFGeoPoint*)ptNewLocation
{
    if ( ptNewLocation )
        location = ptNewLocation;
    
    [self calculateDistance];
}

- (PFGeoPoint*) getLocation
{
    return location;
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


-(NSString*)distanceString
{
    if ( ! distance )
        return @"";
    else if ( [distance floatValue] < 1000.0f )
        return [[NSString alloc] initWithFormat:@"%.0f m", [distance floatValue]];
    else if ( [distance floatValue] < 10000.0f )
        return [[NSString alloc] initWithFormat:@"%.1f km", [distance floatValue]/1000.0f];
    else
        return [[NSString alloc] initWithFormat:@"%.0f km", [distance floatValue]/1000.0f];
}

-(NSString*)timeString
{
    if ( ! personData )
        return @"";
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - [personData.updatedAt timeIntervalSince1970];
    
    // Multiplying by 2 to get at least 2 hours, 2 days, etc. (to get rid of singular forms)
    if ( interval < 60.0f*2.0f )
        return [[NSString alloc] initWithFormat:@"%.0f seconds", interval];
    else if ( interval < 60.0f*60.0f*2.0f )
        return [[NSString alloc] initWithFormat:@"%.0f minutes", interval/60.0f];
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

- (NSUInteger)getFriendsInCommonCount
{
    NSArray* pCurrentUserFriends = [pCurrentUser objectForKey:@"fbFriends"];
    if ( ! pCurrentUserFriends )
        return 0;
    
    NSArray* pThatUserFriends = [personData objectForKey:@"fbFriends"];
    if ( ! pThatUserFriends )
        return 0;
    
    NSMutableSet* set1 = [NSMutableSet setWithArray:pCurrentUserFriends];
    NSMutableSet* set2 = [NSMutableSet setWithArray:pThatUserFriends];
    [set1 intersectSet:set2];
    NSArray* result = [set1 allObjects];
    return result.count;
}

+(NSString*)imageURLWithId:(NSString*)fbId
{
    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&width=100&height=100&return_ssl_resources=1", fbId];
}

+(NSString*)largeImageURLWithId:(NSString*)fbId
{
    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", fbId];
}


-(NSString*)imageURL{
    return [Person imageURLWithId:strId];
//    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&width=100&height=100&return_ssl_resources=1", fbId ? fbId : strId];
}

-(NSString*)largeImageURL{
    return [Person largeImageURLWithId:strId];
//    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", fbId ? fbId : strId];
}

-(NSString*)shortName
{
    return [globalVariables shortName:strFirstName last:strLastName];
}

-(NSString*)fullName
{
    return [globalVariables fullName:strFirstName last:strLastName];
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

@end