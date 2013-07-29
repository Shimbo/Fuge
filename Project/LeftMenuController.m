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
    
    _items = [NSMutableArray arrayWithObjects:NSLocalizedString(@"MENU_ITEM_INBOX",nil), NSLocalizedString(@"MENU_ITEM_PEOPLE",nil), NSLocalizedString(@"MENU_ITEM_EXPLORE",nil), NSLocalizedString(@"MENU_ITEM_STATUS",nil), NSLocalizedString(@"MENU_ITEM_SETTINGS",nil),  nil];
    _selectors = [NSMutableArray arrayWithObjects:@"showInbox", @"showCicles", @"showMap", @"askStatus", @"showUser", nil];
    
    if ( [globalVariables isUserAdmin])
    {
        [_items addObject:@"Stats"];
        [_selectors addObject:@"showStats"];
    }

    _inboxBadge = [CustomBadge secondCircleCustomBadge];
}


-(void)showInbox{
    InboxViewController *inboxViewController = [[InboxViewController alloc] initWithNibName:@"InboxViewController" bundle:nil];
    [self showViewController:inboxViewController];
}

-(void)showCicles{
    if (!_rootViewController) {
        _rootViewController = [[RootViewController alloc]initWithNibName:@"RootViewController" bundle:nil];
    }
    [self showViewController:_rootViewController];
}

-(void)showUser{
    if (!_profileViewController) {
        _profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    }
    if (_mapViewController)
        _profileViewController.main = YES;
    [self showViewController:_profileViewController];
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
    [statusPrompt setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[statusPrompt textFieldAtIndex:0] setDelegate:self];
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1)
    {
        NSString* strResult = [[alertView textFieldAtIndex:0] text];
        if ( strResult )
        {
            [pCurrentUser setObject:strResult forKey:@"profileStatus"];
            [pCurrentUser saveInBackground];
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




- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ident = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident];
        if (indexPath.row == 0) {
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
