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
#import "SCAnnotationView.h"

@implementation MeetupViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        meetup = nil;
        invite = false;
        self.navigationItem.leftItemsSupplementBackButton = true;
        buttons = [[NSMutableArray alloc] init];
        [self flushButtons];
    }
    return self;
}

-(void) setMeetup:(Meetup*)m
{
    meetup = m;
}

- (void) setInvite
{
    invite = true;
}

- (void)flushButtons
{
    [buttons removeAllObjects];
    for ( int n = 0; n < MB_TOTAL_COUNT; n++ )
        [buttons addObject:[NSNumber numberWithBool:FALSE]];
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
    if ( [buttons[MB_JOIN] boolValue] )
        [actualButtons addObject:joinBtn];
    if ( [buttons[MB_SUBSCRIBE] boolValue] )
        [actualButtons addObject:subscribeBtn];
    if ( [buttons[MB_DECLINE] boolValue] )
        [actualButtons addObject:declineBtn];
    if ( [buttons[MB_LEAVE] boolValue] )
        [actualButtons addObject:leaveBtn];
    if ( [buttons[MB_CALENDAR] boolValue] && ! [meetup addedToCalendar] )
        [actualButtons addObject:calendarBtn];
    if ( [buttons[MB_INVITE] boolValue] )
        [actualButtons addObject:inviteBtn];
    if ( [buttons[MB_CANCEL] boolValue] )
        [actualButtons addObject:cancelBtn];
    if ( [buttons[MB_EDIT] boolValue] )
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

#pragma mark -
#pragma mark Actions

- (void)declineClicked
{
    // Update invite
    [globalData updateInvite:meetup.strId attending:INVITE_DECLINED];
    
    //[self dismissViewControllerAnimated:TRUE completion:nil];
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (void)joinClicked
{
    // Change and save all the important data
    [globalData attendMeetup:meetup];
    
    // Add comment to the text field
    [self addComment:@"    You joined the meetup!\n"];
    
    // If it was opened from invite
    if ( invite )
    {
        [self.navigationController popViewControllerAnimated:TRUE];
    }
    else
    {
        // Chaning join button to leave and adding addToCalendar
        buttons[MB_JOIN] = [NSNumber numberWithBool:FALSE];
        buttons[MB_LEAVE] = [NSNumber numberWithBool:TRUE];
        buttons[MB_CALENDAR] = [NSNumber numberWithBool:TRUE];
        if ( meetup.privacy == MEETUP_PUBLIC )
            buttons[MB_INVITE] = [NSNumber numberWithBool:TRUE];
        [self updateButtons];
    }
    [self reloadAnnotation];
    
    // Ask to add to calendar
    //[meetup addToCalendar];
}

- (void)editClicked
{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupViewController" bundle:nil];
    [newMeetupViewController setMeetup:meetup];
    
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (void)calendarClicked
{
    [meetup addToCalendar];
    return;
}

- (void)leaveClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Really?" message:@"You won't be able to join this meetup again (to eliminate ambiguity)!" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    message.tag = 3; // Trinity force
    [message show];
    return;
}

- (void)cancelClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Are you serious?" message:@"If you cancel this meetup, nobody will be able to find it and join. This change is irreversible." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    message.tag = 7; // Lucky one
    [message show];
    return;
}

#pragma mark Leave and decline here

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex != 1)
        return;
    
    if ( alertView.tag == 3 ) // Leave
    {
        // Leaving
        [globalData unattendMeetup:meetup];
        
        // Add comment to the text field
        [self addComment:@"    You just left the meetup!\n"];
        
        // Buttons
        [self flushButtons];
        buttons[MB_SUBSCRIBE] = [NSNumber numberWithBool:TRUE];
        buttons[MB_INVITE] = [NSNumber numberWithBool:TRUE];
        [self updateButtons];
        
        // Annotation
        [self reloadAnnotation];
    }
    
    if ( alertView.tag == 7 ) // Cancel
    {
        // Canceling
        [globalData cancelMeetup:meetup];
        
        // Add comment to the text field
        [self addComment:@"    You just canceled the meetup!\n"];
        
        // Buttons
        [self flushButtons];
        buttons[MB_SUBSCRIBE] = [NSNumber numberWithBool:TRUE];
        [self updateButtons];
        
        // Annotation
        [self reloadAnnotation];
    }
}


- (void)subscribeClicked
{
    // Subscribing
    [globalData subscribeToThread:meetup.strId];
    
    // Update invite
    [globalData updateInvite:meetup.strId attending:INVITE_ACCEPTED];
    
    [self reloadAnnotation];
    // Closing window if there was invite
    if ( invite )
        [self.navigationController popViewControllerAnimated:TRUE];
    else
        [self updateButtons];
}

- (void)unsubscribeClicked
{
    [globalData unsubscribeToThread:meetup.strId];
    [self reloadAnnotation];
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

#pragma mark -
#pragma mark UI stuff

- (void)initButtons
{
    NSNumber* buttonOn = [NSNumber numberWithBool:TRUE];
    
    // Time check
    Boolean bPassed = meetup.hasPassed;
    
    // Facebook/EB/etc or not
    if ( meetup.bImportedEvent )
    {
        if ( ! bPassed )
            buttons[MB_CALENDAR] = buttonOn;
    }
    else
    {
        if ( meetup.isCanceled || [globalData hasLeftMeetup:meetup.strId] )
            buttons[MB_SUBSCRIBE] = buttonOn;
        else
        {
            // Own meetup or not
            if ( [meetup.strOwnerId compare:strCurrentUserId ] != NSOrderedSame )
            {
                // Joined or not
                Boolean bJoined = [globalData isAttendingMeetup:meetup.strId];
                
                if ( ! bJoined )    // Or thread as thread can't be joined
                {
                    if ( meetup.meetupType == TYPE_MEETUP )
                    {
                        if ( ! bPassed || invite )
                            buttons[MB_JOIN] = buttonOn;
                    }
                    
                    if ( meetup.meetupType == TYPE_THREAD )
                        buttons[MB_INVITE] = buttonOn;
                    
                    if ( invite )   // Window opened from invite
                        buttons[MB_DECLINE] = buttonOn;
                }
                else    // Attending already
                {
                    if ( ! bPassed )
                    {
                        if ( meetup.privacy == MEETUP_PUBLIC )
                            buttons[MB_INVITE] = buttonOn;
                        buttons[MB_LEAVE] = buttonOn;
                        buttons[MB_CALENDAR] = buttonOn;
                    }
                }
            }
            else
            {
                if ( meetup.meetupType == TYPE_THREAD || ! bPassed )
                {
                    buttons[MB_CANCEL] = buttonOn;
                    buttons[MB_EDIT] = buttonOn;
                    buttons[MB_INVITE] = buttonOn;
                }
                
                if ( meetup.meetupType == TYPE_MEETUP && ! bPassed )
                    buttons[MB_CALENDAR] = buttonOn;
            }
            
            if ( bPassed || meetup.meetupType == TYPE_THREAD )
                buttons[MB_SUBSCRIBE] = buttonOn;
        }
    }
    [self updateButtons];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.title = @"";
    
    textView.editable = FALSE;
    
    // Map
#ifdef IOS7_ENABLE
    mapView.rotateEnabled = FALSE;
#endif
    
    // Setting location and date labels
    [labelLocation setText:meetup.strVenue];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDoesRelativeDateFormatting:TRUE];
    [labelDate setText:[formatter stringFromDate:meetup.dateTime]];
    
    // Description
    if ( meetup.strDescription || meetup.strPrice || meetup.strImageURL || meetup.strOriginalURL )
    {
        NSMutableString *html = [NSMutableString stringWithString: @"<html><head><title></title></head><body>"];
        Boolean bWasSomethingBefore = false;
        if ( meetup.strImageURL && meetup.strImageURL.length > 0 )
        {
            NSUInteger maxWidth = self.view.width - 20;
            NSString* strHtml = [NSString stringWithFormat:MEETUP_TEMPLATE_IMAGE, maxWidth, meetup.strImageURL];
            [html appendString:strHtml];
            bWasSomethingBefore = true;
        }
        if ( meetup.strPrice && meetup.strPrice.length > 0 )
        {
            if ( bWasSomethingBefore )
                [html appendString:@"<BR>"];
            NSString* strHtml = [NSString stringWithFormat:MEETUP_TEMPLATE_PRICE, meetup.strPrice];
            [html appendString:strHtml];
            bWasSomethingBefore = true;
        }
        if ( meetup.strDescription && meetup.strDescription.length > 0 )
        {
            if ( bWasSomethingBefore )
                [html appendString:@"<BR>"];
            NSString* strHtml = [NSString stringWithFormat:MEETUP_TEMPLATE_DESCRIPTION, meetup.strDescription];
            [html appendString:strHtml];
            bWasSomethingBefore = true;
        }
        //if ( meetup.strOriginalURL )
        //{
        //    if ( bWasSomethingBefore )
        //        [html appendString:@"<BR>"];
        //    NSString* strHtml = [NSString stringWithFormat:MEETUP_TEMPLATE_URL, meetup.strOriginalURL];
        //    [html appendString:strHtml];
        //    bWasSomethingBefore = true;
        //}
        [html appendString:@"</body></html>"];
        [descriptionView loadHTMLString:html baseURL:nil];
    }
    else
    {
        // Hiding description view
        descriptionView.hidden = TRUE;
        
        // Replacing description with comments
        CGRect textFrame = comments.frame;
        textFrame.origin.y = descriptionView.frame.origin.y;
        comments.frame = textFrame;
    }
    
    // Loading comments
    PFQuery *commentsQuery = [PFQuery queryWithClassName:@"Comment"];
    commentsQuery.limit = 1000;
    [commentsQuery whereKey:@"meetupId" equalTo:meetup.strId];
    [commentsQuery orderByAscending:@"createdAt"];
    [commentsQuery findObjectsInBackgroundWithBlock:^(NSArray *commentsList, NSError* error)
    {
        if ( error )
        {
            [comments setText:@"Comments loading failed, no connection."];
        }
        else
        {
            NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
            
            if ( meetup.strOriginalURL && meetup.strOriginalURL.length > 0 )
            {
                [stringComments appendString:@"    Original post: "];
                [stringComments appendString:meetup.strOriginalURL];
                [stringComments appendString:@"\n"];
            }
            
            for (NSDictionary *comment in commentsList)
            {
                NSNumber* nSystem = [comment objectForKey:@"system"];
                if ( [nSystem integerValue] == COMMENT_CANCELED )
                {
                    [meetup setCanceled];   // Set meetup as canceled (as we could have old data)
                    [self reloadAnnotation];
                }
                
                NSString* strUserName = [comment objectForKey:@"userName"];
                if ( ! nSystem || [nSystem intValue] == 0 )   // Not a system comment
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
            [self resizeComments];
            
            // Last read message date
            NSDate* commentDate = nil;
            if ( commentsList.count > 0 )
                commentDate = ((PFObject*)commentsList[commentsList.count-1]).createdAt;
            [globalData updateConversation:commentDate count:[NSNumber numberWithInteger:meetup.numComments] thread:meetup.strId meetup:TRUE];
            
            // Update badge number for unread messages
            [globalData postInboxUnreadCountDidUpdate];
            
            // Make new comment editable now
            textView.editable = TRUE;
            
            // Buttons setup
            [self initButtons];
        }
    }];
}

-(void)reloadAnnotation{
    CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(meetup.location.latitude,meetup.location.longitude);
    MKCoordinateRegion reg = MKCoordinateRegionMakeWithDistance(loc, 200.0f, 200.0f);
    mapView.showsUserLocation = NO;
    [mapView setDelegate:self];
    [mapView setRegion:reg animated:true];
    
    if (currentAnnotation) {
        [mapView removeAnnotation:currentAnnotation];
    }
    if (meetup.meetupType == TYPE_MEETUP) {
        MeetupAnnotation *ann = [[MeetupAnnotation alloc] initWithMeetup:meetup];
        [mapView addAnnotation:ann];
        currentAnnotation = ann;
    }else{
        ThreadAnnotation *ann = [[ThreadAnnotation alloc] initWithMeetup:meetup];
        [mapView addAnnotation:ann];
        currentAnnotation = ann;
    }
}

- (void)resizeComments
{
    // Resizing comments
    NSUInteger newHeight = comments.contentSize.height;
    CGRect frame = comments.frame;
    frame.size.height = newHeight;
    comments.frame = frame;
    
    // Resizing scroll view
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, comments.frame.origin.y + comments.frame.size.height)];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Resizing webView
    NSUInteger newHeight= [[webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"] floatValue];
    CGRect frame = webView.frame;
    frame.size.height = newHeight;
    webView.frame = frame;
    webView.scrollView.scrollEnabled = FALSE;
    
    // Moving comments down
    CGRect textFrame = comments.frame;
    textFrame.origin.y = webView.frame.origin.y + webView.frame.size.height;
    comments.frame = textFrame;
    
    // Resizing scroll view
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, comments.frame.origin.y + comments.frame.size.height)];
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id<MKAnnotation>)annotation
{
    SCAnnotationView *pinView = nil;
    if (annotation != mapView.userLocation)
    {
        pinView = [SCAnnotationView constructAnnotationViewForAnnotation:annotation forMap:mV];
        pinView.canShowCallout = YES;
    }
    else {
        [mapView.userLocation setTitle:@"I am here"];
    }
    return pinView;
}

-(void) keyboardWillShow:(NSNotification *)note{
    [super keyboardWillShow:note];
    comments.userInteractionEnabled = NO;
}

-(void) keyboardWillHide:(NSNotification *)note{
    [super keyboardWillHide:note];
    comments.userInteractionEnabled = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadAnnotation];
}

- (void)viewDidUnload {
    comments = nil;
    mapView = nil;
    labelDate = nil;
    labelLocation = nil;
    descriptionView = nil;
    scrollView = nil;
    [super viewDidUnload];
}

-(void)addComment:(NSString*)strComment
{
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    [stringComments appendString:comments.text];
    [stringComments appendString:strComment];
    [comments setText:stringComments];
    [self resizeComments];
}

-(void)send{
    [super send];
    if ( textView.text.length == 0 )
        return;
    
    // Creating comment in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_PLAIN
                           commentText:textView.text];
    
    // Adding comment to the list
    [self addComment:[NSString stringWithFormat:@"    %@: %@\n", [globalVariables fullUserName], textView.text]];
    
    [textView setText:@""];
    
    [self updateButtons];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [textView resignFirstResponder];
}
@end