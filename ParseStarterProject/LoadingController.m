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

static Boolean bRotating = true;

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
        bRotating = true;
        bAnimation = true;
        nAnimationStage = 0;
        _backgroundImage.alpha = 0.0f;
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
    }
    return self;
}

- (void)loadSequencePart0
{
    // Facebook
    [PFFacebookUtils initializeFacebook];
    
    // ACL
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [defaultACL setWriteAccess:TRUE forRoleWithName:@"Moderator"];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    // Zoom in animated
    _whiteImage.hidden = FALSE;
    _whiteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 3.0, 3.0);
    _backgroundImage.alpha = 0.0f;
    _backgroundImage.hidden = FALSE;
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
    __weak LoadingController *ctrl = self;
    [systemQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        if (error)
        {
            [ctrl noInternet];
            return;
        }
        else
        {
            Boolean bShowAppStoreButton = false;
            Boolean bShowPopup = false;
            
            PFObject* system = object;
            
            float minVersion = [[system objectForKey:@"minVersion"] floatValue];
            float curVersion = [[system objectForKey:@"curVersion"] floatValue];
            float thisVersion = [[globalVariables currentVersion] floatValue];
            if ( thisVersion < minVersion )
                bShowAppStoreButton = TRUE;
            else if ( thisVersion < curVersion )
            {
                bShowPopup = TRUE;
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"New version is out!" message:@"You're running old version of the application. We recommend you updating the application." delegate:ctrl cancelButtonTitle:@"OK" otherButtonTitles:@"Later",nil];
                [message show];
            }
            
            if ( bShowAppStoreButton )
            {
                [self oldVersion];
            }
            else if ( ! bShowPopup )
            {
                bVersionChecked = true;
                [globalVariables setGlobalSettings:[system objectForKey:@"settings"]];
                [ctrl performSelector:@selector(loadSequencePart2) withObject:nil afterDelay:0.01f];
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
        __weak LoadingController *ctrl = self;
        [pCurrentUser refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if ( error )
                [ctrl noInternet];
            else
            {
                Boolean bBanned = FALSE;
                if ( [pCurrentUser objectForKey:@"banExpDate"] )
                {
                    NSDate* date = [pCurrentUser objectForKey:@"banExpDate"];
                    if ( [date compare:[NSDate date]] == NSOrderedDescending )
                        bBanned = TRUE;
                }
                if ( bBanned )
                    [ctrl bannedUser];
                else
                    [globalData loadData];
            }
        }];
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
        
        if ( bRotating )
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
    [self presentViewController:profileViewController animated:TRUE completion:nil];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    bRotating = false;
    _backgroundImage.hidden = TRUE;
}

-(void) mainComplete
{
    // Turning on status bar
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
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
    bAnimation = true;
    nAnimationStage = 0;
    
    _loginButton.alpha = 1.0f;
    _retryButton.alpha = 1.0f;
    _updateButton.alpha = 1.0f;
    _descriptionText.alpha = 1.0f;
    _titleText.alpha = 1.0f;
    _miscText.alpha = 1.0f;
    _whiteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    
    [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        _loginButton.centerY += 200;
        _retryButton.centerY += 200;
        _updateButton.centerY += 200;
        _descriptionText.centerY -= 200;
        _titleText.centerY -= 200;
        _miscText.centerY += 200;
        _loginButton.alpha = 0.0f;
        _retryButton.alpha = 0.0f;
        _updateButton.alpha = 0.0f;
        _descriptionText.alpha = 0.0f;
        _titleText.alpha = 0.0f;
        _miscText.alpha = 0.0f;
        _whiteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 3.0, 3.0);
    }
    completion: ^(BOOL finished) {
        _loginButton.hidden = TRUE;
        _retryButton.hidden = TRUE;
        _descriptionText.hidden = TRUE;
        _titleText.hidden = TRUE;
        _miscText.hidden = TRUE;
        _loginButton.centerY -= 200;
        _retryButton.centerY -= 200;
        _updateButton.centerY -= 200;
        _descriptionText.centerY += 200;
        _titleText.centerY += 200;
        _miscText.centerY -= 200;
    }];
}

- (void) showAll
{
    bAnimation = false;
    
    _loginButton.centerY += 200;
    _retryButton.centerY += 200;
    _updateButton.centerY += 200;
    _descriptionText.centerY -= 200;
    _titleText.centerY -= 200;
    _miscText.centerY += 200;
    _loginButton.alpha = 0;
    _retryButton.alpha = 0;
    _updateButton.alpha = 0;
    _descriptionText.alpha = 0;
    _titleText.alpha = 0;
    _miscText.alpha = 0;
    _whiteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 3.0, 3.0);
    
    [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        _loginButton.centerY -= 200;
        _retryButton.centerY -= 200;
        _updateButton.centerY -= 200;
        _descriptionText.centerY += 200;
        _titleText.centerY += 200;
        _miscText.centerY -= 200;
        _loginButton.alpha = 1.0f;
        _retryButton.alpha = 1.0f;
        _updateButton.alpha = 1.0f;
        _descriptionText.alpha = 1.0f;
        _titleText.alpha = 1.0f;
        _miscText.alpha = 1.0f;
        _whiteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    }
    completion: ^(BOOL finished) {
    }];
}

- (void) notLoggedIn
{
    _retryButton.hidden = TRUE;
    _loginButton.hidden = FALSE;
    _updateButton.hidden = TRUE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = FALSE;
    
    _titleText.text = @"Welcome!";
    _descriptionText.text = @"Fuge is a mobile discovery service for\npeople and activities nearby. Please, keep\nin mind that we're still in early beta.";
    
    [self showAll];
}

- (void) noInternet
{
    _loginButton.hidden = TRUE;
    _retryButton.hidden = FALSE;
    _updateButton.hidden = TRUE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = TRUE;
    
    _titleText.text = @"Ooups!";
    _descriptionText.text = @"It seems like you don’t have internet \n connection at the moment. Try \n again when you will get some!";
    
    [self showAll];
}

- (void) loginFailed
{
    _loginButton.hidden = FALSE;
    _retryButton.hidden = TRUE;
    _updateButton.hidden = TRUE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = FALSE;
    
    _titleText.text = @"Ooups!";
    _descriptionText.text = @"Looks like you haven’t finished \n login process or wasn’t able to do so. \n Please, try again!";
    
    [self showAll];
}

- (void) oldVersion
{
    _loginButton.hidden = TRUE;
    _retryButton.hidden = TRUE;
    _updateButton.hidden = FALSE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = TRUE;
    
    _titleText.text = @"Outdated version!";
    _descriptionText.text = @"What age did you come from? Why\n still using this version instead\n of a new and shiny one?";
    
    [self showAll];
}

- (void) bannedUser
{
    _loginButton.hidden = TRUE;
    _retryButton.hidden = TRUE;
    _updateButton.hidden = TRUE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = FALSE;
    
    _titleText.text = @"You are banned!";
    _miscText.text = @"Don't mess up next time!";
    
    NSDate* expirationDate = [pCurrentUser objectForKey:@"banExpDate"];
    NSTimeInterval interval = [expirationDate timeIntervalSinceDate:[NSDate date]];
    NSInteger daysLeft = interval / (3600*24) + 1;
    NSString* strDays = daysLeft == 1 ? @"day" : @"days";
    
    _descriptionText.text = [NSString stringWithFormat:@"So, you've got a ban. What a shame.\nWas it spam or rudeness? Whatever.\nYour ban will expire in %d %@.", daysLeft, strDays];
    
    [self showAll];
}


- (IBAction)loginDown:(id)sender {
    
    // Activity indicator
    [self hideAll];
    
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location", @"email"];
    __weak LoadingController *ctrl = self;
    [PFFacebookUtils logInWithPermissions:permissionsArray
                                    block:^(PFUser *user, NSError *error)
    {
         if ( ! user )
         {
             if (!error) {
                 NSLog(@"Uh oh. The user cancelled the Facebook login.");
             } else {
                 NSLog(@"Uh oh. An error occurred: %@", error);
             }
             [ctrl loginFailed];
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
        
        PFGeoPoint* location = [locManager getPosition];
        if ( location )
            [globalData setUserPosition:location];
         
        // Continue to next window
        bAnimation = false;
        
        // Start loading data
        if ( [PFUser currentUser] )
            [globalData loadData];
    }];
}

- (IBAction)retryDown:(id)sender {
    [self hideAll];
    if ( bVersionChecked )
        [self performSelector:@selector(loadSequencePart2) withObject:nil afterDelay:0.01f];
    else
        [self performSelector:@selector(loadSequencePart1) withObject:nil afterDelay:0.01f];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 0 )
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_STORE_PATH]];
        [self performSelector:@selector(loadSequencePart1) withObject:nil afterDelay:0.01f];
    }
    else
    {
        bVersionChecked = true;
        [self performSelector:@selector(loadSequencePart2) withObject:nil afterDelay:0.01f];
    }
}


- (IBAction)updateDown:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_STORE_PATH]];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void)viewDidUnload {
    [self setWhiteImage:nil];
    [super viewDidUnload];
}
@end
