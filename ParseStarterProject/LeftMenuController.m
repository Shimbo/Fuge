//
//  LeftMenuController.m
//  SecondCircle
//
//  Created by Constantine Fry on 2/5/13.
//
//

#import "LeftMenuController.h"
#import "MapViewController.h"
#import "ProfileViewController.h"
#import <Parse/Parse.h>


@interface LeftMenuController ()

@end

@implementation LeftMenuController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _items = @[@"Cycles",@"Map",@"User Profile",@"Logout"];
    _selectors = @[@"showCicles",@"showMap",@"showUser",@"logout"];
    self.appDelegate = AppDelegate;
}

-(void)showCicles{
    [self.appDelegate.revealController setFrontViewController:self.appDelegate.mainNavigation
     focusAfterChange:YES completion:nil];
}
-(void)showUser{
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    profileViewController.main = YES;
    [self showViewController:profileViewController];
}

-(void)showMap{
    MapViewController *mapViewController = [[MapViewController alloc] initWithNibName:@"MapView" bundle:nil];
    [self showViewController:mapViewController];
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


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [PFUser logOut];
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
