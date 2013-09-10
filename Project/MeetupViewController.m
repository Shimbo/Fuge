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
#import "MeetupInviteViewController.h"
#import "SCAnnotationView.h"
#import "PeopleViewController.h"
#import "AsyncImageView.h"

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
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(commentReceived:)
                                                name:kPushReceivedNewComment
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadMeetupData)
                                                name:kLoadingMapComplete
                                                object:nil];
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
    
    UIBarButtonItem *featureBtn = [[UIBarButtonItem alloc] initWithTitle:@"Feature" style:UIBarButtonItemStyleBordered target:self action:@selector(featureClicked)];
    
    NSMutableArray* actualButtons = [[NSMutableArray alloc] init];
    if ( [buttons[MB_JOIN] boolValue] )
        [actualButtons addObject:joinBtn];
//    if ( [buttons[MB_SUBSCRIBE] boolValue] )
//        [actualButtons addObject:subscribeBtn];
    if ( [buttons[MB_DECLINE] boolValue] )
        [actualButtons addObject:declineBtn];
    if ( [buttons[MB_LEAVE] boolValue] )
        [actualButtons addObject:leaveBtn];
    if ( [buttons[MB_CALENDAR] boolValue] && ! [meetup addedToCalendar] && ! [buttons[MB_FEATURE] boolValue] ) // to open some space
        [actualButtons addObject:calendarBtn];
    if ( [buttons[MB_INVITE] boolValue] )
        [actualButtons addObject:inviteBtn];
    if ( [buttons[MB_CANCEL] boolValue] )
        [actualButtons addObject:cancelBtn];
    if ( [buttons[MB_EDIT] boolValue] )
        [actualButtons addObject:editBtn];
    if ( [buttons[MB_FEATURE] boolValue] )
        [actualButtons addObject:featureBtn];
    
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
    if ( meetup.spotsAvailable == 0 )
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"Unfortunately, all available spots are taken. Next time!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [message show];
        return;
    }
    
    // Change and save all the important data
    [globalData attendMeetup:meetup addComment:TRUE target:self selector:@selector(reloadAnnotation)];
    
    // Add comment to the text field
    [self addComment:@"    You joined the event!\n" scrollDown:FALSE];
    
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

- (void)featureClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Feature event" message:@"Enter featuring text, not too long." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Feature",nil];
    message.tag = 777; // Jackpot!
    [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[message textFieldAtIndex:0] setDelegate:self];
    NSString* strCurrentFeature = meetup.strFeatured;
    if ( strCurrentFeature && strCurrentFeature.length > 0 )
        [[message textFieldAtIndex:0] setPlaceholder:strCurrentFeature];
    [[message textFieldAtIndex:0] setFont:[UIFont systemFontOfSize:14]];
    [message show];
    return;
}

- (void)leaveClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Really?" message:@"You won't be able to join this event again (to eliminate ambiguity)!" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    message.tag = 3; // Trinity force
    [message show];
    return;
}

- (void)cancelClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Are you serious?" message:@"If you cancel this event, nobody will be able to find it and join. This change is irreversible." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    message.tag = 7; // Lucky one
    [message show];
    return;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex != 1)
        return;
    
    if ( alertView.tag == 3 ) // Leave
    {
        // Leaving
        [globalData unattendMeetup:meetup target:self selector:@selector(reloadAnnotation)];
        
        // Add comment to the text field
        [self addComment:@"    You just left the event!\n" scrollDown:FALSE];
        
        // Buttons
        [self flushButtons];
        buttons[MB_SUBSCRIBE] = [NSNumber numberWithBool:TRUE];
        buttons[MB_INVITE] = [NSNumber numberWithBool:TRUE];
        [self updateButtons];        
    }
    
    if ( alertView.tag == 7 ) // Cancel
    {
        // Canceling
        [globalData cancelMeetup:meetup];
        
        // Add comment to the text field
        [self addComment:@"    You just canceled the event!\n" scrollDown:FALSE];
        
        // Buttons
        [self flushButtons];
        buttons[MB_SUBSCRIBE] = [NSNumber numberWithBool:TRUE];
        [self updateButtons];
        
        // Annotation
        [self reloadAnnotation];
    }
    
    if ( alertView.tag == 777 ) // Feature
    {
        if (buttonIndex == 1)
        {
            NSString* strResult = [[alertView textFieldAtIndex:0] text];
            if ( strResult )
                [meetup feature:strResult];
        }
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
#pragma mark Commenting


-(void)addComment:(NSString*)strComment scrollDown:(Boolean)scrollDown
{
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    [stringComments appendString:comments.text];
    [stringComments appendString:strComment];
    [comments setText:stringComments];
    [self resizeComments:scrollDown];
}

- (void) callbackCommentSaved:(Comment*)comment
{
    [activityIndicator stopAnimating];
    containerView.userInteractionEnabled = TRUE;
    
    if ( ! comment )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"Comment send failed, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
    
    // Updating conversation
    meetup.numComments++;
    [globalData updateConversation:comment.dateCreated count:[NSNumber numberWithInteger:meetup.numComments] thread:comment.strMeetupId meetup:TRUE];
    
    // Adding comment to the list
    [self addComment:[NSString stringWithFormat:@"    %@: %@\n", [globalVariables fullUserName], textView.text] scrollDown:TRUE];
    
    // Reseting text field
    [textView setText:@""];
}

-(void)send{
    [super send];
    if ( textView.text.length == 0 )
        return;
    
    // Creating comment in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_PLAIN
                           commentText:textView.text target:self selector:@selector(callbackCommentSaved:)];
    
    // Start animating
    [activityIndicator startAnimating];
    containerView.userInteractionEnabled = FALSE;
}


#pragma mark -
#pragma mark UI stuff


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Reload data
    [self reloadMeetupData];
    
    // Create list of views and sort
    viewsList = [NSMutableArray arrayWithCapacity:10];
    [viewsList addObject:alertTicketsOnline];
    [viewsList addObject:labelLocation];
    [viewsList addObject:mapView];
    [viewsList addObject:peopleCounters];
    [viewsList addObject:labelSpotsAvailable];
    [viewsList addObject:descriptionView];
    [viewsList addObject:comments];
    
    // Resize and rearrange
    [self resizeComments:FALSE];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.title = @"";
    
    containerView.userInteractionEnabled = FALSE;
    
    // Map
#ifdef IOS7_ENABLE
    mapView.rotateEnabled = FALSE;
#endif
    
    // Loading comments
    [globalData loadCommentThread:meetup target:self selector:@selector(callbackCommentsLoaded:error:)];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadAnnotation];
    [self reloadMeetupData];
    [self resizeComments:FALSE];
}

- (void)initButtons
{
    NSNumber* buttonOn = [NSNumber numberWithBool:TRUE];
    
    // Time check
    Boolean bPassed = meetup.hasPassed;
    
    // Featuring
    if ( bIsAdmin )
        buttons[MB_FEATURE] = buttonOn;
    
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
                        {
                            buttons[MB_JOIN] = buttonOn;
                            if ( ! invite )
                                buttons[MB_INVITE] = buttonOn;
                        }
                    }
                    
                    if ( meetup.meetupType == TYPE_THREAD )
                        buttons[MB_INVITE] = buttonOn;
                    
                    if ( invite )   // Window opened from invite
                        buttons[MB_DECLINE] = buttonOn;
                    
                    if ( [globalData isSubscribedToThread:meetup.strId] )
                        buttons[MB_SUBSCRIBE] = buttonOn;
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

-(void) callbackCommentsLoaded:(NSArray*)loadedComments error:(NSError *)error
{
    if (error || ! loadedComments )
    {
        [comments setText:@"Comments loading failed, no connection."];
        return;
    }
    
    // Comments
    NSMutableString* stringComments = [[NSMutableString alloc] initWithFormat:@""];
    //if ( meetup.strOriginalURL && meetup.strOriginalURL.length > 0 )
    //    [stringComments appendString:[NSString stringWithFormat:@"    Original post: %@\n", meetup.strOriginalURL]];
    
    for (Comment *comment in loadedComments)
    {
        NSNumber* nSystem = comment.systemType;
        if ( [nSystem integerValue] == COMMENT_CANCELED )
        {
            [meetup setCanceled];   // Set meetup as canceled (as we could have old data)
            [self reloadAnnotation];
        }
        
        NSString* strUserName = comment.strNameUserFrom;
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
        [stringComments appendString:comment.strComment];
        [stringComments appendString:@"\n"];
    }
    Boolean bWasNotEmpty = ( commentsList.count > 0 );
    [comments setText:stringComments];
    commentsList = [NSMutableArray arrayWithArray:loadedComments];
    [self resizeComments:bWasNotEmpty];
    
    // Update badge number for unread messages
    [globalData postInboxUnreadCountDidUpdate];
    
    // Make new comment editable now
    if ( ! meetup.bImportedEvent )
        containerView.userInteractionEnabled = TRUE;
    
    // Buttons setup
    [self initButtons];
}

- (void)commentReceived:(NSNotification *)notification {
    
    NSString* meetupId = [notification object];
    if ( meetupId && [meetupId compare:meetup.strId] == NSOrderedSame )
        [globalData loadCommentThread:meetup target:self selector:@selector(callbackCommentsLoaded:error:)];
}

- (void)reloadMeetupData
{
    // Location
    [labelLocation setText:meetup.strVenue];
    
    // Date
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDoesRelativeDateFormatting:TRUE];
    [labelDate setText:[formatter stringFromDate:meetup.dateTime]];
    
    // People counters
    [countersJoined setTitle:[NSString stringWithFormat:@"Going: %d", meetup.attendees.count] forState:UIControlStateNormal];
    [countersDeclined setTitle:[NSString stringWithFormat:@"Can't: %d", meetup.decliners.count] forState:UIControlStateNormal];
    [countersInvited setTitle:[NSString stringWithFormat:@"Not decided: %d", 0] forState:UIControlStateNormal];
    
    // Avatars
    if ( avatarList )
    {
        for ( AsyncImageView* avatar in avatarList )
            [avatar removeFromSuperview];
    }
    avatarList = [NSMutableArray arrayWithCapacity:10];
    NSUInteger offset = countersJoined.originX + [countersJoined.titleLabel.text sizeWithFont:countersJoined.titleLabel.font].width + 5;
    NSArray* attendeesPersons = [globalData getPersonsByIds:meetup.attendees];
    for ( Person* person in attendeesPersons )
    {
        if ( person.idCircle != CIRCLE_FB && person.idCircle != CIRCLE_NONE )
            continue;
        if ( ! person.smallAvatarUrl )
            continue;
        AsyncImageView* image = [[AsyncImageView alloc] initWithFrame:CGRectMake(offset+avatarList.count*(MINI_AVATAR_SIZE+1), countersJoined.originY + 6, MINI_AVATAR_SIZE, MINI_AVATAR_SIZE)];
        [image loadImageFromURL:person.smallAvatarUrl];
        [avatarList addObject:image];
        [peopleCounters addSubview:image];
        if ( avatarList.count > MINI_AVATAR_COUNT_MEETUP )
            break;
    }
    
    // Spots
    Boolean bSoldOut = FALSE;
    if ( meetup.maxGuests )
    {
        labelSpotsAvailable.hidden = FALSE;
        
        [labelSpotsAvailable setText:[NSString stringWithFormat:NSLocalizedString(@"MEETUP_SPOTS_AVAILABLE",nil), meetup.spotsAvailable]];
        if ( meetup.spotsAvailable == 0 )
            bSoldOut = TRUE;
    }
    else
        labelSpotsAvailable.hidden = TRUE;
    
    // Price alert
    if ( meetup.strPrice || meetup.strOriginalURL || bSoldOut )
    {
        alertTicketsOnline.hidden = FALSE;
        alertTicketsOnline.enabled = TRUE;
        if ( bSoldOut )
        {
            alertTicketsOnline.backgroundColor = [UIColor colorWithHexString:MEETUP_ALERT_COLOR_GREY];
            NSString* strLabel = NSLocalizedString(@"MEETUP_ALERT_SOLDOUT",nil);
            [alertTicketsOnline setTitle:strLabel forState:UIControlStateNormal];
            //alertTicketsOnline.enabled = FALSE;
        }
        else if ( meetup.strPrice && meetup.strOriginalURL)
        {
            alertTicketsOnline.backgroundColor = [UIColor colorWithHexString:MEETUP_ALERT_COLOR_RED];
            NSString* strLabel = [NSString stringWithFormat:NSLocalizedString(@"MEETUP_ALERT_PAYONLINE",nil), meetup.strPrice];
            [alertTicketsOnline setTitle:strLabel forState:UIControlStateNormal];
        }
        else if ( meetup.strOriginalURL )
        {
            alertTicketsOnline.backgroundColor = [UIColor colorWithHexString:MEETUP_ALERT_COLOR_YELLOW];
            NSString* strLabel = NSLocalizedString(@"MEETUP_ALERT_REGONLINE",nil);
            [alertTicketsOnline setTitle:strLabel forState:UIControlStateNormal];
        }
        else if ( meetup.strPrice )
        {
            alertTicketsOnline.backgroundColor = [UIColor colorWithHexString:MEETUP_ALERT_COLOR_GREEN];
            NSString* strLabel = [NSString stringWithFormat:NSLocalizedString(@"MEETUP_ALERT_PAYONSITE",nil), meetup.strPrice];
            [alertTicketsOnline setTitle:strLabel forState:UIControlStateNormal];
            alertTicketsOnline.enabled = FALSE;
        }
    }
    else
        alertTicketsOnline.hidden = TRUE;
    
    // Description
    if ( meetup.strDescription || meetup.strImageURL )
    {
        // Showing description
        descriptionView.hidden = FALSE;
        
        // Setting text
        NSMutableString *html = [NSMutableString stringWithString: @"<html><head><title></title></head><body>"];
        Boolean bWasSomethingBefore = false;
        if ( meetup.strImageURL && meetup.strImageURL.length > 0 )
        {
            NSUInteger maxWidth = self.view.width - 20;
            NSString* strHtml = [NSString stringWithFormat:MEETUP_TEMPLATE_IMAGE, maxWidth, meetup.strImageURL];
            [html appendString:strHtml];
            bWasSomethingBefore = true;
        }
        /*if ( meetup.strPrice && meetup.strPrice.length > 0 )
        {
            if ( bWasSomethingBefore )
                [html appendString:@"<BR>"];
            NSString* strHtml = [NSString stringWithFormat:MEETUP_TEMPLATE_PRICE, meetup.strPrice];
            [html appendString:strHtml];
            bWasSomethingBefore = true;
        }*/
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
        
        //[html appendString:@"<div style='width:100%; text-align:left;'><iframe src='http://www.eventbrite.com/tickets-external?eid=4653432542&ref=etckt' frameborder='0' height='256' width='100%' vspace='0' hspace='0' marginheight='5' marginwidth='5' scrolling='auto' allowtransparency='true'></iframe></div>"];
        
        [html appendString:@"</body></html>"];
        
        [descriptionView loadHTMLString:html baseURL:nil];
    }
    else
        descriptionView.hidden = TRUE;
    
    [self reloadAnnotation];
}

-(void)reloadAnnotation{
    CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(meetup.location.latitude,meetup.location.longitude);
    MKCoordinateRegion reg = MKCoordinateRegionMakeWithDistance(loc, 200.0f, 200.0f);
    mapView.showsUserLocation = NO;
    [mapView setDelegate:self];
    [mapView setRegion:reg animated:true];
    
    if (currentMeetupAnnotation)
        [mapView removeAnnotation:currentMeetupAnnotation];
    if (currentPersonAnnotation)
        [mapView removeAnnotation:currentPersonAnnotation];
    
    Person* current = currentPerson;
    currentPersonAnnotation = [[PersonAnnotation alloc] initWithPerson:current];
    currentPersonAnnotation.title = [globalVariables shortUserName];
    if ( current.strStatus && current.strStatus.length > 0 )
        currentPersonAnnotation.subtitle = current.strStatus;
    else
        currentPersonAnnotation.subtitle = @"This is you";
    [mapView addAnnotation:currentPersonAnnotation];
    
    if (meetup.meetupType == TYPE_MEETUP) {
        currentMeetupAnnotation = [[MeetupAnnotation alloc] initWithMeetup:meetup];
        [mapView addAnnotation:currentMeetupAnnotation];
    }/*else{
        ThreadAnnotation *ann = [[ThreadAnnotation alloc] initWithMeetup:meetup];
        [mapView addAnnotation:ann];
        currentAnnotation = ann;
    }*/
}

- (void)resizeComments:(Boolean)scrollDown
{
    // Resizing comments
    NSUInteger newHeight = comments.contentSize.height;
    CGRect frame = comments.frame;
    frame.size.height = newHeight;
    comments.frame = frame;
    
    // Arranging subviews
    NSInteger nYOffset = 0;
    for ( UIView* view in viewsList )
    {
        if ( view.hidden )
            continue;
        
        CGRect viewFrame = view.frame;
        viewFrame.origin.y = nYOffset;
        view.frame = viewFrame;
        nYOffset += viewFrame.size.height;
    }
    CGRect dateFrame = labelDate.frame;
    dateFrame.origin.y = labelLocation.frame.origin.y;
    labelDate.frame = dateFrame;
    
    // Resizing scroll view
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, comments.frame.origin.y + comments.frame.size.height)];
    
    // Scrolling down
    if ( scrollDown )
        [scrollView scrollRectToVisible:CGRectMake(0, scrollView.contentSize.height-1, scrollView.frame.size.width, scrollView.contentSize.height) animated:TRUE];
}


#pragma mark -
#pragma mark WebView


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


#pragma mark -
#pragma mark Misc


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

- (void)viewDidUnload {
    comments = nil;
    mapView = nil;
    labelDate = nil;
    labelLocation = nil;
    descriptionView = nil;
    scrollView = nil;
    activityIndicator = nil;
    alertTicketsOnline = nil;
    labelSpotsAvailable = nil;
    peopleCounters = nil;
    countersJoined = nil;
    countersDeclined = nil;
    countersInvited = nil;
    [super viewDidUnload];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [textView resignFirstResponder];
}
- (IBAction)alertTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:meetup.strOriginalURL]];
}

- (void) openPeopleList:(NSArray*)idsList
{
    PeopleViewController *peopleViewController = [[PeopleViewController alloc] initWithNibName:@"PeopleView" bundle:nil];
    [peopleViewController setIdsList:idsList];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:peopleViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (IBAction)countersJoinedTapped:(id)sender {
    [self openPeopleList:meetup.attendees];
}

- (IBAction)countersDeclinedTapped:(id)sender {
    [self openPeopleList:meetup.decliners];
}

- (IBAction)countersInvitedTapped:(id)sender {
}
@end