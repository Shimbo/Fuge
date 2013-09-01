//
//  MeetupInviteViewController.m
//  SecondCircle
//
//  Created by Constantine Fry on 3/8/13.
//
//

#import "MeetupInviteViewController.h"
#import "Person.h"
#import "Circle.h"
#import "GlobalVariables.h"
#import "GlobalData.h"
#import "PersonInviteCell.h"
#import "MeetupInviteSearch.h"
#import "PushManager.h"
#import "FacebookLoader.h"

@implementation MeetupInviteViewController
- (id)init
{
    self = [super init];
    if (self) {
        selected = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        meetup = nil;
        selected = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

static NSMutableArray* invitesLeft = nil;

-(void)sendNextInvite
{
    if ( ! invitesLeft ) return;
    if ( invitesLeft.count == 0 ) return;
    
    Person* person = [invitesLeft objectAtIndex:0];
    [globalData createInvite:meetup stringTo:person.strId target:self selector:@selector(sendNextInvite)];
    [invitesLeft removeObjectAtIndex:0];
}

-(void)done{
    
    // Creating invites
    if ( meetup )
    {
        invitesLeft = [NSMutableArray arrayWithCapacity:[self selectedPersons].count];
        for ( Person* person in [self selectedPersons])
            if ( ! [meetup hasAttendee:person.strId] )
                [invitesLeft addObject:person];
        [self sendNextInvite];
    }
    
    // Facebook invites
    NSMutableArray* arrayIds = [NSMutableArray arrayWithCapacity:10];
    for ( Person* person in [self selectedPersons])
        if ( person.idCircle == CIRCLE_FBOTHERS )
            [arrayIds addObject:person.strId];
    NSString* invitationString = [NSString stringWithFormat:NSLocalizedString(@"FB_INVITE_MESSAGE_MEETUP",nil), meetup.strSubject ];
    [fbLoader showInviteDialog:arrayIds message:invitationString];
    
    // Saving recent
    if ( [self selectedPersons].count > 0 )
    {
        NSArray* arrayRecentIds = (NSArray*)[_recentPersons valueForKeyPath:@"strId"];
        NSMutableArray* arrayNewIds = [[NSMutableArray alloc] initWithArray:[[self selectedPersons] valueForKeyPath:@"strId"]];
        for ( Person* person in [self selectedPersons])
            if ( person.idCircle != CIRCLE_FBOTHERS )
                [arrayNewIds addObject:person.strId];
        if ( arrayNewIds.count > MAX_RECENT_PEOPLE_COUNT )
            [arrayNewIds removeObjectsInRange:NSMakeRange(MAX_RECENT_PEOPLE_COUNT, arrayNewIds.count-1)];
        NSInteger m = arrayRecentIds.count - 1;
        for ( NSUInteger n = arrayNewIds.count; n < MAX_RECENT_PEOPLE_COUNT; n++ )
        {
            if ( m < 0 ) break;
            if ( ! [arrayNewIds containsObject:arrayRecentIds[m]] )
                [arrayNewIds addObject:arrayRecentIds[m]];
            m--;
        }
        [globalData setRecentInvites:arrayNewIds];
    }
    
    // Push for everybody NOT invited and only in case meetup will happen in next 12 hours
    if ( bNewMeetup )
        if ( meetup.privacy == MEETUP_PUBLIC )
            if ( [meetup.dateTime compare:[NSDate dateWithTimeIntervalSinceNow:PUSH_DISCOVERY_WINDOW]]
                    == NSOrderedAscending)
                [pushManager sendPushCreatedMeetup:meetup.strId ignore:[self selectedPersons]];
    
    // Focusing on meetup and adding to calendar here
    [self dismissViewControllerAnimated:YES completion:^{
        if ( bNewMeetup && meetup.meetupType == TYPE_MEETUP )
        {
            NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:meetup, @"meetup", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMeetupCreated object:nil userInfo:userInfo];
//            [meetup addToCalendar];
        }
    }];
}

static Boolean bTurnOn = true;

- (void)addAll
{
    for (NSInteger j = 0; j < [tableViewInvites numberOfSections]; ++j)
        for (NSInteger i = 0; i < [tableViewInvites numberOfRowsInSection:j]; ++i)
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:j];
            UITableViewCell *cell = [tableViewInvites cellForRowAtIndexPath:indexPath];
            Person *person = [self getArrayForSectionNumber:indexPath.section][indexPath.row];
            if ( bTurnOn )
            {
                selected[person.strId] = person;
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else
            {
                [selected removeObjectForKey:person.strId];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    [tableViewInvites reloadData];
    bTurnOn = ! bTurnOn;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Invite";
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *addAll = [[UIBarButtonItem alloc] initWithTitle:@"Select all" style:UIBarButtonItemStyleBordered target:self action:@selector(addAll)];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    [self.navigationItem setLeftBarButtonItem:addAll];
    [self.navigationItem setRightBarButtonItem:done];
    
    UINib *nib = [UINib nibWithNibName:@"PersonInviteCell" bundle:nil];
    [tableViewInvites registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    
    searcher = [[MeetupInviteSearch alloc]init];
    searcher.selected = selected;
    self.searchDisplayController.searchResultsDelegate = searcher;
    self.searchDisplayController.searchResultsDataSource = searcher;
    self.searchDisplayController.searchBar.delegate = searcher;
    
    
    NSPredicate *predicateRecent = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        Person* person = evaluatedObject;
        NSArray* ids = (NSArray*)[_recentPersons valueForKeyPath:@"strId"];
        Boolean bFound = [ids indexOfObjectIdenticalTo:person.strId] != NSNotFound;
        return ! bFound;
    }];
    NSPredicate* predicateRandom = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        Person* person = evaluatedObject;
        NSArray* ids = (NSArray*)[_recentPersons valueForKeyPath:@"strId"];
        Boolean bFound = [ids indexOfObjectIdenticalTo:person.strId] != NSNotFound;
        if ( bFound )
            return FALSE;
        if ( bIsAdmin )
            return TRUE;
        if ( [selected objectForKey:person.strId] )
            return TRUE;
        return FALSE;
    }];
    
    _recentPersons = [globalData getRecentPersons];
    _firstCircle = [[[globalData getCircle:CIRCLE_FB] getPersons]
                    filteredArrayUsingPredicate:predicateRecent];
    _otherPersons = [[[globalData getCircle:CIRCLE_RANDOM] getPersons]
                     filteredArrayUsingPredicate:predicateRandom];
    _facebookFriends = [[[globalData getCircle:CIRCLE_FBOTHERS] getPersons]
                        filteredArrayUsingPredicate:predicateRecent];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView{
    searcher.searchResult = nil;
    searcher.tableView = self.searchDisplayController.searchResultsTableView;
    UINib *nib = [UINib nibWithNibName:@"PersonInviteCell" bundle:nil];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView{
    [tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
//    NSInteger nCount = [[globalData getCircles] count];
	return 4;
}

-(NSUInteger)translateSectionNumberToCircleNumber:(NSUInteger)section{
    if (section == 1) {
        return CIRCLE_FB;
    }
    else if (section == 2){
        return CIRCLE_RANDOM;
    }
    else if (section == 3){
        return CIRCLE_FBOTHERS;
    }
    return CIRCLE_NONE;
}

-(NSArray*)getArrayForSectionNumber:(NSUInteger)section{
    switch (section) {
        case 0:
            return _recentPersons;
        case 1:
            return _firstCircle;
        case 2:
            return _otherPersons;
        case 3:
            return _facebookFriends;
    }
	return nil;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	// Number of rows is the number of time zones in the region for the specified section
    return [[self getArrayForSectionNumber:section] count];
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
    if ([self getArrayForSectionNumber:section].count == 0)
        return nil;
    
    if (section == 0)
        return @"Recent";
    Circle *circle = [globalData getCircle:[self translateSectionNumberToCircleNumber:section]];
	return [Circle getCircleName:circle.idCircle];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
	static NSString *CellIdentifier = @"PersonCellIdent";
    
	PersonInviteCell *personCell = (PersonInviteCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	// Get the time zones for the region for the section
	Person *person = [self getArrayForSectionNumber:indexPath.section][indexPath.row];
    personCell.personName.text = [person fullName];
    [personCell.personImage loadImageFromURL:person.smallAvatarUrl];
    if ([selected objectForKey:person.strId]) {
        personCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        personCell.accessoryType = UITableViewCellAccessoryNone;
    }
	return personCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	Person *person = [self getArrayForSectionNumber:indexPath.section][indexPath.row];
    
    if ([selected objectForKey:person.strId]) {
        [selected removeObjectForKey:person.strId];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        selected[person.strId] = person;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

-(NSArray*)selectedPersons{
    return selected.allValues;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

-(void)setMeetup:(Meetup*)m newMeetup:(Boolean)new;
{
    meetup = m;
    bNewMeetup = new;
}

-(void)addInvitee:(Person*)i
{
    selected[i.strId] = i;
}

@end
