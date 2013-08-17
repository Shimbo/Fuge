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

-(void)done{
    
    // Creating invites
    if ( meetup )
        for ( Person* person in [self selectedPersons])
            if ( ! [meetup hasAttendee:person.strId] )
                [globalData createInvite:meetup stringTo:person.strId];
    
    // Facebook invites
    NSMutableString* strInvitations = [NSMutableString stringWithString:@""];
    for ( Person* person in [self selectedPersons])
        if ( person.idCircle == CIRCLE_FBOTHERS )
            [strInvitations appendFormat:@"%@,", person.strId];
    if ( strInvitations.length > 0 )
    {
        [strInvitations substringToIndex:strInvitations.length-2];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:strInvitations, @"to", nil];
        NSString* invitationString = [NSString stringWithFormat:NSLocalizedString(@"FB_INVITE_MESSAGE_MEETUP",nil), meetup.strSubject ];
        [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:invitationString title:nil parameters:params handler:nil];
    }
    
    // Saving recent
    NSMutableArray* arrayRecentIds = [[NSMutableArray alloc] init];
    for ( Person* person in [self selectedPersons])
        if ( person.idCircle != CIRCLE_FBOTHERS )
                [arrayRecentIds addObject:person.strId];
    [globalData addRecentInvites:arrayRecentIds];
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Invite";
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    [self.navigationItem setRightBarButtonItem:done];
    
    
    UINib *nib = [UINib nibWithNibName:@"PersonInviteCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    
    searcher = [[MeetupInviteSearch alloc]init];
    searcher.selected = selected;
    self.searchDisplayController.searchResultsDelegate = searcher;
    self.searchDisplayController.searchResultsDataSource = searcher;
    self.searchDisplayController.searchBar.delegate = searcher;
    
    
    // This code works! Use it for recent users!
    _recentPersons = [globalData getRecentPersons];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self.strId in %@)",
                              [_recentPersons valueForKeyPath:@"strId"]];
    _firstCircle = [[[globalData getCircle:CIRCLE_FB] getPersons]
                    filteredArrayUsingPredicate:predicate];
    
    _facebookFriends = [[[globalData getCircle:CIRCLE_FBOTHERS] getPersons]
                        filteredArrayUsingPredicate:predicate];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView{
    searcher.searchResult = nil;
    searcher.tableView = self.searchDisplayController.searchResultsTableView;
    UINib *nib = [UINib nibWithNibName:@"PersonInviteCell" bundle:nil];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
//    NSInteger nCount = [[globalData getCircles] count];
	return 3;
}

-(NSUInteger)translateSectionNumberToCircleNumber:(NSUInteger)section{
    if (section == 1) {
        return CIRCLE_FB;
    }
    else if (section == 2){
        return CIRCLE_FBOTHERS;
    }
    return CIRCLE_NONE;
}

-(NSArray*)getArrayForSectionNumber:(NSUInteger)section{
    switch (section) {
        case 0:
            return _recentPersons;
            break;
        case 1:
            return _firstCircle;
            break;
        case 2:
            return _facebookFriends;
            break;
        default:
            break;
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
    [self setTableView:nil];
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
