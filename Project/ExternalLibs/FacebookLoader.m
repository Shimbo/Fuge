//
//  FacebookLoader.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/22/13.
//
//

#import "FacebookLoader.h"

@implementation FacebookLoader

#pragma mark -
#pragma mark Singleton

static FacebookLoader *sharedInstance = nil;

+ (FacebookLoader *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// Initialization
- (id)init
{
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

// We don't want to allocate a new instance, so return the current one.
+ (id)allocWithZone:(NSZone*)zone {
    return [self sharedInstance];
}

// Equally, we don't want to generate multiple copies of the singleton.
- (id)copyWithZone:(NSZone *)zone {
    return self;
}


#pragma mark -
#pragma mark Loaders


- (void)loadUserData:(NSDictionary<FBGraphUser>*)user
{
    // Store the current user's Facebook ID on the user
    [pCurrentUser setObject:user.id forKey:@"fbId"];
    if ( user.first_name )
        [pCurrentUser setObject:user.first_name forKey:@"fbNameFirst"];
    if ( user.last_name )
        [pCurrentUser setObject:user.last_name forKey:@"fbNameLast"];
    [pCurrentUser setObject:[[globalVariables fullUserName] lowercaseString] forKey:@"searchName"];
    if ( user.birthday )
        [pCurrentUser setObject:user.birthday forKey:@"fbBirthday"];
    if ( [user objectForKey:@"gender"] )
        [pCurrentUser setObject:[user objectForKey:@"gender"]
                         forKey:@"fbGender"];
    if ( [user objectForKey:@"email"] )
        pCurrentUser.email = [user objectForKey:@"email"];
    
    // Looking for job data
    NSArray* work = [user objectForKey:@"work"];
    if ( work )
        for ( NSDictionary* current in work )
        {
            if ( [current objectForKey:@"end_date"] )
                continue;
            NSDictionary* employer = [current objectForKey:@"employer"];
            NSString* strEmployer = @"";
            NSString* strPosition = @"";
            if ( employer && [employer objectForKey:@"name"] )
                strEmployer = [employer objectForKey:@"name"];
            NSDictionary* position = [current objectForKey:@"position"];
            if ( position && [position objectForKey:@"name"] )
                strPosition = [position objectForKey:@"name"];
            [pCurrentUser setObject:strEmployer forKey:@"profileEmployer"];
            [pCurrentUser setObject:strPosition forKey:@"profilePosition"];
        }
}

- (void)loadMeetups:(id)target selector:(SEL)callback
{
    NSString *query =
    @"{"
    @"\"event_info\":\"SELECT eid, venue, name, start_time, end_time, creator, host, attending_count FROM event WHERE eid IN (SELECT eid FROM event_member WHERE uid = me() AND rsvp_status = 'attending')\","
    @"\"event_venue\":\"SELECT name, location, page_id FROM page WHERE page_id IN (SELECT venue.id FROM #event_info)\","
    @"}";
    NSDictionary *queryParam = [NSDictionary dictionaryWithObjectsAndKeys:
                                query, @"q", nil];
    
    [FBRequestConnection startWithGraphPath:@"/fql" parameters:queryParam
                                 HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection,
                                                                       id result, NSError *error) {
         if (error) {
             NSLog(@"FB Loader error, meetups: %@", [error localizedDescription]);
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
                         break;
                     }
                 }
             }
             if ( target )
                 [target performSelector:callback withObject:eventsApproved];
         }
     }];
}

- (void)loadLikesData:(NSInteger)stage result:(NSMutableArray*)data caller:(id)target selector:(SEL)callback
{
    [FBRequestConnection startWithGraphPath:FACEBOOK_KEYS[stage] completionHandler:^(FBRequestConnection *connection, id likes, NSError *error) {
        
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
                    NSDictionary* newItem = [NSDictionary dictionaryWithObjectsAndKeys:strId, @"id", strName, @"name", FACEBOOK_CATEGORIES[stage], @"cat", nil];
                    
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
            if ( stage < FACEBOOK_KEYS.count - 1 )
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

- (void)loadFriends:(id)target selectorSuccess:(SEL)callbackSuccess selectorFailure:(SEL)callbackFailure
{
    FBRequest *request2 = [FBRequest requestForMyFriends];
    [request2 startWithCompletionHandler:^(FBRequestConnection *connection,
                                           id result, NSError *error)
     {
         if ( error )
         {
             NSLog(@"Uh oh. An error occurred: %@", error);
             [target performSelector:callbackFailure withObject:nil];
         }
         else
         {
             // Create a list of friends' Facebook IDs
             NSArray *friendObjects = [result objectForKey:@"data"];
             NSMutableArray *friends = [NSMutableArray arrayWithCapacity:friendObjects.count];
             for (NSDictionary *friendObject in friendObjects)
             {
                 [friends addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                       [friendObject objectForKey:@"id"], @"id",
                                       [friendObject objectForKey:@"name"], @"name",
                                       nil]];
             }
             
             // FB friends, 2O/FBout inside, 2O will call pushes block and user save
             [target performSelector:callbackSuccess withObject:friends];
         }
     }];
}

- (NSString*)getProfileUrl:(NSString*)strId
{
    return [NSString stringWithFormat:@"http://facebook.com/%@", strId];
}

- (NSString*)getSmallAvatarUrl:(NSString*)fbId
{
    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square&width=100&height=100&return_ssl_resources=1", fbId];
}

- (NSString*)getLargeAvatarUrl:(NSString*)fbId
{
    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", fbId];
}

- (void)showInviteDialog:(NSArray*)strIds message:(NSString*)message
{
    if ( ! strIds || strIds.count == 0 )
        return;
    
    NSMutableString* strInvitations = [NSMutableString stringWithString:@""];
    for ( NSString* strId in strIds )
        [strInvitations appendFormat:@"%@,", strId];
    if ( strInvitations.length > 0 )
    {
        [strInvitations substringToIndex:strInvitations.length-2];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:strInvitations, @"to", nil];
        [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:message title:nil parameters:params handler:nil];
    }
}

@end
