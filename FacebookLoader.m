//
//  FacebookLoader.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/22/13.
//
//

#import "FacebookLoader.h"

@implementation FacebookLoader

- (void)loadData:(id)target selector:(SEL)callback
{
    NSString *query =
    @"{"
    @"'event_info':'SELECT eid, venue, name, start_time, end_time, creator, host, attending_count from event WHERE eid in (SELECT eid FROM event_member WHERE uid = me())',"
    @"'event_venue':'SELECT name, location, page_id FROM page WHERE page_id IN (SELECT venue.id FROM #event_info)',"
    @"}";
    NSDictionary *queryParam = [NSDictionary dictionaryWithObjectsAndKeys:
                                query, @"q", nil];
    
    [FBRequestConnection startWithGraphPath:@"/fql" parameters:queryParam
                                 HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection,
                                                                       id result, NSError *error) {
         if (error) {
             NSLog(@"Error: %@", [error localizedDescription]);
             [target performSelector:callback withObject:nil];
         } else {
             NSLog(@"Result: %@", result);
             
             NSArray* data = [result objectForKey:@"data"];
             NSArray* events = [((NSDictionary*) data[0]) objectForKey:@"fql_result_set"];
             NSArray* venues = [((NSDictionary*) data[1]) objectForKey:@"fql_result_set"];
             
             NSMutableArray* eventsApproved = [[NSMutableArray alloc] initWithCapacity:30];
             
             for ( NSDictionary* event in events )
             {
                 for ( NSDictionary* venue in venues )
                 {
                     NSDictionary* eventVenue = [event objectForKey:@"venue"];
                     if ( ! eventVenue )
                         break;
                     NSString* eventVenueId = [eventVenue objectForKey:@"id"];
                     if ( ! eventVenueId )
                         break;
                     NSDictionary* venueLocation = [venue objectForKey:@"location"];
                     if ( ! venueLocation )
                         break;
                     NSString* venueId = [venue objectForKey:@"page_id"];
                     if ( ! venueId )
                         break;
                     if ( [eventVenueId compare:venueId] == NSOrderedSame )
                     {
                         NSDictionary* result = [NSDictionary dictionaryWithObjectsAndKeys:event, @"event", venue, @"venue", nil];
                         [eventsApproved addObject:result];
                     }
                 }
             }
             [target performSelector:callback withObject:eventsApproved];
         }
     }];
}

@end
