//
//  StatsViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/19/13.
//
//

#import <Parse/Parse.h>
#import "StatsViewController.h"
#import "PCLineChartView.h"

@implementation StatsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Some really hardcoded manual code only for stats
    //NSMutableString* labels = [[NSMutableString alloc] init];
    //NSMutableString* stats = [[NSMutableString alloc] init];
    
    // Loading data
    PFQuery *userQuery = [PFUser query];
    userQuery.limit = 1000;
    NSMutableArray* users = [NSMutableArray arrayWithCapacity:1000];
    NSArray* newBulk;
    do {
        newBulk = [userQuery findObjects];
        [users addObjectsFromArray:newBulk];
        userQuery.skip += newBulk.count;
    } while (newBulk && newBulk.count == userQuery.limit);
    
    NSUInteger nCount = 0;
    for (PFUser* user in users)
        if ( [user.updatedAt compare:[NSDate dateWithTimeIntervalSinceNow:-86400]] == NSOrderedDescending )
            nCount++;
    self.title = [NSString stringWithFormat:@"24h count: %d", nCount];
    
    /*NSNumber *userCount = [[NSNumber alloc] initWithInt:[userQuery countObjects]];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    NSNumber *msgCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    query = [PFQuery queryWithClassName:@"Meetup"];
    NSNumber *meetupCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    query = [PFQuery queryWithClassName:@"Comment"];
    NSNumber *commentCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    query = [PFQuery queryWithClassName:@"Invite"];
    NSNumber *inviteCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    //query = [PFQuery queryWithClassName:@"Attendee"];
    //NSNumber *attendeeCount = [[NSNumber alloc] initWithInt:[query countObjects]];
    
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
    //[stats appendString:[attendeeCount stringValue]];
    //[stats appendString:@"\n\n"];
    
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
    
    //NSNumber *averageAttendees = [[NSNumber alloc] initWithDouble:([attendeeCount doubleValue] / [userCount doubleValue])];
    //[labels appendString:@"\nAverage attendees per user: "];
    //[stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageAttendees doubleValue]]];
    //[stats appendString:@"\n\n"];
    
    NSNumber *averageThreadSize = [[NSNumber alloc] initWithDouble:([commentCount doubleValue] / [meetupCount doubleValue])];
    [labels appendString:@"\n\nAverage thread comments: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageThreadSize doubleValue]]];
    [stats appendString:@"\n"];
    
    NSNumber *averageThreadInvites = [[NSNumber alloc] initWithDouble:([inviteCount doubleValue] / [meetupCount doubleValue])];
    [labels appendString:@"\nAverage meetup invites: "];
    [stats appendString:[[NSString alloc] initWithFormat:@"%.1f", [averageThreadInvites doubleValue]]];
    [stats appendString:@"\n"];
    
    [_statsText setText:labels];
    [_statsNumbers setText:stats];*/
    
    _statsNumbers.hidden = TRUE;
    _statsText.hidden = TRUE;
    
    PCLineChartViewComponent* c1 = [[PCLineChartViewComponent alloc] init];
    c1.colour = [UIColor blueColor];
    c1.points = [NSMutableArray arrayWithCapacity:30];
    PCLineChartViewComponent* c2 = [[PCLineChartViewComponent alloc] init];
    c2.colour = [UIColor greenColor];
    c2.points = [NSMutableArray arrayWithCapacity:30];
    PCLineChartViewComponent* c3 = [[PCLineChartViewComponent alloc] init];
    c3.colour = [UIColor yellowColor];
    c3.points = [NSMutableArray arrayWithCapacity:30];
    PCLineChartViewComponent* c4 = [[PCLineChartViewComponent alloc] init];
    c4.colour = [UIColor redColor];
    c4.points = [NSMutableArray arrayWithCapacity:30];
    PCLineChartViewComponent* cc1 = [[PCLineChartViewComponent alloc] init];
    cc1.colour = [UIColor greenColor];
    cc1.points = [NSMutableArray arrayWithCapacity:30];
    PCLineChartViewComponent* cc2 = [[PCLineChartViewComponent alloc] init];
    cc2.colour = [UIColor yellowColor];
    cc2.points = [NSMutableArray arrayWithCapacity:30];
    PCLineChartViewComponent* cc3 = [[PCLineChartViewComponent alloc] init];
    cc3.colour = [UIColor redColor];
    cc3.points = [NSMutableArray arrayWithCapacity:30];
    
    NSInteger screenWidth = self.view.frame.size.width;
    NSInteger screenHeight = self.view.frame.size.height;
    PCLineChartView* chart1 = [[PCLineChartView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight/3)];
    chart1.xLabels = [NSMutableArray arrayWithCapacity:30];
    chart1.maxValue = 0;
    chart1.minValue = 0;
    PCLineChartView* chart2 = [[PCLineChartView alloc] initWithFrame:CGRectMake(0, screenHeight/3, screenWidth, screenHeight/3)];
    chart2.xLabels = [NSMutableArray arrayWithCapacity:30];
    chart2.maxValue = 100;
    chart2.minValue = 0;
    
    // Creating dictionary
    NSMutableDictionary* usersByDates = [NSMutableDictionary dictionary];
    for ( PFUser* user in users )
    {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:user.createdAt];
        NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:components];
        NSMutableArray* usersThisDay = [usersByDates objectForKey:newDate];
        if ( ! usersThisDay )
        {
            usersThisDay = [NSMutableArray arrayWithCapacity:30];
            [usersByDates setObject:usersThisDay forKey:newDate];
        }
        [usersThisDay addObject:user];
    }
    
    // Creating charts
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate dateWithTimeIntervalSinceNow:-100*86400]];
    components.year = 2013;
    components.month = 7;
    components.day = 26;
    NSDate *currentDate = [[NSCalendar currentCalendar] dateFromComponents:components];
    NSUInteger nDayShift = 0;
    while ([currentDate compare:[NSDate date]] == NSOrderedAscending)
    {
        // Calc date info
        NSDate* date = currentDate;
        components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];
        NSString* strLabel = [NSString stringWithFormat:@"%02d/%02d", [components month], [components day]];
        if ( nDayShift % 7 == 0 )
        {
            [chart1.xLabels addObject:strLabel];
            [chart2.xLabels addObject:strLabel];
        }
        else
        {
            [chart1.xLabels addObject:@" "];
            [chart2.xLabels addObject:@" "];
        }
        
        // Update counter
        currentDate = [currentDate dateByAddingTimeInterval:86400];
        nDayShift++;
        
        // Basic info
        NSMutableArray* usersThisDay = [usersByDates objectForKey:date];
        if ( ! usersThisDay )
        {
            [c1.points addObject:[NSNumber numberWithInt:0]];
            [c2.points addObject:[NSNumber numberWithInt:0]];
            [c3.points addObject:[NSNumber numberWithInt:0]];
            [c4.points addObject:[NSNumber numberWithInt:0]];
            [cc1.points addObject:[NSNumber numberWithInt:0]];
            [cc2.points addObject:[NSNumber numberWithInt:0]];
            [cc3.points addObject:[NSNumber numberWithInt:0]];
            continue;
        }
        
        // Installs per day
        [c1.points addObject:[NSNumber numberWithInt:usersThisDay.count]];
        if ( usersThisDay.count > chart1.maxValue )
            chart1.maxValue = usersThisDay.count;
        
        // Opened profile at least once
        NSUInteger nOpenedProfile = 0;
        NSUInteger nGotMessages = 0;
        NSUInteger nReturned = 0;
        for ( PFUser* user in usersThisDay )
            if ( [user objectForKey:@"messageCounts"] )
            {
                nOpenedProfile++;
                Boolean bConversationStarted = FALSE;
                NSDictionary* messageCounts = [user objectForKey:@"messageCounts"];
                for ( NSString* strKey in [messageCounts allKeys] )
                {
                    NSNumber* nCount = [messageCounts objectForKey:strKey];
                    if ( [nCount integerValue] > 0 )
                    {
                        nGotMessages++;
                        bConversationStarted = TRUE;
                        break;
                    }
                }
                if ( bConversationStarted )
                    if ( [user.updatedAt compare:[NSDate dateWithTimeInterval:7*86400 sinceDate:user.createdAt]] == NSOrderedDescending)
                        nReturned++;
            }
        [c2.points addObject:[NSNumber numberWithInt:nOpenedProfile]];
        [c3.points addObject:[NSNumber numberWithInt:nGotMessages]];
        [c4.points addObject:[NSNumber numberWithInt:nReturned]];
        
        [cc1.points addObject:[NSNumber numberWithFloat:(float)nOpenedProfile*100.0f/(float)usersThisDay.count]];
        [cc2.points addObject:[NSNumber numberWithFloat:(float)nGotMessages*100.0f/(float)usersThisDay.count]];
        [cc3.points addObject:[NSNumber numberWithFloat:(float)nReturned*100.0f/(float)usersThisDay.count]];
        
        //currentDate = [currentDate dateByAddingTimeInterval:86400];
    }
    chart1.components = [NSMutableArray arrayWithObjects:c1, c2, c3, c4, nil];
    chart1.interval = chart1.maxValue / 5.0f;
    chart2.components = [NSMutableArray arrayWithObjects:cc1, cc2, cc3, nil];
    chart2.interval = 20.0f;
    
    [self.view addSubview:chart1];
    [self.view addSubview:chart2];
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
