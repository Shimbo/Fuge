//
//  MeetupViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "MeetupViewController.h"
#import <Parse/Parse.h>
#import "NewMeetupViewController.h"
#import "GlobalData.h"
#import "MeetupAnnotation.h"
#import "MeetupInviteViewController.h"

@implementation MeetupViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        meetup = nil;
        invite = nil;
        self.navigationItem.leftItemsSupplementBackButton = true;
        buttons = [[NSMutableArray alloc] init];
        for ( int n = 0; n < MB_TOTAL_COUNT; n++ )
            [buttons addObject:[NSNumber numberWithInt:0]];
        newComment.editable = false;
    }
    return self;
}

- (void)updateButtons
{
    // Buttons
    UIBarButtonItem *joinBtn = [[UIBarButtonItem alloc] initWithTitle:@"Join" style:UIBarButtonItemStyleBordered target:self action:@selector(joinClicked)];
    UIBarButtonItem *declineBtn = [[UIBarButtonItem alloc] initWithTitle:@"Decline" style:UIBarButtonItemStyleBordered target:self action:@selector(declineClicked)];
    UIBarButtonItem *leaveBtn = [[UIBarButtonItem alloc] initWithTitle:@"Leave" style:UIBarButtonItemStyleBordered target:self action:@selector(leaveClicked)];
    
    UIBarButtonItem *subscribeBtn;
    if ( [globalData isSubscribedToThread:meetup.strId])
        subscribeBtn = [[UIBarButtonItem alloc] initWithTitle:@"Unsubscribe" style:UIBarButtonItemStylePlain target:self action:@selector(unsubscribeClicked)];
    else
        subscribeBtn = [[UIBarButtonItem alloc] initWithTitle:@"Subscribe" style:UIBarButtonItemStylePlain target:self action:@selector(subscribeClicked)];
    UIBarButtonItem *inviteBtn = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:self action:@selector(inviteClicked)];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelClicked)];
    UIBarButtonItem *editBtn = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editClicked)];
    UIBarButtonItem *calendarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Calendar-Day"] style:UIBarButtonItemStyleBordered  target:self action:@selector(calendarClicked)];
    
    NSMutableArray* actualButtons = [[NSMutableArray alloc] init];
    if ( [buttons[MB_JOIN] integerValue] != 0 )
        [actualButtons addObject:joinBtn];
    if ( [buttons[MB_SUBSCRIBE] integerValue] != 0 )
        [actualButtons addObject:subscribeBtn];
    if ( [buttons[MB_DECLINE] integerValue] != 0 )
        [actualButtons addObject:declineBtn];
    if ( [buttons[MB_LEAVE] integerValue] != 0 )
        [actualButtons addObject:leaveBtn];
    if ( [buttons[MB_CALENDAR] integerValue] != 0 )
        [actualButtons addObject:calendarBtn];
    if ( [buttons[MB_INVITE] integerValue] != 0 )
        [actualButtons addObject:inviteBtn];
    if ( [buttons[MB_CANCEL] integerValue] != 0 )
        [actualButtons addObject:cancelBtn];
    if ( [buttons[MB_EDIT] integerValue] != 0 )
        [actualButtons addObject:editBtn];
    
    [self.navigationItem setRightBarButtonItems:actualButtons];
    
    // We fixed it by chenging the whole mechanics
    /*if([[self.navigationController viewControllers] objectAtIndex:0] == self){
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc]
                                                   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                   target:self
                                                   action:@selector(cancelButtonDown)]];
    }*/
}

/*- (void)cancelButtonDown {
    [self dismissViewControllerAnimated:YES completion:nil];
}*/

- (void)declineClicked
{
    if ( ! invite )
        return;
    NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_DECLINED];
    [invite setObject:inviteStatus forKey:@"status"];
    [invite saveInBackground];
    //[self dismissViewControllerAnimated:TRUE completion:nil];
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (void)joinClicked
{    
    // Creating attendee in db
    PFObject* attendee = [[PFObject alloc] initWithClassName:@"Attendee"];
    NSString* strUserId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    NSString* strUserName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    [attendee setObject:strUserId forKey:@"userId"];
    [attendee setObject:strUserName forKey:@"userName"];
    [attendee setObject:meetup.strId forKey:@"meetupId"];
    [attendee setObject:meetup.meetupData forKey:@"meetupData"];
    [attendee saveInBackground];
    
    // Creating comment about joining in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_JOINED commentText:nil];
    
    // Add comment to the text field
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    [stringComments appendString:comments.text];
    [stringComments appendString:@"    You joined the event!\n"];
    [comments setText:stringComments];
    
    // Add to attending list
    [globalData attendMeetup:meetup.strId];
    
    // TODO: push notification
    
    // Accepting invite if it was
    if ( invite )
    {
        NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_ACCEPTED];
        [invite setObject:inviteStatus forKey:@"status"];
        [invite saveInBackground];
        //[self dismissViewControllerAnimated:TRUE completion:nil];
        [self.navigationController popViewControllerAnimated:TRUE];
    }
    else
    {
        // Chaning join button to leave and adding addToCalendar
        buttons[MB_JOIN] = [NSNumber numberWithInt:0];
        buttons[MB_LEAVE] = [NSNumber numberWithInt:1];
        buttons[MB_CALENDAR] = [NSNumber numberWithInt:1];
        [self updateButtons];
    }
    
    // Ask to add to calendar
    [meetup addToCalendar:self shouldAlert:true];
}

- (void)editClicked
{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupView" bundle:nil];
    [newMeetupViewController setMeetup:meetup];
    
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (void)calendarClicked
{
    [meetup addToCalendar:self shouldAlert:true];
    return;
}

- (void)leaveClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Under construction!" message:@"Leaving meetups is not implemented yet." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
    [message show];
    
    // TODO:
    // Remove from attending list
    //[globalData unattendMeetup:meetup.strId];

    return;
}

- (void)cancelClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Under construction!" message:@"Canceling meetups is not implemented yet." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
    [message show];
    
    // TODO:
    // Remove from attending list
    //[globalData unattendMeetup:meetup.strId];
    
    return;
}

- (void)subscribeClicked
{
    [globalData subscribeToThread:meetup.strId];
    
    // Accepting invite and closing window if it was
    if ( invite )
    {
        NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_ACCEPTED];
        [invite setObject:inviteStatus forKey:@"status"];
        [invite saveInBackground];
        //[self dismissViewControllerAnimated:TRUE completion:nil];
        [self.navigationController popViewControllerAnimated:TRUE];
    }
    else
        [self updateButtons];
}

- (void)unsubscribeClicked
{
    [globalData unsubscribeToThread:meetup.strId];
    
    if ( invite )
        //[self dismissViewControllerAnimated:TRUE completion:nil];
        [self.navigationController popViewControllerAnimated:TRUE];
    else
        [self updateButtons];
}

-(void)inviteClicked
{
    MeetupInviteViewController *inviteController = [[MeetupInviteViewController alloc]init];
    [inviteController setMeetup:meetup newMeetup:false];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inviteController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"";//meetup.strSubject;
    
    // Map
    CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(meetup.location.latitude,meetup.location.longitude);
    MKCoordinateRegion reg = MKCoordinateRegionMakeWithDistance(loc, 200.0f, 200.0f);
    mapView.showsUserLocation = TRUE;
    [mapView setDelegate:self];
    [mapView setRegion:reg animated:true];
    MeetupAnnotation *ann = [[MeetupAnnotation alloc] init];
    NSUInteger color;
    switch (meetup.privacy)
    {
        case 0: color = MKPinAnnotationColorGreen; break;
        case 1: color = MKPinAnnotationColorPurple; break;
        case 2: color = MKPinAnnotationColorRed; break;
    }
    ann.title = meetup.strVenue;
    ann.subtitle = meetup.strAddress;
    ann.color = color;
    CLLocationCoordinate2D coord;
    coord.latitude = meetup.location.latitude;
    coord.longitude = meetup.location.longitude;
    ann.coordinate = coord;
    [mapView addAnnotation:ann];
    
    NSNumber* buttonOn = [NSNumber numberWithInt:1];
    
    // Own meetup or not
    if ( [meetup.strOwnerId compare:strCurrentUserId ] != NSOrderedSame )
    {
        PFQuery *meetupAnyQuery = [PFQuery queryWithClassName:@"Attendee"];
        [meetupAnyQuery whereKey:@"userId" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
        [meetupAnyQuery whereKey:@"meetupId" equalTo:meetup.strId];
        [meetupAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *attendees, NSError* error)
        {
            if ( [attendees count] == 0 )   // Not attending yet
            {
                if ( meetup.meetupType == TYPE_MEETUP )
                    buttons[MB_JOIN] = buttonOn;
                else
                    buttons[MB_SUBSCRIBE] = buttonOn;
                
                if ( invite )   // Window opened from invite
                    buttons[MB_DECLINE] = buttonOn;
            }
            else    // Attending already
            {
                if ( meetup.meetupType == TYPE_THREAD )
                    buttons[MB_SUBSCRIBE] = buttonOn;
                buttons[MB_INVITE] = buttonOn;
                
                if ( meetup.meetupType == TYPE_MEETUP )
                {
                    buttons[MB_LEAVE] = buttonOn;
                    if ( ! [meetup addedToCalendar] )
                        buttons[MB_CALENDAR] = buttonOn;
                }
            }
            
            [self updateButtons];
        }];
    }
    else
    {
        buttons[MB_CANCEL] = buttonOn;
        buttons[MB_EDIT] = buttonOn;
        buttons[MB_INVITE] = buttonOn;

        if ( ! [meetup addedToCalendar] && meetup.meetupType == TYPE_MEETUP )
            buttons[MB_CALENDAR] = buttonOn;
        
        [self updateButtons];
    }
    
    // Setting location and date labels
    [labelLocation setText:meetup.strVenue];
    NSString *dateString = [NSDateFormatter localizedStringFromDate:meetup.dateTime
                                                          dateStyle:NSDateFormatterMediumStyle
                                                          timeStyle:NSDateFormatterShortStyle];
    [labelDate setText:dateString];
    
    // Loading comments
    PFQuery *commentsQuery = [PFQuery queryWithClassName:@"Comment"];
    [commentsQuery whereKey:@"meetupId" equalTo:meetup.strId];
    [commentsQuery orderByAscending:@"createdAt"];
    [commentsQuery findObjectsInBackgroundWithBlock:^(NSArray *commentsList, NSError* error)
    {
        NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
        for (NSDictionary *comment in commentsList)
        {
            NSNumber* nSystem = [comment objectForKey:@"system"];
            NSString* strUserName = [comment objectForKey:@"userName"];
            if ( ! nSystem )   // Not system comment
            {
                [stringComments appendString:@"    "];
                [stringComments appendString:strUserName];
                [stringComments appendString:@": "];
            }
            else
            {
                [stringComments appendString:@"    "];
            }
            [stringComments appendString:[comment objectForKey:@"comment"]];
            [stringComments appendString:@"\n"];
        }
        [comments setText:stringComments];
        
        // Last read message date
        if ( meetup.numComments > 0 )
            [globalData updateConversation:((PFObject*)commentsList[0]).createdAt count:meetup.numComments thread:meetup.strId];
        
        // Make new comment editable now
        newComment.editable = true;
    }];
    
}

-(void)hideKeyBoard{
    [newComment resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setMeetup:(Meetup*)m
{
    meetup = m;
}

-(void) setInvite:(PFObject*)i
{
    invite = i;
}

- (void)viewDidUnload {
    comments = nil;
    newComment = nil;
    mapView = nil;
    labelDate = nil;
    labelLocation = nil;
    [super viewDidUnload];
}




-(MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKPinAnnotationView *pinView = nil;
    if (annotation != mapView.userLocation)
    {
        static NSString *defaultPinID = @"secondcircle.pin";
        pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
        
        if ( pinView == nil ){
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
        }
        
        pinView.pinColor = ((MeetupAnnotation*) annotation).color;
        
        pinView.canShowCallout = YES;
        pinView.animatesDrop = YES;
    }
    else {
        [mapView.userLocation setTitle:@"I am here"];
    }
    return pinView;
}






static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 162;

double animatedDistance;

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    CGRect textFieldRect = [self.view.window convertRect:textView.bounds
                                                fromView:textView];
    CGRect viewRect = [self.view.window convertRect:self.view.bounds
                                           fromView:self.view];
    
    CGFloat midline = textFieldRect.origin.y + 0.5
    * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y
    - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION)
    * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    
    if (heightFraction < 0.0)
    {
        heightFraction = 0.0;
    }
    else if (heightFraction > 1.0)
    {
        heightFraction = 1.0;
    }
    
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT * heightFraction);
    }
    else
    {
        animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    }
    
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y -= animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
	if ( [ text isEqualToString: @"\n" ] )
    {
        [ textView resignFirstResponder ];
        return NO;
    }
    return YES;
}

- (void) textViewDidEndEditing:(UITextView *)textView
{
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y += animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
    
    if ( [newComment.text compare:@""] == NSOrderedSame )
        return;
    
    // Creating comment in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_PLAIN commentText:newComment.text];
    
    // Adding comment to the list
    NSMutableString* stringComments = [[NSMutableString alloc] initWithString:comments.text];
    [stringComments appendString:@"    "];
    [stringComments appendString:strCurrentUserName];
    [stringComments appendString:@": "];
    [stringComments appendString:newComment.text];
    [stringComments appendString:@"\n"];
    [comments setText:stringComments];
    
    [newComment setText:@""];    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [newComment resignFirstResponder];
}
@end