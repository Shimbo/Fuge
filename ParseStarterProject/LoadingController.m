//
//  LoadingController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 4/11/13.
//
//

#import "LoadingController.h"
#import "GlobalData.h"
#import "GlobalVariables.h"
#import "LeftMenuController.h"
#import "LocationManager.h"
#import "PushManager.h"
#import "ProfileViewController.h"

@implementation LoadingController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(proceedToMapWindow)
                                                name:kLoadingMainComplete
                                                object:nil];
    }
    return self;
}

// Versions
// TODO 2: call AppStore
// TODO 4: actually, just show a label (where news should be) and button Update.

- (Boolean) versionCheck
{
    // Checking version information
    PFQuery *systemQuery = [PFQuery queryWithClassName:@"System"];
    PFObject* system = [systemQuery getFirstObject];
    float minVersion = [[system objectForKey:@"minVersion"] floatValue];
    float curVersion = [[system objectForKey:@"curVersion"] floatValue];
    float thisVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] floatValue];
    if ( thisVersion < minVersion )
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"New version is out!" message:@"You're running old version of the application. Please, update first." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
        [message show];
        //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.com/apps/cut-the-rope"]];
        return false;
    }
    if ( thisVersion < curVersion )
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"New version is out!" message:@"You're running old version of the application. We recommend you updating the application." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Later",nil];
        [message show];
        //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.com/apps/cut-the-rope"]];
        //return NO;
    }
    
    return true;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Animation started
    [self.loadingIndicator startAnimating];
    //self.navigationController.view.userInteractionEnabled = NO;
    
    // Version check
    Boolean bShowAppStoreButton = ! [self versionCheck];
    if ( bShowAppStoreButton )
    {
        // Do some UI stuff
        return;
    }
    
    // Location data
    [locManager startUpdating];
    
    // Login or load
    if (! PFFacebookUtils.session.isOpen || ! [[PFUser currentUser] isAuthenticated])
    {
        [self.loadingIndicator stopAnimating];
        _loginButton.hidden = FALSE;
        _descriptionText.hidden = FALSE;
        _titleText.hidden = FALSE;
        _miscText.hidden = FALSE;
        _titleText.text = @"Welcome stranger!";
        _descriptionText.text = @"ThisApp is a location-based people \n discovery and messaging service. \n If sounds a bit complicated, betta try!";
    }
    else
    {
        [globalData loadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) showLoginButton
{
    
}

-(void) proceedToProfile
{
    ParseStarterProjectAppDelegate *delegate = AppDelegate;
    [delegate.revealController dismissViewControllerAnimated:TRUE completion:nil];
    LeftMenuController *leftMenu = (LeftMenuController*)delegate.revealController.leftViewController;
    [leftMenu showUser];
    
/*    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:profileViewController];
    [delegate.revealController presentViewController:nav animated:NO completion:nil];*/
}

-(void) proceedToMapWindow
{
    ParseStarterProjectAppDelegate *delegate = AppDelegate;
    [delegate.revealController dismissViewControllerAnimated:TRUE completion:nil];
    LeftMenuController *leftMenu = (LeftMenuController*)delegate.revealController.leftViewController;
    [leftMenu showMap];
}

- (void) loginFailed
{
    
}

- (IBAction)loginDown:(id)sender {
    
    // Activity indicator
    [self.loadingIndicator startAnimating];
    self.view.userInteractionEnabled = NO;
    
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error)
    {
         if ( ! user )
         {
             if (!error) {
                 NSLog(@"Uh oh. The user cancelled the Facebook login.");
             } else {
                 NSLog(@"Uh oh. An error occurred: %@", error);
             }
             [self loginFailed];
             return;
         }
         else
         {
             if (user.isNew)
             {
                 NSLog(@"User signed up and logged in through Facebook!");
                 [globalVariables setNewUser];
             }
             else
             {
                 NSLog(@"User logged in through Facebook!");
                 [[PFUser currentUser] refresh];
             }             
        }
        
        // Waiting for location data
        while ( ! [locManager getPosition] )
            sleep(100);
        // TODO: set text "Updating position"? check for failure normally
        // Check also what to do if user blocked loction services
        [globalData setUserPosition:[locManager getPosition]];
         
        // Continue to next window
        [self.loadingIndicator stopAnimating];
        self.view.userInteractionEnabled = YES;
        
        if ( [PFUser currentUser] )
        {
            // Show profile window if it's new user
            if ( [globalVariables isNewUser] )
            {
                [self proceedToProfile];
                [[NSNotificationCenter defaultCenter]removeObserver:self];
            }
            
            // Start loading data
            [globalData loadData];
         }
     }];
}

- (IBAction)retryDown:(id)sender {
}

- (IBAction)updateDown:(id)sender {
}
@end
