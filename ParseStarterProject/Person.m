
#import "Person.h"
#import "ParseStarterProjectAppDelegate.h"
#import "PersonView.h"

@implementation Person

@synthesize strId;
@synthesize strName;
@synthesize strAge;
@synthesize strGender;
@synthesize strDistance;
@synthesize strRole;
@synthesize strArea;
@synthesize strCircle;
@synthesize idCircle;

//@synthesize urlRequest;

//@synthesize pParent;

+ (void)initialize {
	if (self == [Person class]) {
	}
}

//- (void)addParent:(PersonView*)parent
//{
//    pParent = parent;
//}

- (id)init:(NSArray*) nameComponents circle:(NSUInteger)nCircle{
	
	if (self = [super init]) {
        strName = [[nameComponents objectAtIndex:0] copy];
        strId = [[nameComponents objectAtIndex:1] copy];
        strAge = [[nameComponents objectAtIndex:2] copy];
        strGender = [[nameComponents objectAtIndex:3] copy];
        strDistance = [[nameComponents objectAtIndex:4] copy];
        strRole = [[nameComponents objectAtIndex:5] copy];
        strArea = [[nameComponents objectAtIndex:6] copy];
        strCircle = [[nameComponents objectAtIndex:7] copy];
        idCircle = nCircle;
//        image = nil;
//        imageData = nil;
//        urlConnection = nil;
        object = nil;
	}
	return self;
}

-(NSString*)imageURL{
    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&width=100&height=100&return_ssl_resources=1", strId];
}

-(NSString*)largeImageURL{
    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", strId];
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

- (void) setLocation:(CLLocationCoordinate2D) loc
{
    location = loc;
}

- (CLLocationCoordinate2D) getLocation
{
    return location;
}

@end