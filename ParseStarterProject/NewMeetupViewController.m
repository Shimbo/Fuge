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
        _meetup = nil;
        invitee = nil;
        inviteController = nil;
        self.navigationItem.leftItemsSupplementBackButton = true;
    }
    return self;
}

-(void) setMeetup:(Meetup*)m
{
    _meetup = m;
}

-(void) setInvitee:(Person*)i
{
    invitee = i;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Meetup";
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
    
    if ( ! self.selectedVenue && ! _meetup )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:@"Please, select a venue for the meetup using the big and noticeable button!" delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return NO;
    }
    return YES;
}



-(void)populateMeetupWithData:(Meetup*)meetup{
    meetup.strOwnerId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    meetup.strOwnerName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    meetup.strSubject = subject.text;
    meetup.privacy = notifySwitch.isOn;
    meetup.dateTime = [dateTime date];
    [meetup populateWithVenue:self.selectedVenue];
}

-(void)save{
    if (![self validateForm])
        return;
    [self populateMeetupWithData:_meetup];
    [_meetup save];
    [globalData  createCommentForMeetup:_meetup
                                  isNew:NO];
    [self.navigationController pushViewController:inviteController animated:YES];
}

- (void)next {
    if (![self validateForm])
        return;

    _meetup = [[Meetup alloc] init];
    [self populateMeetupWithData:_meetup];
    //we will save metup in invitation screen
    


    if (!inviteController)
        inviteController = [[MeetupInviteViewController alloc]init];
    
    // Add invitee if this window was ivoked from user profile
    if ( invitee )
        [inviteController addInvitee:invitee];
    [inviteController setMeetup:_meetup];
    [self.navigationController pushViewController:inviteController animated:YES];
    
        // Adding invite to user's calendar
        
//    }
//    [self dismissViewControllerAnimated:NO completion:nil];
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
