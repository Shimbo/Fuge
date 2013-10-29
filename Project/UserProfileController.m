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
#import "Message.h"
#import "LinkedinLoader.h"
#import "FUGOpportunitiesView.h"

@implementation UserProfileController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"", @"");
        messagesCount = 0;
        profileMode = PROFILE_MODE_MESSAGES;
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(messageReceived:)
                                                name:kPushReceivedNewMessage
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(opsHidden)
                                                name:kOpportunitiesHidden
                                                object:nil];
    }
    return self;
}

- (void)profileClicked{
    [personThis openProfileInBrowser];
}

- (void)meetClicked{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupViewController" bundle:nil];
    [newMeetupViewController setType:TYPE_MEETUP];
    [newMeetupViewController setInvitee:personThis];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (void)messageClicked{
    
    if ( profileMode == PROFILE_MODE_MESSAGES )
    {
        profileMode = PROFILE_MODE_SUMMARY;
        [textView resignFirstResponder];
    }
    else
        profileMode = PROFILE_MODE_MESSAGES;
    [self updateUI];
}

- (void)resizeScroll
{
    CGRect frame;
    
    // Resizing scroll view frame
    if ( profileMode == PROFILE_MODE_MESSAGES )
        scrollView.height = self.view.height-containerView.height;
    else
        scrollView.height = self.view.height;
    
#ifdef TARGET_S2C
    // Resizing web view
    if ( profileMode == PROFILE_MODE_SUMMARY )
    {
        NSUInteger newHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"] floatValue];
        frame = webView.frame;
        frame.size.height = newHeight;
        webView.frame = frame;
    }
#endif
    
    // Resizing scroll view contents
    if ( profileMode == PROFILE_MODE_MESSAGES )
        [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, messagesView.frame.origin.y + messagesView.frame.size.height)];
    else
        [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, webView.frame.origin.y + webView.frame.size.height)];
    
    // Scrolling down
    if ( profileMode == PROFILE_MODE_MESSAGES )
        [scrollView scrollRectToVisible:CGRectMake(0, scrollView.contentSize.height-1, scrollView.frame.size.width, scrollView.contentSize.height) animated:TRUE];
    else
        [scrollView scrollRectToVisible:CGRectMake(0, 0, scrollView.frame.size.width, 1) animated:TRUE];
}

- (void)updateUI
{
    if ( profileMode == PROFILE_MODE_MESSAGES )
    {
        messagesView.hidden = FALSE;
        textView.hidden = FALSE;
        containerView.hidden = FALSE;
        webView.hidden = TRUE;
        opportunities.hidden = TRUE;
#ifdef TARGET_S2C
        [messageBtn setTitle:@"Full profile"];
#endif
    }
    else
    {
        messagesView.hidden = TRUE;
        textView.hidden = TRUE;
        containerView.hidden = TRUE;
        webView.hidden = FALSE;
        opportunities.hidden = FALSE;
#ifdef TARGET_S2C
        [messageBtn setTitle:@"Message"];
#endif
    }
    [self resizeScroll];
}

-(void) setProfileMode:(NSUInteger)mode
{
#ifdef TARGET_S2C
    profileMode = mode;
#endif
}

-(void) setMessageText:(NSString*)text
{
    textView.text = text;
    [textView becomeFirstResponder];
}

- (void) opsHidden
{
    if ( opportunities )
        [UIView animateWithDuration:0.3 animations:^{
            webView.originY -= opportunities.height;
            opportunities.alpha = 0.0f;
        }];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ( profileMode == PROFILE_MODE_SUMMARY )
        [self resizeScroll];
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

- (void)messageReceived:(NSNotification *)notification
{
    NSString* userFrom = [notification object];
    if ( userFrom && [userFrom compare:personThis.strId] == NSOrderedSame )
        [globalData loadMessageThread:personThis target:self selector:@selector(messagesLoaded:error:)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Boolean bCurrentUser = ( [personThis.strId compare:strCurrentUserId ] == NSOrderedSame );
    
    NSMutableArray* buttonArray = [NSMutableArray arrayWithCapacity:2];
#ifdef TARGET_FUGE
    NSString* strProfileTitle = @"FB Profile";
#elif defined TARGET_S2C
    NSString* strProfileTitle = @"LI Profile";
    if ( ! bCurrentUser )
    {
        messageBtn = [[UIBarButtonItem alloc] initWithTitle:@"Message" style:UIBarButtonItemStylePlain target:self action:@selector(messageClicked)];
        [buttonArray addObject:messageBtn];
    }
    btnThingsInCommon.hidden = TRUE;
#endif
    [buttonArray addObject:[[UIBarButtonItem alloc] initWithTitle:strProfileTitle style:UIBarButtonItemStylePlain target:self action:@selector(profileClicked)]];
    if ( ! bCurrentUser )
        [buttonArray addObject:[[UIBarButtonItem alloc] initWithTitle:@"Meet" style:UIBarButtonItemStylePlain target:self action:@selector(meetClicked)]];
    self.navigationItem.rightBarButtonItems = buttonArray;
    
    containerView.userInteractionEnabled = FALSE;
    
    // Comments
    if ( ! bCurrentUser )
        [globalData loadMessageThread:personThis target:self selector:@selector(messagesLoaded:error:)];
    
    // Avatar
    //profileImageView.profileID = personThis.strId;
    //profileImageView.pictureCropping = FBProfilePictureCroppingSquare;
    if ( personThis.largeAvatarUrl )
        [profileImage loadImageFromURL:personThis.largeAvatarUrl];
    
    // Labels
    labelFriendName.text = [personThis fullName];
    if ( bCurrentUser )
    {
        labelDistance.text = @"";
        labelTimePassed.text = @"It's you!";
    }
    else
    {
        NSString* distanceString = [personThis distanceString:FALSE];
        labelDistance.text = distanceString;
        labelTimePassed.text = [[NSString alloc] initWithFormat:@"%@ ago", [personThis timeString]];
    }

#ifdef TARGET_FUGE
    labelStatus.text = personThis.strStatus;
    strJobInfo.hidden = TRUE;
    strIndustry.hidden = TRUE;
#elif defined TARGET_S2C
    strJobInfo.text = personThis.jobInfo;
    strIndustry.text = personThis.industryInfo;
    labelTimePassed.originY += 37;
    labelDistance.originY += 37;
    labelStatus.hidden = TRUE;
    
    // Summary
    NSString* strResult = [lnLoader getProfileInHtml:nil summary:personThis.profileSummary jobs:personThis.profilePositions];
    [webView loadHTMLString:strResult baseURL:nil];
#endif
    
#ifdef TARGET_FUGE
    nThingsInCommon = [personThis matchesTotal];
    NSString* strTitle = @"No matches";
    if ( nThingsInCommon == 1 )
        strTitle = @"See 1 match";
    else if ( nThingsInCommon > 1 )
        strTitle = [NSString stringWithFormat:@"See %d matches", nThingsInCommon];
    if ( bIsAdmin )
        strTitle = [strTitle stringByAppendingString:[NSString stringWithFormat:@"+%d", personThis.matchesAdminBonus]];
    [btnThingsInCommon setTitle:strTitle forState:UIControlStateNormal];
#endif
    
    personThis.numUnreadMessages = 0;
    
    keyboard = [[ULKeyboardHandler alloc] init];
    keyboard.delegate = self;
    
#ifdef TARGET_S2C
    // Opportunities
    [self updateOpportunities];
#endif
    
    // UI stuff, scroll, texts
    [self updateUI];
}

- (void) updateOpportunities
{
    // Opportunities
    if ( opportunities )
    {
        webView.originY = opportunities.originY;
        [opportunities removeFromSuperview];
    }
    opportunities = [[FUGOpportunitiesView alloc] initWithFrame:CGRectMake(0, webView.originY, self.view.width, 0)];
    
    // Real opportunities
    if ( personThis.isCurrentUser )
        [opportunities addHideAllButtonFor:personThis];   // To add "add new opportunity" button
    for ( FUGOpportunity* op in personThis.allOpportunities )
        [opportunities addOpportunity:op by:personThis isRead:op.read];
    
    // Add only if we should
    if ( ( personThis.allOpportunities && personThis.allOpportunities.count > 0 ) || personThis.isCurrentUser )
    {
        [scrollView addSubview:opportunities];
        webView.originY = opportunities.originY + opportunities.height;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
#ifdef TARGET_S2C
    [self updateOpportunities];
    
    // UI stuff, scroll, texts
    [self updateUI];
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) messagesLoaded:(NSArray*)messages error:(NSError *)error
{
    if (error || ! messages )
    {
        [messagesView setText:@"Messages load failed, no connection."];
        return;
    }
    
    //NSMutableString* stringHistory = [[NSMutableString alloc] initWithFormat:@""];
    
    // Feedback message (always at the top, first one)
    /*if ( [globalVariables isFeedbackBot:personThis.strId] )
    {
        [stringHistory appendString:@"    "];
        [stringHistory appendString:personThis.strFirstName];
        [stringHistory appendString:@": "];
        [stringHistory appendString:WELCOME_MESSAGE];
        if ( messages.count != 0 )
            [stringHistory appendString:@"\n"];
    }*/
    
    // Date formatter
    //NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    //[formatter setDateStyle:NSDateFormatterMediumStyle];
    //[formatter setTimeStyle:NSDateFormatterNoStyle];
    //[formatter setDoesRelativeDateFormatting:TRUE];
    
    // Messages
    //NSDate* conversationDate = [personThis getConversationDate:strCurrentUserId meetup:FALSE];
    //Boolean bReadMarkAdded = FALSE;
    /*for ( int n = 0; n < messages.count; n++ )
    {
        Message* message = messages[n];
        
        // My or opponents?
        Boolean myMessage = ([personThis.strId compare:message.strUserFrom] != NSOrderedSame);
        
        // Read or not
        Boolean thisMessageBefore = false;
        if ( conversationDate )
            if ( [conversationDate compare:message.dateCreated] != NSOrderedAscending )
                thisMessageBefore = true;
        if ( myMessage && thisMessageBefore )
            [stringHistory appendString:@"*"];
        else
            [stringHistory appendString:@" "];
        
        // Add message
        if ( myMessage )
            [stringHistory appendString:@"   You: "];
        else
        {
            [stringHistory appendString:@"   "];
            [stringHistory appendString:personThis.strFirstName];
            [stringHistory appendString:@": "];
        }
        //[stringHistory appendString:[formatter stringFromDate:message.dateCreated]];
        //[stringHistory appendString:@": "];
        [stringHistory appendString:message.strText];
        
        if ( n != messages.count - 1 )
            [stringHistory appendString:@"\n"];
    }*/
    
    //[messageHistory setText:stringHistory];
    [messagesView setCommentsList:messages navigation:nil];
    messagesCount = messages.count;
    
    containerView.userInteractionEnabled = TRUE;
    
    if ( profileMode == PROFILE_MODE_MESSAGES )
        [self resizeScroll];
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
    messagesView = nil;
    labelDistance = nil;
    [self setActivityIndicator:nil];
    labelFriendName = nil;
    labelTimePassed = nil;
    btnThingsInCommon = nil;
    profileImage = nil;
    labelStatus = nil;
    scrollView = nil;
    webView = nil;
    strJobInfo = nil;
    strIndustry = nil;
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

- (void)keyboardSizeChanged:(CGSize)delta
{
    scrollView.originY -= delta.height;
}

- (void) callbackMessageSaved:(Message*)message
{
    [self.activityIndicator stopAnimating];
    containerView.userInteractionEnabled = TRUE;
    
    if ( ! message )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"Message send failed, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
    
    // Updating conversation
    messagesCount++;
    [globalData updateConversation:message.dateCreated count:[NSNumber numberWithInteger:messagesCount] thread:personThis.strId meetup:FALSE];
    
    // Updating history
    [messagesView addComment:message];
    
    // Scrolling, sizing, etc.
    [self resizeScroll];
    
    // Reseting text field
    [textView setText:@""];
}

-(void)send{
    [super send];
    if ( textView.text.length == 0)
        return;
    
    // Adding message with callback on save
    [globalData createMessage:textView.text person:personThis target:self selector:@selector(callbackMessageSaved:)];
    
    // Start animating
    [self.activityIndicator startAnimating];
    containerView.userInteractionEnabled = FALSE;
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
