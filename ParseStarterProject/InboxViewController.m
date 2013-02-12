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

#import "UserProfileController.h"

@implementation InboxViewItem
@end

@implementation InboxViewController

@synthesize activityIndicator;

#define ROW_HEIGHT 60

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        inbox = [[NSMutableDictionary alloc] init];
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
    
    // Loading
    [TestFlight passCheckpoint:@"Inbox opened"];
    [self reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    activityIndicator.center = self.view.center;
}


- (void) reloadData {
    //[activityIndicator startAnimating];
    //self.navigationController.view.userInteractionEnabled = NO;
    
    // Loading data
    NSArray* inboxData = [globalData getInbox];
    
    // Creating temporary overal array
    NSMutableArray* tempArray = [[NSMutableArray alloc] init];
    for ( id object in inboxData )
    {
        InboxViewItem* item = [[InboxViewItem alloc] init];
        if ( [object isKindOfClass:[PFObject class]] )
        {
            PFObject* pObject = object;
            if ( [[pObject className] compare:@"Message"] == NSOrderedSame )
            {
                item.type = INBOX_ITEM_MESSAGE;
                item.subject = [pObject objectForKey:@"nameUserFrom"];
                item.fromId = [pObject objectForKey:@"idUserFrom"];
                item.message = [pObject objectForKey:@"text"];
                item.misc = nil;
                item.data = pObject;
                item.dateTime = pObject.createdAt;
                [tempArray addObject:item];
            }
        }
    }
    
    // Creating arrays
    [inbox removeAllObjects];
    NSMutableArray* inboxNew = [[NSMutableArray alloc] init];
    NSMutableArray* inboxRecent = [[NSMutableArray alloc] init];
    NSMutableArray* inboxOld = [[NSMutableArray alloc] init];
    
    // Parsing data
    NSDate* dateRecent = [[NSDate alloc] initWithTimeIntervalSinceNow:-24*60*60*7];
    for ( InboxViewItem* item in tempArray )
    {
        if ( [item.dateTime compare:dateRecent] == NSOrderedDescending )
            [inboxRecent addObject:item];
        else
            [inboxOld addObject:item];
    }
    
    if ( [inboxNew count] > 0 )
        [inbox setObject:inboxNew forKey:@"New"];
    if ( [inboxRecent count] > 0 )
        [inbox setObject:inboxRecent forKey:@"Recent"];
    if ( [inboxOld count] > 0 )
        [inbox setObject:inboxOld forKey:@"Old"];
    
    
    
    self.tableView.alpha = 0;
    [[self tableView] reloadData];
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.alpha = 1;
    }];
    
    [TestFlight passCheckpoint:@"Inbox loaded from data"];
    
    //[activityIndicator stopAnimating];
    //self.navigationController.view.userInteractionEnabled = YES;
    //[self.navigationController popViewControllerAnimated:TRUE];
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
    inboxCell.mainImage = item.iconImage;
    inboxCell.subject.text = item.subject;
    inboxCell.message.text = item.message;
    inboxCell.misc.text = item.misc;
    
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
    if ( item.type == INBOX_ITEM_MESSAGE )
    {
        // TODO: what if person is unknown and not in our global data? We should load him/her!
        Person* person = [globalData getPersonById:item.fromId];
        if ( person )
        {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [self.navigationController pushViewController:userProfileController animated:YES];
            [userProfileController setPerson:person];
        }
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
