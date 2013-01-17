//
//  NewEventViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import "NewEventViewController.h"
#import "VenueSelectViewController.h"
#import <Parse/Parse.h>
#import "FSVenue.h"


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

    NSDateComponents* deltaCompsMin = [[NSDateComponents alloc] init];
    [deltaCompsMin setMinute:15];
    NSDate* dateMin = [[NSCalendar currentCalendar] dateByAddingComponents:deltaCompsMin toDate:[NSDate date] options:0];
    NSDateComponents* deltaCompsDefault = [[NSDateComponents alloc] init];
    [deltaCompsDefault setMinute:30];
    NSDate* dateDefault = [[NSCalendar currentCalendar] dateByAddingComponents:deltaCompsDefault toDate:[NSDate date] options:0];
    NSDateComponents* deltaCompsMax = [[NSDateComponents alloc] init];
    [deltaCompsMax setDay:7];
    NSDate* dateMax = [[NSCalendar currentCalendar] dateByAddingComponents:deltaCompsMax toDate:[NSDate date] options:0];
    
    [dateTime setDate:dateDefault];
    [dateTime setMinimumDate:dateMin];
    [dateTime setMaximumDate:dateMax];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.selectedVenue) {
        [location setTitle:self.selectedVenue.name forState:UIControlStateNormal];
    }
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
    
    if ( subject.text.length == 0 )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:@"Please, enter the subject of the meetup in the text above!" delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
    
    if ( ! self.selectedVenue )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:@"Please, select a venue for the meetup using the big and noticeable button!" delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
    
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
    
    // Seeting actual location
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:[self.selectedVenue.lat doubleValue]
                                                  longitude:[self.selectedVenue.lon doubleValue]];
    [meetup setObject:geoPoint forKey:@"location"];
    
    [meetup setObject:[NSNumber numberWithBool:FALSE] forKey:@"isRead"];
    [meetup save];
    
    // Creating comment about meetup creation in db
    PFObject* comment = [[PFObject alloc] initWithClassName:@"Comment"];
    NSMutableString* strComment = [[NSMutableString alloc] initWithFormat:@""];
    [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
    [strComment appendString:@" created the meetup: "];
    [strComment appendString:subject.text];
    [comment setObject:stringFromId forKey:@"userId"];
    [comment setObject:@"" forKey:@"userName"]; // As it's not a normal comment, it's ok
    [comment setObject:strMeetupId forKey:@"meetupId"];
    [comment setObject:strComment forKey:@"comment"];
    [comment save];
    
    // TODO: Send to everybody around (using public/2ndO filter, send checkbox and geo-query) push about the meetup
    
    [self.navigationController setNavigationBarHidden:false animated:true];
    [self.navigationController popViewControllerAnimated:TRUE];
}


- (IBAction)venueButtonDown:(id)sender {
    if (!venueNavViewController) {
        VenueSelectViewController *venueViewController = [[VenueSelectViewController alloc] initWithNibName:@"VenueSelectView" bundle:nil];
        venueViewController.delegate = self;
        venueNavViewController = [[UINavigationController alloc]initWithRootViewController:venueViewController];
    }
    [self presentViewController:venueNavViewController
                       animated:YES completion:nil];
}

- (IBAction)notifySwitched:(id)sender {
    if ( notifySwitch.isOn && privacy.selectedSegmentIndex == 2 )
        [privacy setSelectedSegmentIndex:0];
}

- (IBAction)privacySwitched:(id)sender {
    if ( privacy.selectedSegmentIndex == 2 )
        [notifySwitch setOn:FALSE animated:TRUE];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [subject resignFirstResponder];
    return true;
}

@end
