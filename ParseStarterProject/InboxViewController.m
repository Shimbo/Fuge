//
//  InboxViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 2/11/13.
//
//

#import "InboxViewController.h"
#import "TestFlightSDK/TestFlight.h"
#import "GlobalData.h"
#import "InboxCell.h"
#import "AsyncImageView.h"
#import "MeetupViewController.h"
#import "UserProfileController.h"

@implementation InboxViewItem
@end

@implementation InboxViewController

#define ROW_HEIGHT 60

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        inbox = nil;
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(refreshData)
                                                name:kLoadingInboxComplete
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(loadingFailed)
                                                name:kLoadingInboxFailed
                                                object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"InboxCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"InboxCellIdent"];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = ROW_HEIGHT;
    
    // Reload button
    UIBarButtonItem *reloadBtn = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStyleBordered target:self action:@selector(reloadClicked)];
    [self.navigationItem setRightBarButtonItem:reloadBtn];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [TestFlight passCheckpoint:@"Inbox opened"];
    
    // Loading or updating UI
    if ( [globalData getLoadingStatus:LOADING_INBOX] != LOAD_STARTED )
    {
        [self refreshData];
    }
    else
    {
        // UI
        [self.activityIndicator startAnimating];
        _tableView.userInteractionEnabled = FALSE;
    }
}

- (void) reloadClicked
{
    // UI
    [self.activityIndicator startAnimating];
    _tableView.userInteractionEnabled = FALSE;
    
    // Loading
    if ( [globalData getLoadingStatus:LOADING_INBOX] != LOAD_STARTED )
        [globalData reloadInboxInBackground];
}

- (void) refreshData {
    
    [self.activityIndicator stopAnimating];
    _tableView.userInteractionEnabled = TRUE;
    
    inbox = [globalData getInbox];
    
    if ( inbox )
        [[self tableView] reloadData];
}

- (void) loadingFailed {
    [self.activityIndicator stopAnimating];
    _tableView.userInteractionEnabled = TRUE;
}


#pragma mark -
#pragma mark Table view datasource and delegate methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	
    NSInteger nCount = [inbox count];
	return nCount;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	
    NSArray *keys = [inbox allKeys];
    id aKey = [keys objectAtIndex:section];
    
	NSArray *items = [inbox objectForKey:aKey];
	return [items count];
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	
    NSArray *keys = [inbox allKeys];
	return [keys objectAtIndex:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
	static NSString *CellIdentifier = @"InboxCellIdent";
    
	InboxCell *inboxCell = (InboxCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSArray *keys = [inbox allKeys];
    id aKey = [keys objectAtIndex:indexPath.section];
    
	NSArray *items = [inbox objectForKey:aKey];
	InboxViewItem *item = [items objectAtIndex:indexPath.row];
    
    // Here should follow big switch
    inboxCell.subject.text = item.subject;
    inboxCell.message.text = item.message;
    inboxCell.misc.text = item.misc;
    inboxCell.mainImage.shoulCacheCircledImage = YES;
    if ( [item.fromId compare:strCurrentUserId] == NSOrderedSame && item.type != INBOX_ITEM_COMMENT )
        [inboxCell.mainImage loadImageFromURL:[Person imageURLWithId:item.toId]];
    else
        [inboxCell.mainImage loadImageFromURL:[Person imageURLWithId:item.fromId]];
    
	return inboxCell;
}

- (void)openPersonWindow:(Person*)person
{
    UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
    [userProfileController setPerson:person];
    [self.navigationController pushViewController:userProfileController animated:YES];
}

- (void)openMeetupWindow:(Meetup*)meetup invite:(Boolean)bInvite
{
    // Loading window
    if ( ! meetup )
        return;
    
    MeetupViewController *meetupController = [[MeetupViewController alloc] initWithNibName:@"MeetupView" bundle:nil];
    [meetupController setMeetup:meetup];
    if ( bInvite )  // Already responded
        [meetupController setInvite];
    [self.navigationController pushViewController:meetupController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger nRow = indexPath.row;
    NSInteger nSection = indexPath.section;
    
    NSArray *keys = [inbox allKeys];
    id aKey = [keys objectAtIndex:nSection];
    
	NSArray *items = [inbox objectForKey:aKey];
    InboxViewItem* item = [items objectAtIndex:nRow];
    
    // Another switch depending on item type
    if ( item.type == INBOX_ITEM_INVITE || item.type == INBOX_ITEM_COMMENT )
    {
        Meetup* meetup = [globalData getMeetupById:[item.data objectForKey:@"meetupId"]];
        Boolean bInvite = ( ! item.misc && item.type == INBOX_ITEM_INVITE );
        
        if ( meetup)
            [self openMeetupWindow:meetup invite:bInvite];
        else // Fetching if needed
        {
            PFObject *meetupData = [item.data objectForKey:@"meetupData"];
            [self.activityIndicator startAnimating];
            self.navigationController.view.userInteractionEnabled = FALSE;
            [meetupData fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if ( ! error )
                {
                    Meetup* newMeetup = [[Meetup alloc] init];
                    [newMeetup unpack:meetupData];
                    [globalData addMeetup:newMeetup];
                    [self openMeetupWindow:newMeetup invite:bInvite];
                }
                else
                {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"No connection!" message:@"There were problems loading the thread or meetup you selected. Please, check your internet connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [message show];
                }
                [self.activityIndicator stopAnimating];
                self.navigationController.view.userInteractionEnabled = TRUE;
            }];
        }
    }
    else if ( item.type == INBOX_ITEM_MESSAGE )
    {
        // Retrieving person data
        Message* message = item.data;
        PFUser* personData;
        NSString* strId;
        if ( [message.strUserFrom compare:strCurrentUserId] == NSOrderedSame )
        {
            personData = message.objUserTo;
            strId = message.strUserTo;
        }
        else
        {
            personData = message.objUserFrom;
            strId = message.strUserFrom;
        }
        
        Person* person = [globalData getPersonById:strId];
        
        if ( person )
            [self openPersonWindow:person];
        else // fetching if needed
        {
            [self.activityIndicator startAnimating];
            self.navigationController.view.userInteractionEnabled = FALSE;
            [personData fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if ( ! error )
                {
                    Person* personNew = [globalData addPerson:personData userCircle:CIRCLE_RANDOM];
                    if ( personNew )
                        [self openPersonWindow:personNew];
                }
                else
                {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"No connection!" message:@"There were problems loading the person you selected. Please, check your internet connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [message show];
                }
                [self.activityIndicator stopAnimating];
                self.navigationController.view.userInteractionEnabled = TRUE;
            }];
        }
    }
    else if ( item.type == INBOX_ITEM_NEWUSER )
    {
        // This person is always fetched as we already loaded it to find out that it's new
        Person* person = item.data;
        
        // Removing from new
        [globalData removeUserFromNew:person.strId];
        
        // Opening profile
        [self openPersonWindow:person];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) dismissMeetup
{
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

@end
