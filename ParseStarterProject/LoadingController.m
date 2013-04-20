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
#import <QuartzCore/QuartzCore.h>
#import "TestFlightSDK/TestFlight.h"

@implementation LoadingController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(mainComplete)
                                                name:kLoadingMainComplete
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(loadingFailed)
                                                name:kLoadingMainFailed
                                                object:nil];
        bVersionChecked = false;
        bAnimation = true;
        nAnimationStage = 0;
        _backgroundImage.alpha = 0.0f;
    }
    return self;
}

// Versions
// TODO 2: call AppStore
// TODO 4: actually, just show a label (where news should be) and button Update.

- (void)loadSequencePart0
{
    // Testflight
#ifndef RELEASE
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    @try {
        [TestFlight takeOff:@"d42a1f02-bb75-4c1e-896e-e0e4f41daf17"];
    }
    @catch (NSException *exception) {
        NSLog(@"TestFlight error: %@",exception);
    }
    [TestFlight passCheckpoint:@"Initialization phase 0"];
    
    // Parse
    [Parse setApplicationId:@"VMhSG8IQ9xibufk8lAPpclIwdXVfYD44OpKmsHdn"
                  clientKey:@"u2kJ1jWBjN9qY3ARlJuEyNkvUA9EjOMv1R4w5sDX"];
    
    // Facebook
    [PFFacebookUtils initializeFacebook];
    
    // ACL
    PFACL *defaultACL = [PFACL ACL];
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    // Zoom in animated
    _backgroundImage.alpha = 0.0f;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:1.0];
    _backgroundImage.alpha = 1.0f;
    [UIView commitAnimations];
    
    [self performSelector:@selector(loadSequencePart1) withObject:nil afterDelay:0.01f];
}

- (void)loadSequencePart1
{
    [TestFlight passCheckpoint:@"Initialization phase 1"];
    
    // Checking version information
    PFQuery *systemQuery = [PFQuery queryWithClassName:@"System"];
    [systemQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        if (error)
        {
            [self noInternet];
            return;
        }
        else
        {
            Boolean bShowAppStoreButton = false;
            
            PFObject* system = object;
            
            float minVersion = [[system objectForKey:@"minVersion"] floatValue];
            float curVersion = [[system objectForKey:@"curVersion"] floatValue];
            float thisVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] floatValue];
            if ( thisVersion < minVersion )
            {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"New version is out!" message:@"You're running old version of the application. Please, update first." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
                [message show];
                //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.com/apps/cut-the-rope"]];
                bShowAppStoreButton = TRUE;
            }
            if ( thisVersion < curVersion )
            {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"New version is out!" message:@"You're running old version of the application. We recommend you updating the application." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Later",nil];
                [message show];
                //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.com/apps/cut-the-rope"]];
                //return NO;
            }
            
            if ( bShowAppStoreButton )
            {
                // TODO: TODONOW: Do some UI stuff
            }
            else
            {
                bVersionChecked = true;
                [self performSelector:@selector(loadSequencePart2) withObject:nil afterDelay:0.01f];
            }
        }
    }];
}

- (void)loadSequencePart2
{
    [TestFlight passCheckpoint:@"Initialization phase 2"];
    
    // Location data
    [locManager startUpdating];
    
    // Login or load
    if (! PFFacebookUtils.session.isOpen || ! [[PFUser currentUser] isAuthenticated])
    {
        [self notLoggedIn];
    }
    else
    {
        [globalData loadData];
    }
}

- (void)animateHypno
{
    NSUInteger nOptions = UIViewAnimationOptionCurveLinear;
    if ( nAnimationStage == 0 )
        nOptions = UIViewAnimationOptionCurveEaseIn;
    if ( nAnimationStage == 2 )
        nOptions = UIViewAnimationOptionCurveEaseOut;
    float fPower = bAnimation ? M_PI/2 : M_PI/6;
    [UIView animateWithDuration: 0.5f delay: 0.0f options: nOptions animations: ^ {
        _backgroundImage.transform = CGAffineTransformRotate(_backgroundImage.transform, fPower);
    }
    completion: ^(BOOL finished) {
        
        if (nAnimationStage == 0)
            nAnimationStage = 1;
        if (nAnimationStage == 2)
            nAnimationStage = 0;
        
        [self animateHypno];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self animateHypno];
    
    [self performSelector:@selector(loadSequencePart0) withObject:nil afterDelay:0.01f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void) proceedToProfile
{
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    [self.navigationController presentViewController:profileViewController animated:TRUE completion:nil];
}

-(void) mainComplete
{
    // Show profile window if it's new user
    if ( [globalVariables isNewUser] )
        [self proceedToProfile];
    else
        [self proceedToMapWindow];
    
    [TestFlight passCheckpoint:@"Initialization main complete"];
}

-(void) proceedToMapWindow
{
    ParseStarterProjectAppDelegate *delegate = AppDelegate;
    [delegate.revealController dismissViewControllerAnimated:TRUE completion:nil];
    LeftMenuController *leftMenu = (LeftMenuController*)delegate.revealController.leftViewController;
    [leftMenu showMap];
}

- (void) loadingFailed
{
    NSUInteger nStatus = [globalData getLoadingStatus:LOADING_MAIN];
    if ( nStatus == LOAD_NOFACEBOOK )
        [self loginFailed];
    else
        [self noInternet];
}

- (void) hideAll
{
    _loginButton.hidden = TRUE;
    _retryButton.hidden = TRUE;
    _descriptionText.hidden = TRUE;
    _titleText.hidden = TRUE;
    _miscText.hidden = TRUE;
}

- (void) notLoggedIn
{
    bAnimation = false;
    _loginButton.hidden = FALSE;
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = FALSE;
    _titleText.text = @"Welcome stranger!";
    _descriptionText.text = @"ThisApp is a location-based people \n discovery and messaging service. \n If sounds a bit complicated, betta try!";
}

- (void) noInternet
{
    bAnimation = false;
    _loginButton.hidden = TRUE;
    _retryButton.hidden = FALSE;
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = TRUE;
    _titleText.text = @"Ooups!";
    _descriptionText.text = @"It seems like you don’t have internet \n connection at the moment. Try \n again if you’re so confident!";
}

- (void) loginFailed
{
    bAnimation = false;
    _loginButton.hidden = FALSE;
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = FALSE;
    _titleText.text = @"Ooups!";
    _descriptionText.text = @"Looks like you haven’t finished \n login process or wasn’t able to do so. \n Please, try again!";
}

- (IBAction)loginDown:(id)sender {
    
    // Activity indicator
    bAnimation = true;
    nAnimationStage = 0;
    [self hideAll];
    
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
        NSUInteger nRetries = 0;
        while ( ! [locManager getPosition] && nRetries < 3 )
        {
            sleep(1);
            nRetries++;
        }
        // TODO: set text "Updating position"? check for failure normally
        // Check also what to do if user blocked loction services
        [globalData setUserPosition:[locManager getPosition]];
         
        // Continue to next window
        bAnimation = false;
        //self.view.userInteractionEnabled = YES;
        
        if ( [PFUser currentUser] )
        {
            // Start loading data
            [globalData loadData];
        }
    }];
}

- (IBAction)retryDown:(id)sender {
    bAnimation = true;
    nAnimationStage = 0;
    [self hideAll];
    if ( bVersionChecked )
        [self performSelector:@selector(loadSequencePart2) withObject:nil afterDelay:0.01f];
    else
        [self performSelector:@selector(loadSequencePart1) withObject:nil afterDelay:0.01f];
}

- (IBAction)updateDown:(id)sender {
}
@end
