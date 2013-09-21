//
//  LeftMenuController.m
//  SecondCircle
//
//  Created by Constantine Fry on 2/5/13.
//
//

#import "LeftMenuController.h"
#import "InboxViewController.h"
#import "MapViewController.h"
#import "ProfileViewController.h"
#import <Parse/Parse.h>
#import "RootViewController.h"
#import "StatsViewController.h"
#import "GlobalData.h"
#import "CustomBadge.h"
#import "UserProfileController.h"
#import "MeetupLoader.h"
#import "LoadingController.h"

#define ALERT_ENTER_STATUS      1
#define ALERT_IMPORT_MEETUP     2

@implementation LeftMenuController
- (id)init
{
    self = [super init];
    if (self) {
        self.appDelegate = AppDelegate;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_inboxBadge setNumber:[globalData getInboxUnreadCount]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifdef TARGET_FUGE
    _items = [NSMutableArray arrayWithObjects:NSLocalizedString(@"MENU_ITEM_EXPLORE",nil), NSLocalizedString(@"MENU_ITEM_INBOX",nil), NSLocalizedString(@"MENU_ITEM_PEOPLE",nil), NSLocalizedString(@"MENU_ITEM_STATUS",nil), NSLocalizedString(@"MENU_ITEM_SETTINGS",nil),  nil];
    _selectors = [NSMutableArray arrayWithObjects:@"showMap", @"showInbox", @"showCircles", @"askStatus", @"showUser", nil];
#elif defined TARGET_S2C
    _items = [NSMutableArray arrayWithObjects:NSLocalizedString(@"MENU_ITEM_PEOPLE",nil), NSLocalizedString(@"MENU_ITEM_INBOX",nil), NSLocalizedString(@"MENU_ITEM_EXPLORE",nil), NSLocalizedString(@"MENU_ITEM_STATUS",nil), NSLocalizedString(@"MENU_ITEM_SETTINGS",nil),  nil];
    _selectors = [NSMutableArray arrayWithObjects:@"showCircles", @"showInbox", @"showMap", @"askStatus", @"showUser", nil];
#endif
    
    if ( [globalVariables isUserAdmin])
    {
        [_items addObject:@"* Stats"];
        [_selectors addObject:@"showStats"];
        [_items addObject:@"* Import meetup"];
        [_selectors addObject:@"importMeetup"];
        [_items addObject:@"* Demo mode"];
        [_selectors addObject:@"showDemo"];
    }

    _inboxBadge = [CustomBadge secondCircleCustomBadge];
}


-(void)showInbox{
    InboxViewController *inboxViewController = [[InboxViewController alloc] initWithNibName:@"InboxViewController" bundle:nil];
    [self showViewController:inboxViewController];
}

-(void)showCircles{
    if (!_rootViewController) {
        _rootViewController = [[RootViewController alloc]initWithNibName:@"RootViewController" bundle:nil];
    }
    [self showViewController:_rootViewController];
}

-(void)showUser{
    if (!_profileViewController) {
        _profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    }
    if (_mapViewController || _rootViewController)
        _profileViewController.main = YES;
    [self showViewController:_profileViewController];
}

-(void)showDemo{
    LoadingController* loading = [[LoadingController alloc] initWithNibName:@"LoadingController" bundle:nil];
    loading.bDemoMode = TRUE;
    [self showViewController:loading];
}

-(void)prepareMap
{
    if (!_mapViewController) {
        _mapViewController = [[MapViewController alloc] initWithNibName:@"MapView" bundle:nil];
    }
}

-(void)showMap{
    if (!_mapViewController) {
        _mapViewController = [[MapViewController alloc] initWithNibName:@"MapView" bundle:nil];
    }
    [self showViewController:_mapViewController];
}

-(void)showViewController:(UIViewController*)ctrl{
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:ctrl];
    [self.appDelegate.revealController setFrontViewController:nav
                                             focusAfterChange:YES completion:nil];
}

-(void)askStatus{
    
    statusPrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STATUS_WINDOW_TITLE",nil)
            message:NSLocalizedString(@"STATUS_WINDOW_TEXT",nil) delegate:self
            cancelButtonTitle:NSLocalizedString(@"STATUS_WINDOW_BTN_SKIP",nil)
            otherButtonTitles:NSLocalizedString(@"STATUS_WINDOW_BTN_ENTER",nil), nil];
    statusPrompt.tag = ALERT_ENTER_STATUS;
    [statusPrompt setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[statusPrompt textFieldAtIndex:0] setDelegate:self];
    NSString* strCurrentStatus = currentPerson.strStatus;
    if ( strCurrentStatus && strCurrentStatus.length > 0 )
        [[statusPrompt textFieldAtIndex:0] setPlaceholder:strCurrentStatus];
    else
        [[statusPrompt textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"STATUS_WINDOW_PLACEHOLDER",nil)];
    [[statusPrompt textFieldAtIndex:0] setFont:[UIFont systemFontOfSize:14]];
    [statusPrompt show];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > TEXT_MAX_STATUS_LENGTH) ? NO : YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if ( statusPrompt )
        [statusPrompt dismissWithClickedButtonIndex:statusPrompt.firstOtherButtonIndex animated:YES];
    return YES;
}

- (void)meetupCallback:(NSDictionary*)meetupData
{
    if ( ! meetupData )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Meetup not found" message:@"Probably, wrong id" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
    
    NSLog(@"Meetup: %@", meetupData);
    NSString* strId = [ [NSString alloc] initWithFormat:@"mtmt_%@", [meetupData objectForKey:@"id"]];
    PFQuery *meetupQuery = [PFQuery queryWithClassName:@"Meetup"];
    [meetupQuery whereKey:@"meetupId" equalTo:strId];
    [meetupQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if ( object )
        {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Meetup already exists" message:@"This meetup was already added" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];
        }
        else
        {
            Meetup* meetup = [[Meetup alloc] initWithMtEvent:meetupData];
            if ( ! meetup )
            {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Meetup initizalization failed" message:@"Check the data." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];
            }
            else
            {
                Boolean bSaved = [meetup save:nil selector:nil];
                if ( bSaved )
                {
                    [globalData addMeetup:meetup];
                    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:meetup, @"meetup", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMeetupCreated object:nil userInfo:userInfo];
                }
                else
                {
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Meetup save failed" message:@"Probably, no connection. Try it all again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [errorAlert show];
                }
            }
        }
    }];
}

- (void)meetupsListCallback:(NSDictionary*)meetupsData
{
    NSEnumerator *enumerator = [meetupsData objectEnumerator];
    NSDictionary* meetupData = nil;
    while ( (meetupData = [enumerator nextObject]) != nil) {
        NSLog(@"Meetup: %@", meetupsData);
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if ( alertView.tag == ALERT_ENTER_STATUS )
    {
        if (buttonIndex == 1)
        {
            NSString* strResult = [[alertView textFieldAtIndex:0] text];
            if ( strResult )
            {
                [pCurrentUser setObject:strResult forKey:@"profileStatus"];
                [pCurrentUser setObject:[NSDate date] forKey:@"profileStatusDate"];
                [pCurrentUser saveInBackground];
            }
        }
    } else if ( alertView.tag == ALERT_IMPORT_MEETUP ) {
        if (buttonIndex == 1)
        {
            NSString* strResult = [[alertView textFieldAtIndex:0] text];
            if ( strResult )
            {
                [mtLoader loadMeetup:strResult owner:self selector:@selector(meetupCallback:)];
                //[mtLoader loadMeetups:@"Interesting-Talks-London" owner:self selector:@selector(meetupsListCallback:)];
            }
        }
    }
    [self.appDelegate.revealController showViewController:self.appDelegate.revealController.frontViewController];
}

/*- (void)openPersonWindow:(Person*)person
{
    UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
    [userProfileController setPerson:person];
    [self.navigationController pushViewController:userProfileController animated:YES];
}


-(void)showFeedback{
    
    // Retrieving person data
    Person* person = [globalData getPersonById:FEEDBACK_BOT_ID];
    
    if ( person )
        [self openPersonWindow:person];
    else // fetching if needed
    {
        [activityIndicator startAnimating];
        self.navigationController.view.userInteractionEnabled = FALSE;
        
        PFQuery *userQuery = [PFUser query];
        [userQuery whereKey:@"fbId" equalTo:FEEDBACK_BOT_ID];
        [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            if ( error )
            {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Problem, chief" message:@"There were problems loading data. Please, check your internet connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [message show];
            }
            else
            {
                Person* personNew = [globalData addPerson:(PFUser*)object userCircle:CIRCLE_RANDOM];
                if ( personNew )
                    [self openPersonWindow:personNew];
            }
            [activityIndicator stopAnimating];
            self.navigationController.view.userInteractionEnabled = TRUE;
        }];
    }
}*/

-(void)showStats{
    StatsViewController *statsViewController = [[StatsViewController alloc] initWithNibName:@"StatsViewController" bundle:nil];
    [self showViewController:statsViewController];
}

-(void)importMeetup{
    statusPrompt = [[UIAlertView alloc] initWithTitle:@"Import meetup"
                                              message:@"Enter meetup ID from www.meetup.com" delegate:self
                                    cancelButtonTitle:@"Cancel" otherButtonTitles:@"Import", nil];
    statusPrompt.tag = ALERT_IMPORT_MEETUP;
    [statusPrompt setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[statusPrompt textFieldAtIndex:0] setDelegate:self];
    [[statusPrompt textFieldAtIndex:0] setFont:[UIFont systemFontOfSize:14]];
    [statusPrompt show];
}





- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ident = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident];
        if (indexPath.row == 1) {
            [cell insertSubview:_inboxBadge atIndex:100];
            _inboxBadge.center = CGPointMake(240, 22);
            [_inboxBadge setNumber:[globalData getInboxUnreadCount]];
        }
    }
    cell.textLabel.text = _items[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SEL selector = NSSelectorFromString(_selectors[indexPath.row]);
    [self performSelector:selector];
}

- (void) clean
{
    _mapViewController = nil;
    _rootViewController = nil;
    _profileViewController = nil;
}

@end
