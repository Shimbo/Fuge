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
        for ( int n = 0; n < MB_TOTAL_COUNT; n++ )
            [buttons addObject:[NSNumber numberWithInt:0]];
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
    if ( [buttons[MB_CALENDAR] integerValue] != 0 && ! [meetup addedToCalendar] )
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
    // Update invite
    [globalData updateInvite:meetup.strId attending:INVITE_DECLINED];
    
    //[self dismissViewControllerAnimated:TRUE completion:nil];
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (void)joinClicked
{
    // Add to attending list and save attendee in DB
    [globalData attendMeetup:meetup];
    
    // Update invite
    [globalData updateInvite:meetup.strId attending:INVITE_ACCEPTED];
    
    // Creating comment about joining in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_JOINED commentText:nil];
    
    // Add comment to the text field
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    [stringComments appendString:comments.text];
    [stringComments appendString:@"    You joined the event!\n"];
    [comments setText:stringComments];
    
    // Adding attendee to the local copy of meetup
    [meetup addAttendee:strCurrentUserId];
    
    // If it was opened from invite
    if ( invite )
    {
        [self.navigationController popViewControllerAnimated:TRUE];
    }
    else
    {
        // Chaning join button to leave and adding addToCalendar
        buttons[MB_JOIN] = [NSNumber numberWithInt:0];
        buttons[MB_LEAVE] = [NSNumber numberWithInt:1];
        buttons[MB_CALENDAR] = [NSNumber numberWithInt:1];
        if ( meetup.privacy == MEETUP_PUBLIC )
            buttons[MB_INVITE] = [NSNumber numberWithInt:1];
        [self updateButtons];
    }
    [self reloadAnnotation];
    
    // Ask to add to calendar
    [meetup addToCalendar];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidLoad];
    
    self.title = @"";
    
    textView.editable = FALSE;
    
    // Map
#ifdef IOS7_ENABLE
    mapView.rotateEnabled = FALSE;
#endif
    
    NSNumber* buttonOn = [NSNumber numberWithInt:1];
    
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
                
                if ( meetup.meetupType == TYPE_THREAD || bPassed )
                    buttons[MB_SUBSCRIBE] = buttonOn;
                
                if ( meetup.meetupType == TYPE_THREAD )
                    buttons[MB_INVITE] = buttonOn;
                
                if ( invite )   // Window opened from invite
                    buttons[MB_DECLINE] = buttonOn;
            }
            else    // Attending already
            {
                if ( bPassed )
                    buttons[MB_SUBSCRIBE] = buttonOn;
                else
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
    }
    [self updateButtons];
    
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
            [globalData updateConversation:commentDate count:meetup.numComments thread:meetup.strId];
            
            // Update badge number for unread messages
            [globalData postInboxUnreadCountDidUpdate];
            
            // Make new comment editable now
            textView.editable = TRUE;
        }
    }];
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

-(void) setMeetup:(Meetup*)m
{
    meetup = m;
}

- (void) setInvite
{
    invite = true;
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


-(void)send{
    [super send];
    if ( textView.text.length == 0 )
        return;
    
    // Creating comment in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_PLAIN
                           commentText:textView.text];
    
    // Adding comment to the list
    NSMutableString* stringComments = [[NSMutableString alloc] initWithString:comments.text];
    [stringComments appendString:@"    "];
    [stringComments appendString:[globalVariables fullUserName]];
    [stringComments appendString:@": "];
    [stringComments appendString:textView.text];
    [stringComments appendString:@"\n"];
    [comments setText:stringComments];
    
    [textView setText:@""];
    
    [self resizeComments];
    
    [self updateButtons];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [textView resignFirstResponder];
}
@end