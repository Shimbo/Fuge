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

@implementation MeetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.leftItemsSupplementBackButton = true;
    }
    return self;
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
    PFObject* comment = [[PFObject alloc] initWithClassName:@"Comment"];
    NSMutableString* strComment = [[NSMutableString alloc] initWithFormat:@""];
    [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
    [strComment appendString:@" joined the event."];
    [comment setObject:strUserId forKey:@"userId"];
    NSNumber* trueNum = [[NSNumber alloc] initWithBool:true];
    [comment setObject:[trueNum stringValue] forKey:@"system"];
    [comment setObject:strUserName forKey:@"userName"];
    [comment setObject:strMeetupId forKey:@"meetupId"];
    [comment setObject:strComment forKey:@"comment"];
    [comment saveInBackground];
    
    // Add comment to the text field
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    [stringComments appendString:comments.text];
    [stringComments appendString:@"    You joined the event!\n"];
    [comments setText:stringComments];
    
    // TODO: push notification
    
    // Ask to add to calendar
    [meetup addToCalendar:self shouldAlert:true];
    
    // Auto subscribe
    [self subscribeClicked];
}

- (void)editClicked
{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupView" bundle:nil];
    [newMeetupViewController setMeetup:meetup];
    [self.navigationController presentViewController:newMeetupViewController animated:YES completion:nil];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    // Join button checks
    if ( [meetup.strOwnerId compare:[[PFUser currentUser] objectForKey:@"fbId"] ] != NSOrderedSame )
    {
        PFQuery *meetupAnyQuery = [PFQuery queryWithClassName:@"Attendee"];
        [meetupAnyQuery whereKey:@"userId" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
        [meetupAnyQuery whereKey:@"meetupId" equalTo:meetup.strId];
        [meetupAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *attendees, NSError* error)
        {
            if ( [attendees count] == 0 )
                [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Join" style:UIBarButtonItemStylePlain target:self action:@selector(joinClicked)]];
            else
            {
                if ( ! [meetup addedToCalendar] )
                {
                    self.navigationItem.rightBarButtonItems = @[
                                                                [[UIBarButtonItem alloc] initWithTitle:@"Leave" style:UIBarButtonItemStyleBordered target:self action:@selector(leaveClicked)],
                                                                [[UIBarButtonItem alloc] initWithTitle:@"Add to calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(calendarClicked)]];
                }
                else
                {
                    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Leave" style:UIBarButtonItemStylePlain target:self action:@selector(leaveClicked)]];
                }
                
                if ( [globalData isSubscribedToThread:meetup.strId])
                    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Unsubscribe" style:UIBarButtonItemStylePlain target:self action:@selector(unsubscribeClicked)]];
                else
                    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Subscribe" style:UIBarButtonItemStylePlain target:self action:@selector(subscribeClicked)]];
            }
        }];
    }
    else
    {
        if ( ! [meetup addedToCalendar] )
        {
            self.navigationItem.rightBarButtonItems = @[
                                                    [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelClicked)],
                                                    [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editClicked)],
                                                    [[UIBarButtonItem alloc] initWithTitle:@"Add to calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(calendarClicked)]];
        }
        else
        {
            self.navigationItem.rightBarButtonItems = @[
                                                        [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelClicked)],
                                                        [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editClicked)]];
        }
    }
    
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
            if ( ! strSystem || [strSystem compare:@""] != NSOrderedSame )   // System comment like join
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

- (void)viewDidUnload {
    comments = nil;
    newComment = nil;
    mapView = nil;
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
    NSString* strUserId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    NSString* strUserName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    NSString* strMeetupId = meetup.strId;
    PFObject* comment = [[PFObject alloc] initWithClassName:@"Comment"];
    [comment setObject:strUserId forKey:@"userId"];
    [comment setObject:strUserName forKey:@"userName"];
    [comment setObject:strMeetupId forKey:@"meetupId"];
    [comment setObject:newComment.text forKey:@"comment"];
    [comment save];
    
    // Adding comment to the list
    NSMutableString* stringComments = [[NSMutableString alloc] initWithString:comments.text];
    [stringComments appendString:@"    "];
    [stringComments appendString:strUserName];
    [stringComments appendString:@": "];
    [stringComments appendString:newComment.text];
    [stringComments appendString:@"\n"];
    [comments setText:stringComments];
    
    [newComment setText:@""];
    
    // Auto subscription
    [self subscribeClicked];
}


@end