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

@implementation LoginViewController

-(void)setPersonList:(NSMutableArray*)list
{
    listPersons = list;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

	}
	return self;
}

- (IBAction)touchDown:(UIButton *)sender
{
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
                NSLog(@"User signed up and logged in through Facebook!");
            else
            {
                NSLog(@"User logged in through Facebook!");
                [[PFUser currentUser] refresh];
            }
        }
    }];
    
/*    // Retrieving and saving to db current user data
    PF_FBRequest *request = [PF_FBRequest requestForMe];
    [request startWithCompletionHandler:^(PF_FBRequestConnection *connection,
                                           id result, NSError *error) {
        if (!error) {
             // Store the current user's Facebook ID on the user
             [[PFUser currentUser] setObject:[result objectForKey:@"id"]
                                      forKey:@"fbId"];
             [[PFUser currentUser] setObject:[result objectForKey:@"name"]
                                      forKey:@"fbName"];
             [[PFUser currentUser] setObject:[result objectForKey:@"birthday"]
                                      forKey:@"fbBirthday"];
             [[PFUser currentUser] setObject:[result objectForKey:@"gender"]
                                      forKey:@"fbGender"];
             [[PFUser currentUser] save];
        }
    }];
    
    // FB friendlist
    PF_FBRequest *request2 = [PF_FBRequest requestForMyFriends];
    [request2 startWithCompletionHandler:^(PF_FBRequestConnection *connection,
                                            id result, NSError *error) {
        if (!error) {
            // result will contain an array with your user's friends in the "data" key
            NSArray *friendObjects = [result objectForKey:@"data"];
            NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
        
            // Create a list of friends' Facebook IDs
            for (NSDictionary *friendObject in friendObjects) {
                [friendIds addObject:[friendObject objectForKey:@"id"]];
            }
             
            // Saving user friends
            [[PFUser currentUser] addUniqueObjectsFromArray:friendIds
                                                      forKey:@"fbFriends"];
             
            // Construct a PFUser query that will find friends whose facebook ids
            // are contained in the current user's friend list.
            PFQuery *friendQuery = [PFUser query];
            [friendQuery whereKey:@"fbId" containedIn:friendIds];
             
            // findObjects will return a list of PFUsers that are friends
            // with the current user
            NSArray *friendUsers = [friendQuery findObjects];
            
            for (NSDictionary *friendUser in friendUsers)
            {
                NSMutableArray *friendFriendIds = [friendUser objectForKey:@"fbFriends"];
                [[PFUser currentUser] addUniqueObjectsFromArray:friendFriendIds forKey:@"fbFriends2O"];
            }
             
            [[PFUser currentUser] save];
            
            // Second circle friends
            NSMutableArray *friend2OIds = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
            PFQuery *friend2OQuery = [PFUser query];
            [friend2OQuery whereKey:@"fbId" containedIn:friend2OIds];
            NSArray *friend2OUsers = [friend2OQuery findObjects];
            for (NSDictionary *friend2OUser in friend2OUsers)
            {
                NSString *strId = [friend2OUser objectForKey:@"fbId"];
                if ( [strId compare:[ [PFUser currentUser] objectForKey:@"fbId"] ] == NSOrderedSame )
                    continue;
                NSString* strName = [friend2OUser objectForKey:@"fbName"];
                 
                Person *person = [[Person alloc] init:@[strName, strId, [friend2OUser
                        objectForKey:@"fbBirthday"], [friend2OUser objectForKey:@"fbGender"]]];
                [listPersons addObject:person];
            }
            
            // First circle friends
            for (NSString *strId in friendIds)
            {
                Person *person = [[Person alloc] init:@[@"Your friend", strId, @"Invite!", @""]];
                [listPersons addObject:person];
            }
        }
    }];*/
    
    if ( ! [PFUser currentUser] )
        return;
    
    // Showing profile (TODO: check if user was created, then skip this step)
    //[self.navigationController popViewControllerAnimated:false];
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

@end