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
#import "LocationManager.h"

@implementation NewMeetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _meetup = nil;
        invitee = nil;
        self.navigationItem.leftItemsSupplementBackButton = true;
    }
    return self;
}

-(void) setMeetup:(Meetup*)m
{
    _meetup = m;
    meetupType = m.meetupType;
}

-(void) setInvitee:(Person*)i
{
    invitee = i;
}

-(void) setType:(NSUInteger)t
{
    meetupType = t;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Title
    if ( meetupType == TYPE_MEETUP )
        self.title = @"Meetup";
    else
        self.title = @"Thread";
    
    // Navigation
    [self.navigationController setNavigationBarHidden:false animated:false];
    [self.navigationItem setHidesBackButton:false animated:false];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonDown)]];
    
    //UIBarButtonItem *invite = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:self action:@selector(invite)];
    UIBarButtonItem *button = nil;
    if (_meetup) {
        button = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    }else{
        button = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(next)];
        
    }
    [self.navigationItem setRightBarButtonItem:button];
    
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
    
    if ( _meetup )
    {
        [dateTime setDate:_meetup.dateTime];
        [subject setText:_meetup.strSubject];
        [notifySwitch setOn:_meetup.privacy];
        [location setTitle:_meetup.strVenue forState:UIControlStateNormal];
    }
    else
    {
        if ( meetupType == TYPE_MEETUP )
            [dateTime setDate:dateDefault];
        else
            [dateTime setDate:dateMax];
        if ( invitee )
            [notifySwitch setOn:TRUE];
    }
    
    if ( meetupType == TYPE_THREAD )
        dateTime.hidden = TRUE;
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

/*-(void)invite{
    if (!inviteController)
        inviteController = [[MeetupInviteViewController alloc]init];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:inviteController];
    [self presentViewController:nav animated:YES completion:nil];
}*/

-(BOOL)validateForm{
    if ( subject.text.length == 0 )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:@"Please, enter the subject of the meetup in the text above!" delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return NO;
    }
    
    if ( ! self.selectedVenue && ! _meetup && ! [locManager getPosition] )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:@"We were unable to retrieve your current location, please, select a venue for the meetup." delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return NO;
    }
    return YES;
}



-(void)populateMeetupWithData:(Meetup*)meetup{
    meetup.meetupType = meetupType;
    meetup.strOwnerId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    meetup.strOwnerName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    meetup.strSubject = subject.text;
    meetup.privacy = notifySwitch.isOn;
    meetup.dateTime = [dateTime date];
    
    if ( self.selectedVenue )
        [meetup populateWithVenue:self.selectedVenue];
    else
        [meetup populateWithCoords];
}

-(void)save{
    if (![self validateForm])
        return;
    
    // Saving meetup on server
    [self populateMeetupWithData:_meetup];
    [_meetup save];
    
    // Creating comment
    [globalData createCommentForMeetup:_meetup commentType:COMMENT_SAVED commentText:nil];
}

- (void)next {
    if (![self validateForm])
        return;
    
    // Saving meetup on server
    _meetup = [[Meetup alloc] init];
    [self populateMeetupWithData:_meetup];
    [_meetup save];
    
    // Adding to the list on client and creating comment
    [globalData addMeetup:_meetup];
    [globalData createCommentForMeetup:_meetup commentType:COMMENT_CREATED commentText:nil];
    
    // Invites
    MeetupInviteViewController *inviteController = [[MeetupInviteViewController alloc]init];
    if ( invitee ) // Add invitee if this window was ivoked from user profile
        [inviteController addInvitee:invitee];
    [inviteController setMeetup:_meetup newMeetup:true];
    [self.navigationController pushViewController:inviteController animated:YES];
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
