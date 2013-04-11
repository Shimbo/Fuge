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
    
    NSArray* items = @[@"Inbox",@"Map",@"Circles",@"User Profile",@"Logout"];
    NSArray* selectors = @[@"showInbox",@"showMap",@"showCicles",@"showUser",@"logout"];
    _items = [[NSMutableArray alloc] initWithArray:items];
    _selectors = [[NSMutableArray alloc] initWithArray:selectors];
    
    if ( [globalData isUserAdmin])
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
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    if (_mapViewController)
        profileViewController.main = YES;
    [self showViewController:profileViewController];
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

-(void)showStats{
    StatsViewController *statsViewController = [[StatsViewController alloc] initWithNibName:@"StatsViewController" bundle:nil];
    [self showViewController:statsViewController];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [PFUser logOut];
        _mapViewController = nil;
        _rootViewController = nil;
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
