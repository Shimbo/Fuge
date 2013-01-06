//
//  NewEventViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import "NewEventViewController.h"
#import <Parse/Parse.h>

@interface NewEventViewController ()

@end

@implementation NewEventViewController

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
    
    NSDate* dateNow = [NSDate date];
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    [deltaComps setDay:7];
    NSDate* dateThen = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:[NSDate date] options:0];
    
    [dateTime setMinimumDate:dateNow];
    [dateTime setMaximumDate:dateThen];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    dateTime = nil;
    privacy = nil;
    subject = nil;
    notifySwitch = nil;
    location = nil;
    [super viewDidUnload];
}

- (IBAction)cancelButtonDown:(id)sender {
    [self.navigationController setNavigationBarHidden:false animated:true];
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (IBAction)createButtonDown:(id)sender {
    // TODO: Check if place was set up
    // TODO: Check if subject is not empty (in case of public or 2ndO types at least)
    
    // Meetup creation
    PFObject* meetup = [[PFObject alloc] initWithClassName:@"Meetup"];
    NSString* stringFromId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    NSString* stringFromName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    [meetup setObject:stringFromId forKey:@"userFromId"];
    [meetup setObject:stringFromName forKey:@"userFromName"];
    [meetup setObject:subject.text forKey:@"subject"];
    [meetup setObject:[NSNumber numberWithInt:[privacy selectedSegmentIndex]] forKey:@"privacy"];
    [meetup setObject:[dateTime date] forKey:@"meetupDate"];
    NSNumber* timestamp = [[NSNumber alloc] initWithDouble:[[dateTime date] timeIntervalSince1970]];
    [meetup setObject:timestamp forKey:@"meetupTimestamp"];
    NSString* strMeetupId = [[NSString alloc] initWithFormat:@"%d_%@", [timestamp integerValue], stringFromId];
    [meetup setObject:strMeetupId forKey:@"meetupId"];
    
    // TODO: actual location!
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:37//coord.latitude
                                                  longitude:48];//coord.longitude];
    [meetup setObject:geoPoint forKey:@"location"];
    
    [meetup setObject:[NSNumber numberWithBool:FALSE] forKey:@"isRead"];
    [meetup save];
    
    // TODO: Send to everybody around (using public/2ndO filter, send checkbox and geo-query) push about the meetup
    
    [self.navigationController setNavigationBarHidden:false animated:true];
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [subject resignFirstResponder];
    return true;
}

@end
