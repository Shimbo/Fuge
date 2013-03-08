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
#import "MeetupInviteViewController.h"
@implementation NewMeetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        meetup = nil;
        invitee = nil;
        self.navigationItem.leftItemsSupplementBackButton = true;
    }
    return self;
}

-(void) setMeetup:(Meetup*)m
{
    meetup = m;
}

-(void) setInvitee:(PFUser*)i
{
    invitee = i;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Navigation
    [self.navigationController setNavigationBarHidden:false animated:false];
    [self.navigationItem setHidesBackButton:false animated:false];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonDown)]];
    
    UIBarButtonItem *invite = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:self action:@selector(invite)];
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(createButtonDown)];
    [self.navigationItem setRightBarButtonItems:@[save,invite]];
    
    // Defaults
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
        [notifySwitch setOn:meetup.privacy];
        [location setTitle:meetup.strVenue forState:UIControlStateNormal];
    }
    else
    {
        [dateTime setDate:dateDefault];
        if ( invitee )
            [notifySwitch setOn:TRUE];
    }
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

/*- (void)viewDidUnload {
    dateTime = nil;
    privacy = nil;
    subject = nil;
    notifySwitch = nil;
    location = nil;
    [super viewDidUnload];
}*/

- (void)cancelButtonDown {
    [self dismissModalViewControllerAnimated:YES];
    //[self.navigationController setNavigationBarHidden:false animated:true];
    //[self.navigationController popViewControllerAnimated:YES];
}

-(void)invite{
    if (!inviteController)
        inviteController = [[MeetupInviteViewController alloc]init];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:inviteController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)createButtonDown {
    
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
    meetup.privacy = notifySwitch.isOn;
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
    NSNumber* trueNum = [[NSNumber alloc] initWithBool:true];
    [comment setObject:[trueNum stringValue] forKey:@"system"];
    NSString* strUserName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    [comment setObject:strUserName forKey:@"userName"];
    [comment setObject:meetup.strId forKey:@"meetupId"];
    [comment setObject:strComment forKey:@"comment"];
    //comment.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
    //[comment.ACL setPublicReadAccess:true];
    
    [comment saveInBackground];
    
    // TODO: Send to everybody around (using public/2ndO filter, send checkbox and geo-query) push about the meetup
    
    // Subscription
    [globalData subscribeToThread:meetup.strId];
    
    // Close the window - why no animation? Because animations conflict!
    [self dismissViewControllerAnimated:NO completion:nil];
    //[self.navigationController popViewControllerAnimated:TRUE];
    //[self.navigationController setNavigationBarHidden:false animated:true];
    //[self.navigationController popViewControllerAnimated:NO];
    
    // Invites
    // TODO: Replace it with single window, add invitee to this window by default if specified
    if ( invitee )
    {
        [globalData createInvite:meetup objectTo:invitee stringTo:nil];
    }
    
    // Add to calendar call
    [meetup addToCalendar:self shouldAlert:newMeetup];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [subject resignFirstResponder];
    return true;
}

@end
