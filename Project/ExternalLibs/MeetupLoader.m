//
//  MeetupLoader.m
//  meetup
//
//  Created by 0 on 7/30/13.
//
//

#import "MeetupLoader.h"
#import "XMLDictionary.h"

@implementation MeetupLoader

static MeetupLoader *sharedInstance = nil;

static const NSString *MeetupAPIkey = @"69665c4e96f263c20106168443f534b";

+ (MeetupLoader *)sharedInstance {
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

-(void)loadMeetup:(NSString*)meetupId owner:(id)target selector:(SEL)callback{
    
    NSAssert(meetupId && [meetupId length], @"meetup id invalid");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.meetup.com/2/event/%@.xml?key=%@", meetupId, MeetupAPIkey]]];
        [req setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
        
        NSURLResponse *resp = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&error];
        NSDictionary *ret = nil;
        
        if(!data){
            if(error){
                NSLog(@"error when requesting url: %@", [error description]);
            }
        }else{
            ret = [NSDictionary dictionaryWithXMLData:data];
            if([ret objectForKey:@"code"]&&[[ret objectForKey:@"code"] isEqualToString:@"not_found"])
                ret = nil;
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if([target respondsToSelector:callback])
                [target performSelector:callback withObject:ret];
        });
        
    });
}

-(void)loadMeetups:(NSString*)groupUrl owner:(id)target selector:(SEL)callback{
    NSAssert(groupUrl && [groupUrl length], @"invalid group url");
    
    // Checking url
    NSString* regEx = @"^((http|https)://){0,1}www.meetup.com/[a-zA-Z0-9-]+/{0,1}$";
    NSPredicate *valid = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regEx];
    if ( ! [valid evaluateWithObject:groupUrl] )
    {
        groupUrl = [NSString stringWithFormat:@"http://www.meetup.com/%@", groupUrl];
        valid = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regEx];
        if ( ! [valid evaluateWithObject:groupUrl] )
        {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Wrong url" message:@"There's something wrong with the url" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [message show];
            return;
        }
    }
    
    // Loading data
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.meetup.com/2/events.xml?key=%@&group_urlname=%@&status=upcoming&limited_events=true", MeetupAPIkey, [groupUrl lastPathComponent]]]];
        [req setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
        
        NSURLResponse *resp = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&error];
        NSArray *ret = nil;
        
        if(!data){
            if(error){
                NSLog(@"error when requesting url: %@", [error description]);
            }
        }else{
            ret = [[NSDictionary dictionaryWithXMLData:data] valueForKeyPath:@"items.item"];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if([target respondsToSelector:callback])
                [target performSelector:callback withObject:ret];
        });
        
    });
}

-(void)callback:(id)object{
    NSLog(@"\n\ncallback for: %@", object);
}


@end
