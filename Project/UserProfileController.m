//
//  UserProfileController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/2/12.
//
//

#import <Parse/Parse.h>
#import "UserProfileController.h"
#import "PushManager.h"
#import "AsyncImageView.h"
#import "GlobalData.h"
#import "NewMeetupViewController.h"
#import "MatchesViewController.h"
#include "Message.h"

@implementation UserProfileController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"", @"");
        messagesCount = 0;
    }
    return self;
}

- (void)profileClicked{
    [Person openProfileInBrowser:personThis.strId];
}

- (void)meetClicked{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupViewController" bundle:nil];
    [newMeetupViewController setType:TYPE_MEETUP];
    [newMeetupViewController setInvitee:personThis];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithTitle:@"Meet" style:UIBarButtonItemStylePlain target:self action:@selector(meetClicked)],                                                                                                                                                                                                                 [[UIBarButtonItem alloc] initWithTitle:@"FB Profile" style:UIBarButtonItemStylePlain target:self action:@selector(profileClicked)]];
    
    
    textView.editable = FALSE;
    
    // Comments
    [globalData loadThread:personThis target:self selector:@selector(callback:error:)];
    
    //[profileImage loadImageFromURL:personThis.largeImageURL];
    
    // Avatar
    profileImageView.profileID = personThis.strId;
    profileImageView.pictureCropping = FBProfilePictureCroppingSquare;
    
    // Labels
    labelFriendName.text = [personThis fullName];
    NSString* distanceString = [personThis distanceString];
    if ( distanceString.length > 0 )
        labelDistance.text = [[NSString alloc] initWithFormat:@"%@ away", distanceString];
    else
        labelDistance.text = @"";
    labelTimePassed.text = [[NSString alloc] initWithFormat:@"%@ ago", [personThis timeString]];
    labelCircle.text = personThis.strCircle;
    nThingsInCommon = [personThis matchesTotal];
    NSString* strTitle = @"No matches";
    if ( nThingsInCommon == 1 )
        strTitle = @"See 1 match";
    else if ( nThingsInCommon > 1 )
        strTitle = [NSString stringWithFormat:@"See %d matches", nThingsInCommon];
    if ( bIsAdmin )
        strTitle = [strTitle stringByAppendingString:[NSString stringWithFormat:@"+%d", personThis.matchesAdminBonus]];
    [btnThingsInCommon setTitle:strTitle forState:UIControlStateNormal];
    
    personThis.numUnreadMessages = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) callback:(NSArray*)messages error:(NSError *)error
{
    if (error || ! messages )
    {
        [messageHistory setText:@"Messages loading failed, no connection."];
        return;
    }
    
    NSMutableString* stringHistory = [[NSMutableString alloc] initWithFormat:@""];
    
    // Messages
    for ( int n = 0; n < messages.count; n++ )
    {
        PFObject* message = messages[n];
        NSString* strText = [message objectForKey:@"text"];
        if ( [ personThis.strId compare:[ message objectForKey:@"idUserFrom"] ] == NSOrderedSame )
        {
            [stringHistory appendString:@"    "];
            [stringHistory appendString:personThis.strFirstName];
            [stringHistory appendString:@": "];
        }
        else
            [stringHistory appendString:@"    You: "];
        [stringHistory appendString:strText];
        if ( n != messages.count - 1 )
            [stringHistory appendString:@"\n"];
    }
    
    // Feedback message (always at the bottom, first one)
    if ( [globalVariables isFeedbackBot:personThis.strId] )
    {
        if ( stringHistory.length > 0 )
            [stringHistory appendString:@"\n"];
        [stringHistory appendString:@"    "];
        [stringHistory appendString:personThis.strFirstName];
        [stringHistory appendString:@": "];
        [stringHistory appendString:WELCOME_MESSAGE];
        if ( messages.count != 0 )
            [stringHistory appendString:@"\n"];
    }
    
    [messageHistory setText:stringHistory];
    messagesCount = messages.count;
    
    textView.editable = TRUE;
}

- (IBAction)showMatchesList:(id)sender {
    if ( nThingsInCommon + personThis.matchesAdminBonus == 0 )
        return;
    MatchesViewController *matchesViewController = [[MatchesViewController alloc] initWithNibName:@"MatchesViewController" bundle:nil];
    [matchesViewController setPerson:personThis];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:matchesViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

-(void) setPerson:(Person*)person
{
    personThis = person;
}



- (void)viewDidUnload {
    messageHistory = nil;
    labelDistance = nil;
    labelCircle = nil;
    [self setActivityIndicator:nil];
    profileImageView = nil;
    labelFriendName = nil;
    labelTimePassed = nil;
    btnThingsInCommon = nil;
    [super viewDidUnload];
}




/*

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

*/

- (void) callbackMessageSave:(NSNumber *)result error:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    textView.editable = YES;
    
    if ( error )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"Message send failed, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
    
    // Updating history
    NSMutableString* stringHistory = [[NSMutableString alloc] initWithFormat:@""];
    [stringHistory appendString:@"    You: "];
    [stringHistory appendString:textView.text];
    [stringHistory appendString:@"\n"];
    [stringHistory appendString:messageHistory.text];
    [messageHistory setText:stringHistory];
    
    // Scrolling
    NSRange range;
    range.location = range.length = 0;
    [messageHistory scrollRangeToVisible:range];
    
    // Emptying message field
    [textView setText:@""];
    
    // Updating conversation
    messagesCount++;
    [globalData updateConversation:nil count:[NSNumber numberWithInteger:messagesCount] thread:personThis.strId meetup:FALSE];
    
    // Adding to inbox
    [globalData addMessage:currentMessage];
    
    // Sending push
    [pushManager sendPushNewMessage:currentMessage.strUserTo text:currentMessage.strText];
}

-(void) keyboardWillShow:(NSNotification *)note{
    [super keyboardWillShow:note];
    messageHistory.userInteractionEnabled = NO;
}

-(void) keyboardWillHide:(NSNotification *)note{
    [super keyboardWillHide:note];
    messageHistory.userInteractionEnabled = YES;
}

-(void)send{
    [super send];
    if ( textView.text.length == 0)
        return;
    
    // Adding message with callback on save
    currentMessage = [[Message alloc] init];
    currentMessage.strUserFrom = strCurrentUserId;
    currentMessage.strUserTo = personThis.strId;
    currentMessage.strText = textView.text;
    currentMessage.objUserFrom = [PFUser currentUser];
    currentMessage.objUserTo = personThis.personData;
    currentMessage.strNameUserFrom = [globalVariables fullUserName];
    currentMessage.strNameUserTo = [personThis fullName];
    [currentMessage save:self selector:@selector(callbackMessageSave:error:)];
    
    // Start animating
    [self.activityIndicator startAnimating];
    textView.editable = NO;
}




/*- (IBAction)ignoreButtonDown:(id)sender {
    UIAlertView* confirmationView = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure you want to block this user? You won't receive any notifications." delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""),nil];
    
	[confirmationView show];
}

- (IBAction)meetButtonDown:(id)sender {
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupViewController" bundle:nil];
    [newMeetupViewController setType:TYPE_MEETUP];
    [newMeetupViewController setInvitee:personThis];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation
                                            animated:YES completion:nil];
    
}*/

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 0 )
        return;
    
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"WIP" message:@"Ignore lists and all connected functionality will be added later, thanks." delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
    [errorAlert show];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [textView resignFirstResponder];
}

@end