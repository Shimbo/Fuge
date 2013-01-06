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

@implementation LoginViewController

@synthesize activityIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	}
	return self;
}

- (void)subscribeFinished:(NSNumber *)result error:(NSError *)error {
    if ([result boolValue]) {
        NSLog(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
    } else {
        NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
    }
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
            
            // Login and push stuff
            NSString* strUserChannel =[[NSString alloc] initWithFormat:@"fb%@", [user objectForKey:@"fbId"]];
            [[PFInstallation currentInstallation] addUniqueObject:strUserChannel forKey:@"channels"];
            [[PFInstallation currentInstallation] addUniqueObject:@"" forKey:@"channels"];
            [[PFInstallation currentInstallation] saveEventually];
            [PFPush subscribeToChannelInBackground:@"" target:self selector:@selector(subscribeFinished:error:)];
            [PFPush subscribeToChannelInBackground:strUserChannel target:self selector:@selector(subscribeFinished:error:)];
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
        }
    }];
}

@end