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
    
    NSArray* items = @[@"Inbox", @"Explore", @"People", @"Profile", @"Logout"];
    NSArray* selectors = @[@"showInbox", @"showMap", @"showCicles", @"showUser", @"logout"];
    _items = [[NSMutableArray alloc] initWithArray:items];
    _selectors = [[NSMutableArray alloc] initWithArray:selectors];
    
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

-(void)logout{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Logout" message:@"Are you sure you want to logout? " delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
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


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [PFUser logOut];
        _mapViewController = nil;
        _rootViewController = nil;
        _profileViewController = nil;
        [self.appDelegate userDidLogout];
    }
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



@end
