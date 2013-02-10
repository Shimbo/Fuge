//
//  NewEventViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import "NewMeetupViewController.h"
#import "VenueSelectViewController.h"
#import <Parse/Parse.h>
#import "FSVenue.h"
#import "GlobalData.h"

@implementation NewMeetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        meetup = nil;
    }
    return self;
}

-(void) setMeetup:(Meetup*)m
{
    meetup = m;
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
    
    
    [dateTime setMinimumDate:dateMin];
    [dateTime setMaximumDate:dateMax];
    
    if ( meetup )
    {
        [dateTime setDate:meetup.dateTime];
        [subject setText:meetup.strSubject];
        [privacy setSelectedSegmentIndex:meetup.privacy];
        [location setTitle:meetup.strVenue forState:UIControlStateNormal];
        [createButton setTitle:@"Save" forState:UIControlStateNormal];
    }
    else
        [dateTime setDate:dateDefault];
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
    createButton = nil;
    [super viewDidUnload];
}

- (IBAction)cancelButtonDown:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:false animated:true];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)createButtonDown:(id)sender {
    
    Boolean newMeetup = meetup ? false : true;
    
    if ( subject.text.length == 0 )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:@"Please, enter the subject of the meetup in the text above!" delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
    
    if ( ! self.selectedVenue && ! meetup )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:@"Please, select a venue for the meetup using the big and noticeable button!" delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
    
    // Meetup creation
    if ( ! meetup )
        meetup = [[Meetup alloc] init];
    meetup.strOwnerId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    meetup.strOwnerName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    meetup.strSubject = subject.text;
    meetup.privacy = [privacy selectedSegmentIndex];
    meetup.dateTime = [dateTime date];
    if ( self.selectedVenue )
    {
        meetup.location = [PFGeoPoint geoPointWithLatitude:[self.selectedVenue.lat doubleValue]
                                                  longitude:[self.selectedVenue.lon doubleValue]];
        meetup.strVenue = self.selectedVenue.name;
        if ( self.selectedVenue.address )
            meetup.strAddress = self.selectedVenue.address;
        if ( self.selectedVenue.city )
        {
            meetup.strAddress = [meetup.strAddress stringByAppendingString:@" "];
            meetup.strAddress = [meetup.strAddress stringByAppendingString:self.selectedVenue.city];
        }
        if ( self.selectedVenue.state )
        {
            meetup.strAddress = [meetup.strAddress stringByAppendingString:@" "];
            meetup.strAddress = [meetup.strAddress stringByAppendingString:self.selectedVenue.state];
        }
        if ( self.selectedVenue.postalCode )
        {
            meetup.strAddress = [meetup.strAddress stringByAppendingString:@" "];
            meetup.strAddress = [meetup.strAddress stringByAppendingString:self.selectedVenue.postalCode];
        }
        if ( self.selectedVenue.country )
        {
            meetup.strAddress = [meetup.strAddress stringByAppendingString:@" "];
            meetup.strAddress = [meetup.strAddress stringByAppendingString:self.selectedVenue.country];
        }
    }
    [meetup save];
    
    // Adding to our own meetup list
    [globalData addMeetup:meetup];
    
    // Creating comment about meetup creation in db
    PFObject* comment = [[PFObject alloc] initWithClassName:@"Comment"];
    NSMutableString* strComment = [[NSMutableString alloc] initWithFormat:@""];
    [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
    if ( newMeetup )
    {
        [strComment appendString:@" created the meetup: "];
        [strComment appendString:subject.text];
    }
    else
        [strComment appendString:@" changed meetup details."];
    [comment setObject:meetup.strOwnerId forKey:@"userId"];
    [comment setObject:@"" forKey:@"userName"]; // As it's not a normal comment, it's ok
    [comment setObject:meetup.strId forKey:@"meetupId"];
    [comment setObject:strComment forKey:@"comment"];
    [comment saveInBackground];
    
    // TODO: Send to everybody around (using public/2ndO filter, send checkbox and geo-query) push about the meetup
    
    // Add to calendar call
    [meetup addToCalendar:self shouldAlert:newMeetup];
    
    // Close the window
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController setNavigationBarHidden:false animated:true];
    [self.navigationController popViewControllerAnimated:YES];
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
