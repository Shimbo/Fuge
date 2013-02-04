//
//  MeetupViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "MeetupViewController.h"
#import <Parse/Parse.h>
#import "NewEventViewController.h"

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
    // Hiding join button
    [self.navigationItem setRightBarButtonItem:nil];
    
    // Creating attendee in db
    PFObject* attendee = [[PFObject alloc] initWithClassName:@"Attendee"];
    NSString* strUserId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    NSString* strUserName = (NSString *) [[PFUser currentUser] objectForKey:@"fbName"];
    NSString* strMeetupId = meetup.strId;
    [attendee setObject:strUserId forKey:@"userId"];
    [attendee setObject:strUserName forKey:@"userName"];
    [attendee setObject:strMeetupId forKey:@"meetupId"];
    [attendee save];
    
    // Creating comment about joining in db
    PFObject* comment = [[PFObject alloc] initWithClassName:@"Comment"];
    NSMutableString* strComment = [[NSMutableString alloc] initWithFormat:@""];
    [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
    [strComment appendString:@" joined the event."];
    [comment setObject:strUserId forKey:@"userId"];
    [comment setObject:@"" forKey:@"userName"]; // As it's not a normal comment, it's ok
    [comment setObject:strMeetupId forKey:@"meetupId"];
    [comment setObject:strComment forKey:@"comment"];
    [comment save];
    
    // Add comment to the text field
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    [stringComments appendString:comments.text];
    [stringComments appendString:@"    You joined the event!\n"];
    [comments setText:stringComments];
    
    // TODO: push notification
}

- (void)editClicked
{
    NewEventViewController *newEventViewController = [[NewEventViewController alloc] initWithNibName:@"NewEventView" bundle:nil];
    [newEventViewController setMeetup:meetup];
    [self.navigationController setNavigationBarHidden:true animated:true];
    [self.navigationController pushViewController:newEventViewController animated:YES];
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
        }];
    }
    else
    {
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editClicked)]];
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