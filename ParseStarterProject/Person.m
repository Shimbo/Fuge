
#import "Person.h"
#import "ParseStarterProjectAppDelegate.h"
#import "PersonView.h"
#import "Circle.h"

@implementation Person

@synthesize strId, strName, strAge, strGender, strDistance, strRole, strArea, strCircle, idCircle, personData,numUnreadMessages;

+ (void)initialize {
	if (self == [Person class]) {
	}
}

- (id)init:(PFUser*)user circle:(NSUInteger)nCircle{
	
	if (self = [super init]) {
        
        personData = user;
        
        // Data parsing
        strId = [user objectForKey:@"fbId"];
        strName = [user objectForKey:@"fbName"];
        strGender = [user objectForKey:@"fbGender"];
        strRole = [user objectForKey:@"profileRole"];
        strArea = [user objectForKey:@"profileArea"];
        strCircle = [Circle getPersonType:nCircle];
        idCircle = nCircle;
        
        // Location
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

- (void)updateLocation:(PFGeoPoint*)ptNewLocation
{
    // Distance calculation
    strDistance = @"";
    PFGeoPoint *geoPointUser = [[PFUser currentUser] objectForKey:@"location"];
    PFGeoPoint *geoPointFriend = ptNewLocation;
    CLLocation* locationFriend = nil;
    CLLocationDistance distance = 40000000.0f;
    if ( ! geoPointUser || ! geoPointFriend )
        return;
    
    CLLocation* locationUser = [[CLLocation alloc] initWithLatitude:geoPointUser.latitude longitude:geoPointUser.longitude];
    locationFriend = [[CLLocation alloc] initWithLatitude:geoPointFriend.latitude longitude:geoPointFriend.longitude];
    distance = [locationUser distanceFromLocation:locationFriend];
        
    if ( distance < 1000.0f )
        strDistance = [[NSString alloc] initWithFormat:@"%.0f m", distance];
    else if ( distance < 10000.0f )
        strDistance = [[NSString alloc] initWithFormat:@"%.1f km", distance/1000.0f];
    else
        strDistance = [[NSString alloc] initWithFormat:@"%.0f km", distance/1000.0f];
        
    location = locationFriend.coordinate;
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

- (CLLocationCoordinate2D) getLocation
{
    return location;
}

@end