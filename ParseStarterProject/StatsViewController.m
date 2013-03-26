//
//  StatsViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/19/13.
//
//

#import <Parse/Parse.h>
#import "StatsViewController.h"

@implementation StatsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Some really hardcoded manual code only for stats
    NSMutableString* labels = [[NSMutableString alloc] init];
    NSMutableString* stats = [[NSMutableString alloc] init];
    
    // Counters
    PFQuery *userQuery = [PFUser query];
    userQuery.limit = 1000;
    NSNumber *userCount = [[NSNumber alloc] initWithInt:[userQuery countObjects]];
    /*NSArray* users = [userQuery findObjects];
    NSNumber *fbfriends =
    for ( PFUser* user in users )
    {
        
    }*/
    
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    NSNumber *msgCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    query = [PFQuery queryWithClassName:@"Meetup"];
    NSNumber *meetupCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    query = [PFQuery queryWithClassName:@"Comment"];
    NSNumber *commentCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    query = [PFQuery queryWithClassName:@"Invite"];
    NSNumber *inviteCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    query = [PFQuery queryWithClassName:@"Attendee"];
    NSNumber *attendeeCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    
    [labels appendString:@"User count: "];
    [stats appendString:[userCount stringValue]];
    [stats appendString:@"\n"];
    [labels appendString:@"\nThreads and meetups count: "];
    [stats appendString:[meetupCount stringValue]];
    [stats appendString:@"\n"];
    [labels appendString:@"\nPrivate messages count: "];
    [stats appendString:[msgCount stringValue]];
    [stats appendString:@"\n"];
    [labels appendString:@"\nComments count: "];
    [stats appendString:[commentCount stringValue]];
    [stats appendString:@"\n"];
    [labels appendString:@"\nInvite count: "];
    [stats appendString:[inviteCount stringValue]];
    [stats appendString:@"\n"];
    [labels appendString:@"\nAttendee count: "];
    [stats appendString:[attendeeCount stringValue]];
    [stats appendString:@"\n\n"];
    
    // Averages
    NSNumber *averageMeetups = [[NSNumber alloc] initWithDouble:([meetupCount doubleValue] / [userCount doubleValue])];
    [labels appendString:@"\n\nAverage threads/meetups: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageMeetups doubleValue]]];
    [stats appendString:@"\n"];
    
    NSNumber *averageMessages = [[NSNumber alloc] initWithDouble:([msgCount doubleValue] / [userCount doubleValue])];
    [labels appendString:@"\nAverage messages per user: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageMessages doubleValue]]];
    [stats appendString:@"\n"];
    
    NSNumber *averageComments = [[NSNumber alloc] initWithDouble:([commentCount doubleValue] / [userCount doubleValue])];
    [labels appendString:@"\nAverage comments per user: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageComments doubleValue]]];
    [stats appendString:@"\n"];
    
    NSNumber *averageInvites = [[NSNumber alloc] initWithDouble:([inviteCount doubleValue] / [userCount doubleValue])];
    [labels appendString:@"\nAverage invites per user: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageInvites doubleValue]]];
    [stats appendString:@"\n"];
    
    NSNumber *averageAttendees = [[NSNumber alloc] initWithDouble:([attendeeCount doubleValue] / [userCount doubleValue])];
    [labels appendString:@"\nAverage attendees per user: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageAttendees doubleValue]]];
    [stats appendString:@"\n\n"];
    
    NSNumber *averageThreadSize = [[NSNumber alloc] initWithDouble:([commentCount doubleValue] / [meetupCount doubleValue])];
    [labels appendString:@"\n\nAverage thread comments: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageThreadSize doubleValue]]];
    [stats appendString:@"\n"];
    
    NSNumber *averageThreadInvites = [[NSNumber alloc] initWithDouble:([inviteCount doubleValue] / [meetupCount doubleValue])];
    [labels appendString:@"\nAverage meetup invites: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageThreadInvites doubleValue]]];
    [stats appendString:@"\n"];
    
    NSNumber *averageThreadAttendees = [[NSNumber alloc] initWithDouble:([attendeeCount doubleValue] / [meetupCount doubleValue])];
    [labels appendString:@"\nAverage meetup attendees: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageThreadAttendees doubleValue]]];
    [stats appendString:@"\n"];
    
    [_statsText setText:labels];
    [_statsNumbers setText:stats];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setStatsText:nil];
    [self setStatsNumbers:nil];
    [super viewDidUnload];
}
@end
