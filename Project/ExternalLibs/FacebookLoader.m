//
//  FacebookLoader.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/22/13.
//
//

#import "FacebookLoader.h"

@implementation FacebookLoader

- (void)loadMeetups:(id)target selector:(SEL)callback
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
             //NSLog(@"Result: %@", result);
             
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
             if ( target )
                 [target performSelector:callback withObject:eventsApproved];
         }
     }];
}

#define keys @[@"/me/movies", @"/me/music", @"/me/games", @"/me/books", @"/me/interests", @"/me/likes"]
#define categories @[@"Movies", @"Music", @"Games", @"Books", @"Interests", @"Likes"]

- (void)loadLikesData:(NSInteger)stage result:(NSMutableArray*)data caller:(id)target selector:(SEL)callback
{
    [FBRequestConnection startWithGraphPath:keys[stage] completionHandler:^(FBRequestConnection *connection, id likes, NSError *error) {
        
        if (error)
        {
            NSLog(@"%@", error);
            return;
        }
        else
        {
            //NSLog(@"%@: %@", keys[stage], [likes data]);
            
            // Importing results
            NSArray* tempData = (NSArray*)[likes data];
            if ( tempData )
            {
                for ( NSDictionary* item in tempData )
                {
                    // Grab data
                    NSString* strName = [item objectForKey:@"name"];
                    NSString* strId = [item objectForKey:@"id"];
                    NSDictionary* newItem = [NSDictionary dictionaryWithObjectsAndKeys:strId, @"id", strName, @"name", categories[stage], @"cat", nil];
                    
                    // Check for duplicants
                    Boolean bFound = false;
                    for ( NSDictionary* oldItem in data )
                    {
                        NSString* strOldId = [oldItem objectForKey:@"id"];
                        if ( [strOldId compare:strId] == NSOrderedSame )
                            bFound = true;
                    }
                    
                    // Add to result
                    if ( ! bFound )
                        [data addObject:newItem];
                }
            }
            
            // Proceed to the next stage or call selector if finished
            if ( stage < keys.count - 1 )
                [self loadLikesData:stage+1 result:data caller:target selector:callback];
            else if ( target )
                [target performSelector:callback withObject:data];
        }
    }];
}

- (void)loadLikes:(id)target selector:(SEL)callback
{
    // Getting likes
    NSMutableArray* allThings = [NSMutableArray arrayWithCapacity:30];
    
    [self loadLikesData:0 result:allThings caller:target selector:callback];
}

@end
