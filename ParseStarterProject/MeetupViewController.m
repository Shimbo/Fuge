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

@implementation MeetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)joinClicked
{
    // Hiding join button and adding addToCalendar
    // TODO: change join to leave, don't hide!
    [self.navigationItem setRightBarButtonItem:nil];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Add to calendar" style:UIBarButtonItemStylePlain target:self action:@selector(calendarClicked)]];
    
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
    [comment setObject:@"" forKey:@"userName"]; // As it's not a normal comment, it's ok
    [comment setObject:strMeetupId forKey:@"meetupId"];
    [comment setObject:strComment forKey:@"comment"];
    [comment saveInBackground];
    
    // Add comment to the text field
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    [stringComments appendString:comments.text];
    [stringComments appendString:@"    You joined the event!\n"];
    [comments setText:stringComments];
    
    // TODO: push notification
}

- (void)editClicked
{
    NewMeetupViewController *newEventViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupView" bundle:nil];
    [newEventViewController setMeetup:meetup];
    [self.navigationController setNavigationBarHidden:true animated:true];
    [self.navigationController pushViewController:newEventViewController animated:YES];
}

- (void)presentEventEditViewControllerWithEventStore:(EKEventStore*)eventStore
{
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    event.title     = [meetup.strSubject stringByAppendingFormat:@" at %@", meetup.strVenue];
    event.startDate = meetup.dateTime;
    event.endDate   = [[NSDate alloc] initWithTimeInterval:3600 sinceDate:event.startDate];
    event.location = meetup.strAddress;
    
    /*EKCalendarChooser* chooser = [[EKCalendarChooser alloc] initWithSelectionStyle:EKCalendarChooserSelectionStyleSingle displayStyle:EKCalendarChooserDisplayWritableCalendarsOnly entityType:EKEntityTypeEvent eventStore:eventStore];
     
    [self.navigationController pushViewController:chooser animated:YES];*/
    
    EKEventEditViewController* eventView = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
    [eventView setEventStore:eventStore];
    [eventView setEvent:event];
    
    [self presentModalViewController:eventView animated:YES];
    eventView.editViewDelegate = self;
    
//    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
//    NSError *err;
//    [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
}

#pragma mark -
#pragma mark EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions.
- (void)eventEditViewController:(EKEventEditViewController *)controller
          didCompleteWithAction:(EKEventEditViewAction)action {
    
    NSError *error = nil;
    EKEvent *thisEvent = controller.event;
    
    switch (action) {
        case EKEventEditViewActionCanceled:
            break;
            
        case EKEventEditViewActionSaved:
            [controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
            break;
            
        case EKEventEditViewActionDeleted:
            [controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
            break;
            
        default:
            break;
    }
    // Dismiss the modal view controller
    [controller dismissModalViewControllerAnimated:YES];
}


// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
/*- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller {
    //EKCalendar *calendarForEdit = self.defaultCalendar;
    return calendarForEdit;
}*/

- (void)calendarClicked
{
    // TODO: hide add to calendar, but for both cases: join/edit (keep edit in the second)
    
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    // iOS 6 introduced a requirement where the app must
    // explicitly request access to the user's calendar. This
    // function is built to support the new iOS 6 requirement,
    // as well as earlier versions of the OS.
    if([eventStore respondsToSelector:
        @selector(requestAccessToEntityType:completion:)]) {
        // iOS 6 and later
        [eventStore
         requestAccessToEntityType:EKEntityTypeEvent
         completion:^(BOOL granted, NSError *error) {
             // If you don't perform your presentation logic on the
             // main thread, the app hangs for 10 - 15 seconds.
             [self performSelectorOnMainThread:
              @selector(presentEventEditViewControllerWithEventStore:)
                                    withObject:eventStore
                                 waitUntilDone:NO];
         }];
    } else {
        // iOS 5
        [self presentEventEditViewControllerWithEventStore:eventStore];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
            else if ( TRUE ) // TODO: check if meetup is already added to calendar
            {
                [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Add to calendar" style:UIBarButtonItemStylePlain target:self action:@selector(calendarClicked)]];
            }
        }];
    }
    else
    {
        //[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editClicked)]];
        
        // TODO: check if already added to calendar, if so, use code above
        self.navigationItem.rightBarButtonItems = @[
                                                    [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editClicked)],
                                                    [[UIBarButtonItem alloc] initWithTitle:@"Add to calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(calendarClicked)]];
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
            NSString* strUserName = [comment objectForKey:@"userName"];
            if ( [strUserName compare:@""] != NSOrderedSame )   // System comment like join
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

// TODO: add join button
// TODO: add join mechanics (attendee class and list in db)
// TODO: use owner and subject as first comment.
// TODO: add joins as comments (except of owner)
// TODO: support actuall comments

- (void)viewDidUnload {
    comments = nil;
    newComment = nil;
    [super viewDidUnload];
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
}


@end