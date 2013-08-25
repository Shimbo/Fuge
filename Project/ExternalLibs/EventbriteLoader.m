//
//  EventbriteLoader.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/21/13.
//
//

#import "EventbriteLoader.h"
#import "XMLDictionary.h"

@implementation EventbriteLoader

#define TIMEOUT_INTERVAL 45

/*- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //NSString *someString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    //NSLog(someString);
    NSArray* eventsArray;
    NSDictionary* dict = [NSDictionary dictionaryWithXMLData:data];
    if ( dict )
        eventsArray = [dict objectForKey:@"event"];
    [resultTarget performSelector:resultCallback withObject:eventsArray];
}

- (void)loadData:(id)target selector:(SEL)callback
{
    resultTarget = target;
    resultCallback = callback;
    
    PFGeoPoint* location = [globalVariables currentLocation];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString* startDate = [dateFormatter stringFromDate:[NSDate date]];
    NSString* endDate = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:24*3600*3]];
    NSString* strRange = [NSString stringWithFormat:@"%@+%@", startDate, endDate];
    
    NSString* strRequest = [NSString stringWithFormat:@"https://www.eventbrite.com/xml/event_search?app_key=%@&within=100&within_unit=K&latitude=%f&longitude=%f&date=%@&max=30", EVENTBRITE_API_KEY, location.latitude, location.longitude, strRange];
    NSURL* urlRequest = [NSURL URLWithString:strRequest];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:urlRequest cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:TIMEOUT_INTERVAL];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (connection) {
        NSMutableData* data = [NSMutableData data];
        data = nil;
    } else {
    }
}*/

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *someString = [[NSString alloc] initWithData:receivedData encoding:NSASCIIStringEncoding];
    NSLog(@"Eventbrite results: %@", someString);
    NSArray* eventsArray;
    NSDictionary* dict = [NSDictionary dictionaryWithXMLData:receivedData];
    if ( dict )
        eventsArray = [dict objectForKey:@"event"];
    [resultTarget performSelector:resultCallback withObject:eventsArray];
}

- (void)loadData:(NSString*)strSource target:(id)target selector:(SEL)callback
{
    resultTarget = target;
    resultCallback = callback;
    receivedData = [NSMutableData data];
    
    NSString* strRequest = [NSString stringWithFormat:@"https://www.eventbrite.com/xml/organizer_list_events?app_key=%@&id=%@", EVENTBRITE_API_KEY, strSource];
    NSURL* urlRequest = [NSURL URLWithString:strRequest];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:urlRequest cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:TIMEOUT_INTERVAL];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (! connection)
        NSLog(@"Failed to establish Eventbrite connection");
}

@end
