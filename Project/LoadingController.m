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

#ifdef TARGET_S2C
#import "LinkedinLoader.h"
#endif

@implementation LoadingController

@synthesize bDemoMode;

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
        bDemoMode = false;
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
    }
    return self;
}

- (void)loadSequencePart0
{
#ifdef TARGET_FUGE
    // Facebook
    [PFFacebookUtils initializeFacebook];
#endif
    
    // ACL
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [defaultACL setWriteAccess:TRUE forRoleWithName:@"Moderator"];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    // Zoom in animated
#ifdef TARGET_FUGE
    _backgroundImage.hidden = FALSE;
    _backgroundImage.alpha = 0.0f;
    _whiteImage.hidden = FALSE;
    _whiteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 4.0, 4.0);
#elif defined TARGET_S2C
    pyramid.alpha = 0.0f;
    pyramid.hidden = FALSE;
#endif
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:1.0];
#ifdef TARGET_FUGE
    _backgroundImage.alpha = 1.0f;
#elif defined TARGET_S2C
    pyramid.alpha = 1.0f;
#endif
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
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOADING_TITLE_NEWVERSION",nil) message:NSLocalizedString(@"LOADING_TEXT_NEWVERSION",nil) delegate:ctrl cancelButtonTitle:@"OK" otherButtonTitles:@"Later",nil];
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
    
#ifdef TARGET_FUGE
    // Check permissions
    Boolean bPermissionsGranted = TRUE;
    NSArray *permissionsArray = FACEBOOK_PERMISSIONS;
    for ( NSString* permission in permissionsArray )
        if ([PFFacebookUtils.session.permissions indexOfObject:permission] == NSNotFound)
        {
            bPermissionsGranted = FALSE;
            break;
        }
    
    // Login or load
    if ( ! PFFacebookUtils.session.isOpen || ! [[PFUser currentUser] isAuthenticated] || ! bPermissionsGranted || ! strCurrentUserId )
#elif defined TARGET_S2C
    if ( ! [[PFUser currentUser] isAuthenticated] || ! strCurrentUserId )
#endif
    {
        [self notLoggedIn];
    }
    else
    {
        __weak LoadingController *ctrl = self;
        [pCurrentUser refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if ( error )
            {
                if ( error.code == 101) // user not found, relogin no matter why
                    [self notLoggedIn];
                else
                    [ctrl noInternet];
            }
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
                    [self loadSequencePart3];
            }
        }];
    }
}

- (void)loadSequencePart3
{
    // Start loading data
    [globalData loadData];
    [locManager startUpdating];
}

#ifdef TARGET_FUGE
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
#endif

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ( ! bDemoMode )
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

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
#ifdef TARGET_FUGE
    
    bRotating = TRUE;
    _backgroundImage.hidden = FALSE;
    _backgroundImage.alpha = 0.0f;
    [self animateHypno];
    
#elif defined TARGET_S2C
    
    _backgroundImage.hidden = TRUE;
    if ( ! pyramid )
    {
        CGPoint ptSize;
        if ( IPAD )
            ptSize = CGPointMake(306*2, 312*2);
        else
            ptSize = CGPointMake(306, 312);
        CGRect frame = self.view.frame;
        frame.origin.x = ( frame.size.width - ptSize.x ) / 2;
        frame.size.width = ptSize.x;
        frame.origin.y = ( frame.size.height - ptSize.y ) / 2;
        frame.size.height = ptSize.y;
        pyramid = [[UIImageView alloc] initWithFrame:frame];
        
        // load all the frames of our animation
        if ( IPAD )
        {
            pyramid.animationImages = [NSArray arrayWithObjects:
                                       [UIImage imageNamed:@"pyramid_0000@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0011@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0022@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0033@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0044@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0055@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0066@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0077@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0088@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0099@2x.png"],
                                       [UIImage imageNamed:@"pyramid_0110@2x.png"], nil];
        }
        else
        {
            pyramid.animationImages = [NSArray arrayWithObjects:
                                       [UIImage imageNamed:@"pyramid_0000.png"],
                                       [UIImage imageNamed:@"pyramid_0011.png"],
                                       [UIImage imageNamed:@"pyramid_0022.png"],
                                       [UIImage imageNamed:@"pyramid_0033.png"],
                                       [UIImage imageNamed:@"pyramid_0044.png"],
                                       [UIImage imageNamed:@"pyramid_0055.png"],
                                       [UIImage imageNamed:@"pyramid_0066.png"],
                                       [UIImage imageNamed:@"pyramid_0077.png"],
                                       [UIImage imageNamed:@"pyramid_0088.png"],
                                       [UIImage imageNamed:@"pyramid_0099.png"],
                                       [UIImage imageNamed:@"pyramid_0110.png"], nil];

        }
        
        // all frames will execute in 1.75 seconds
        pyramid.animationDuration = 0.8;
        // repeat the annimation forever
        pyramid.animationRepeatCount = 0;
        // start animating
        [pyramid startAnimating];
        // add the animation view to the main window
        [self.view addSubview:pyramid];
        if ( bDemoMode )
            pyramid.hidden = FALSE;
        else
            pyramid.hidden = TRUE;
    }
    
#endif
    
    if ( bDemoMode )
    {
        _backgroundImage.alpha = 1.0f;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
        [self.navigationController setNavigationBarHidden:TRUE];
        CGRect frame = AppDelegate.revealController.view.frame;
        frame.size.height += frame.origin.y;
        frame.origin.y = 0;
        AppDelegate.revealController.view.frame = frame;
    }
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
    //if ( [globalVariables isNewUser] )
    //    [self proceedToProfile];
    //else
    [globalVariables setLoaded];
    [self proceedToMapWindow];
    
    [TestFlight passCheckpoint:@"Initialization main complete"];
}

-(void) proceedToMapWindow
{
    FugeAppDelegate *delegate = AppDelegate;
    [delegate.revealController dismissViewControllerAnimated:TRUE completion:nil];
    LeftMenuController *leftMenu = (LeftMenuController*)delegate.revealController.leftViewController;
#ifdef TARGET_FUGE
    [leftMenu showMap];
#elif defined TARGET_S2C
    [leftMenu showCircles];
#endif
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
    _linkedinButton.alpha = 1.0f;
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
        _linkedinButton.alpha = 0.0f;
        _retryButton.alpha = 0.0f;
        _updateButton.alpha = 0.0f;
        _descriptionText.alpha = 0.0f;
        _titleText.alpha = 0.0f;
        _miscText.alpha = 0.0f;
        _whiteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 4.0, 4.0);
    }
    completion: ^(BOOL finished) {
        _loginButton.hidden = TRUE;
        _linkedinButton.hidden = TRUE;
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
    _linkedinButton.centerY += 200;
    _retryButton.centerY += 200;
    _updateButton.centerY += 200;
    _descriptionText.centerY -= 200;
    _titleText.centerY -= 200;
    _miscText.centerY += 200;
    _loginButton.alpha = 0;
    _linkedinButton.alpha = 0;
    _retryButton.alpha = 0;
    _updateButton.alpha = 0;
    _descriptionText.alpha = 0;
    _titleText.alpha = 0;
    _miscText.alpha = 0;
    _whiteImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, 4.0, 4.0);
    
    [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        _loginButton.centerY -= 200;
        _linkedinButton.centerY -= 200;
        _retryButton.centerY -= 200;
        _updateButton.centerY -= 200;
        _descriptionText.centerY += 200;
        _titleText.centerY += 200;
        _miscText.centerY -= 200;
        _loginButton.alpha = 1.0f;
        _linkedinButton.alpha = 1.0f;
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
#ifdef TARGET_FUGE
    _loginButton.hidden = FALSE;
#elif defined TARGET_S2C
    _linkedinButton.hidden = FALSE;
#endif
    _updateButton.hidden = TRUE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = FALSE;
    
    _titleText.text = NSLocalizedString(@"LOADING_TITLE_FIRSTPAGE",nil);
    _descriptionText.text = NSLocalizedString(@"LOADING_TEXT_FIRSTPAGE",nil);
    
    [self showAll];
}

- (void) noInternet
{
    _loginButton.hidden = TRUE;
    _linkedinButton.hidden = TRUE;
    _retryButton.hidden = FALSE;
    _updateButton.hidden = TRUE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = TRUE;
    
    _titleText.text = NSLocalizedString(@"LOADING_TITLE_NOINTERNET",nil);
    _descriptionText.text = NSLocalizedString(@"LOADING_TEXT_NOINTERNET",nil);
    
    [self showAll];
}

- (void) loginFailed
{
#ifdef TARGET_FUGE
    _loginButton.hidden = FALSE;
#elif defined TARGET_S2C
    _linkedinButton.hidden = FALSE;
#endif
    _retryButton.hidden = TRUE;
    _updateButton.hidden = TRUE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = FALSE;
    
    _titleText.text = NSLocalizedString(@"LOADING_TITLE_LOGINFAILED",nil);
    _descriptionText.text = NSLocalizedString(@"LOADING_TEXT_LOGINFAILED",nil);
    
    [self showAll];
}

- (void) oldVersion
{
    _loginButton.hidden = TRUE;
    _linkedinButton.hidden = TRUE;
    _retryButton.hidden = TRUE;
    _updateButton.hidden = FALSE;
    
    _descriptionText.hidden = FALSE;
    _titleText.hidden = FALSE;
    _miscText.hidden = TRUE;
    
    _titleText.text = NSLocalizedString(@"LOADING_TITLE_OLDVERSION",nil);
    _descriptionText.text = NSLocalizedString(@"LOADING_TEXT_OLDVERSION",nil);
    
    [self showAll];
}

- (void) bannedUser
{
    _loginButton.hidden = TRUE;
    _linkedinButton.hidden = TRUE;
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
    
    NSString* strReason = @"Was it spam or rudeness? Whatever.";
    if ( [pCurrentUser objectForKey:@"banReason"] )
        strReason = [NSString stringWithFormat:@"Reason? %@", [pCurrentUser objectForKey:@"banReason"]];
    _descriptionText.text = [NSString stringWithFormat:@"So, you were reported. What a shame.\n%@\nThe ban will expire in %d %@.", strReason, daysLeft, strDays];
    
    [self showAll];
}

- (IBAction)loginDown:(id)sender {
    
    // Activity indicator
    [self hideAll];
    
    NSArray *permissionsArray = FACEBOOK_PERMISSIONS;
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
                 [self loadSequencePart3];
             }
             else
             {
                 NSLog(@"User logged in through Facebook!");
                 [pCurrentUser refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                     if ( ! error )
                         [self loadSequencePart3];
                 }];
             }             
        }        
    }];
}

- (IBAction)linkedinDown:(id)sender {
    
    [self hideAll];
#ifdef TARGET_S2C
    [lnLoader initialize:self selector:@selector(loadSequencePart3) failed:@selector(loginFailed)];
#endif
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
    [self setLinkedinButton:nil];
    [super viewDidUnload];
}

@end
