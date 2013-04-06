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
    
    // Loading
    [TestFlight passCheckpoint:@"Inbox appeared"];
    [self reloadData];
}

- (void) reloadClicked
{
    [globalData reloadInbox:self];
    [self reloadData];
}

- (void) reloadData {
    
    inbox = [globalData getInbox:self];
    
    if ( ! inbox )
    {
        [self.activityIndicator startAnimating];
        self.navigationController.view.userInteractionEnabled = NO;
    }
    else
    {
        [TestFlight passCheckpoint:@"Inbox loaded from data"];
        
        [[self tableView] reloadData];
        
        [self.activityIndicator stopAnimating];
        self.navigationController.view.userInteractionEnabled = YES;
    }
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
    if ( [item.fromId compare:strCurrentUserId] == NSOrderedSame )
        [inboxCell.mainImage loadImageFromURL:[Person imageURLWithId:item.toId]];
    else
        [inboxCell.mainImage loadImageFromURL:[Person imageURLWithId:item.fromId]];
    
	return inboxCell;
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
        PFObject *meetupData = [item.data objectForKey:@"meetupData"];
        NSError* error;
        [meetupData fetchIfNeeded:&error];
        
        if ( ! error )
        {
            MeetupViewController *meetupController = [[MeetupViewController alloc] initWithNibName:@"MeetupView" bundle:nil];
            Meetup* meetup = [[Meetup alloc] init];
            [meetup unpack:meetupData];
            [globalData addMeetup:meetup];
            [meetupController setMeetup:meetup];
            if ( ! item.misc && item.type == INBOX_ITEM_INVITE )  // Already responded
                [meetupController setInvite];
            [self.navigationController pushViewController:meetupController animated:YES];
            
            //self.navigationItem.leftItemsSupplementBackButton = true;
            //UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:meetupController];
            //[self.navigationController presentViewController:navigation animated:YES completion:nil];
        }
    }
    else if ( item.type == INBOX_ITEM_MESSAGE )
    {
        // Retrieving person data
        Message* message = item.data;
        [message fetchUserIfNeeded];
        
        PFUser* personData;
        if ( [message.strUserFrom compare:strCurrentUserId] == NSOrderedSame )
            personData = message.objUserTo;
        else
            personData = message.objUserFrom;
        
        // Trying to get this person if in one of our circles
        NSString* strId = [personData objectForKey:@"fbId"];
        Person* person = [globalData getPersonById:strId];
        
        // Creating person if not
        if ( ! person )
            person = [[Person alloc] init:personData circle:CIRCLE_RANDOM];
        
        // Opening profile
        if ( person )
        {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [self.navigationController pushViewController:userProfileController animated:YES];
            [userProfileController setPerson:person];
        }
    }
    else if ( item.type == INBOX_ITEM_NEWUSER )
    {
        Person* person = item.data;
        
        // Removing from new
        [globalData removeUserFromNew:person.strId];
        
        // Opening profile
        if ( person )
        {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [self.navigationController pushViewController:userProfileController animated:YES];
            [userProfileController setPerson:person];
        }
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) dismissMeetup
{
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

@end
