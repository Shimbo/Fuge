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
    }
    return self;
}

- (void)declineClicked
{
    if ( ! invite )
        return;
    NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_DECLINED];
    [invite setObject:inviteStatus forKey:@"status"];
    [invite saveInBackground];
    //[self.delegate dismissMeetup];
    //[self.navigationController popViewControllerAnimated:TRUE];
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

- (void)joinClicked
{
    // Chaning join button to leave and adding addToCalendar
    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithTitle:@"Leave" style:UIBarButtonItemStyleBordered target:self action:@selector(leaveClicked)],
                                                [[UIBarButtonItem alloc] initWithTitle:@"Add to calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(calendarClicked)]];
    
    // Creating attendee in db
    PFObject* attendee = [[PFObject alloc] initWithClassName:@"Attendee"];
    NSString* strUserId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    NSString* strUserName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    NSString* strMeetupId = meetup.strId;
    [attendee setObject:strUserId forKey:@"userId"];
    [attendee setObject:strUserName forKey:@"userName"];
    [attendee setObject:strMeetupId forKey:@"meetupId"];
    [attendee saveInBackground];
    
    // Creating comment about joining in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_JOINED commentText:nil];
    
    // Add comment to the text field
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    [stringComments appendString:comments.text];
    [stringComments appendString:@"    You joined the event!\n"];
    [comments setText:stringComments];
    
    // TODO: push notification
    
    // Accepting invite if it was
    if ( invite )
    {
        NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_ACCEPTED];
        [invite setObject:inviteStatus forKey:@"status"];
        [invite saveInBackground];
    }
    
    // Ask to add to calendar
    [meetup addToCalendar:self shouldAlert:true];
    
    // Auto subscribe
    [self subscribeClicked];
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
    return;
}

- (void)cancelClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Under construction!" message:@"Canceling meetups is not implemented yet." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
    [message show];
    return;
}

- (void)subscribeClicked
{
    [globalData subscribeToThread:meetup.strId];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Unsubscribe" style:UIBarButtonItemStylePlain target:self action:@selector(unsubscribeClicked)]];
}

- (void)unsubscribeClicked
{
    [globalData unsubscribeToThread:meetup.strId];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Subscribe" style:UIBarButtonItemStylePlain target:self action:@selector(subscribeClicked)]];
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
    
    self.title = meetup.strSubject;
    
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
    UIBarButtonItem *calendarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Add to calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(calendarClicked)];
    
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
                if ( invite )   // Window opened from invite
                    [self.navigationItem setRightBarButtonItems:@[joinBtn,declineBtn]];
                else
                    [self.navigationItem setRightBarButtonItem:joinBtn];
            }
            else    // Attending already
            {
                if ( ! [meetup addedToCalendar] )
                    [self.navigationItem setRightBarButtonItems:@[leaveBtn, calendarBtn]];
                else
                    [self.navigationItem setRightBarButtonItem:leaveBtn];
                
                [self.navigationItem setLeftBarButtonItems:@[subscribeBtn,inviteBtn]];
            }
        }];
    }
    else
    {        
        if ( ! [meetup addedToCalendar] )
            [self.navigationItem setRightBarButtonItems:@[cancelBtn,editBtn,calendarBtn]];
        else
            [self.navigationItem setRightBarButtonItems:@[cancelBtn,editBtn]];
        
        [self.navigationItem setLeftBarButtonItem:inviteBtn];
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
            NSString* strSystem = [comment objectForKey:@"system"];
            NSString* strUserName = [comment objectForKey:@"userName"];
            if ( ! strSystem || [strSystem compare:@""] == NSOrderedSame )   // Not system comment
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
        if ( [commentsList count] > 0 )
            [globalData updateConversationDate:((PFObject*)commentsList[0]).createdAt thread:meetup.strId];
    }];
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
    
    // Auto subscription
    [self subscribeClicked];
}


@end