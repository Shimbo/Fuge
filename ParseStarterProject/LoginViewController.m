//
//  LoginView.cpp
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/1/12.
//
//

#import <Parse/Parse.h>

#include "Person.h"
#include "LoginViewController.h"
#include "ProfileViewController.h"
#include "GlobalVariables.h"
#import "PushManager.h"
#import "ParseStarterProjectAppDelegate.h"

@implementation LoginViewController

@synthesize activityIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	}
	return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    self.title = @"Welcome";
}

- (IBAction)touchDown:(UIButton *)sender
{
    // Activity indicator
    CGPoint ptCenter = CGPointMake(self.navigationController.view.frame.size.width/2, self.navigationController.view.frame.size.height/2);
    activityIndicator.center = ptCenter;
    [self.navigationController.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    self.view.userInteractionEnabled = NO;
    
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error)
    {
        if (!user)
        {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
        }
        else
        {
            if (user.isNew)
            {
                [globalVariables setNewUser];
                NSLog(@"User signed up and logged in through Facebook!");
            }
            else
            {
                NSLog(@"User logged in through Facebook!");
                [[PFUser currentUser] refresh];
            }
            
            // Push channels initialization
            [pushManager initChannelsFirstTime];
        }
        
        [activityIndicator stopAnimating];
        [activityIndicator removeFromSuperview];
        self.view.userInteractionEnabled = YES;
        
        if ( [PFUser currentUser] )
        {
            // Showing profile (TODO: check if user was created, then skip this step)
            //[self.navigationController popViewControllerAnimated:false];
            ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
            [self.navigationController pushViewController:profileViewController animated:YES];
            ParseStarterProjectAppDelegate *delegate = AppDelegate;
            [delegate userDidLogin];
        }
    }];
}

@end