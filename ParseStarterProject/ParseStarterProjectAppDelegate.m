#import <Parse/Parse.h>
#import "ParseStarterProjectAppDelegate.h"
#import "RootViewController.h"

#import "LoginViewController.h"
#import "Circle.h"

#import "GlobalData.h"

#import "LeftMenuController.h"

#import "TestFlightSDK/TestFlight.h"

#import "LocationManager.h"


@implementation ParseStarterProjectAppDelegate

@synthesize window;

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   
    NSLog(@"%@", launchOptions);

    self.imageCache = [[NSCache alloc]init];
    [self.imageCache setCountLimit:90];
    bFirstActivation = true;
        
#ifndef RELEASE
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    @try {
        [TestFlight takeOff:@"f8d7037b262277589cd287681817220a_MTUyNzAwMjAxMi0xMS0wNyAyMToxMDo0Ni43OTY5OTc"];
    }
    @catch (NSException *exception) {
        NSLog(@"----%@",exception);
    }

    
    [TestFlight passCheckpoint:@"Initialization started"];
    
    [Parse setApplicationId:@"VMhSG8IQ9xibufk8lAPpclIwdXVfYD44OpKmsHdn"
                  clientKey:@"u2kJ1jWBjN9qY3ARlJuEyNkvUA9EjOMv1R4w5sDX"];
    
    [PFFacebookUtils initializeWithApplicationId:@"157314481074430"];
    
    // Location data
    [locManager startUpdating];
    
    PFACL *defaultACL = [PFACL ACL];
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    LeftMenuController *leftMenu = [[LeftMenuController alloc]init];
    self.revealController = [PKRevealController revealControllerWithFrontViewController:nil leftViewController:leftMenu rightViewController:nil options:nil];
    window.rootViewController = self.revealController;
    [window makeKeyAndVisible];
    
    if (! PFFacebookUtils.session.isOpen || ! [[PFUser currentUser] isAuthenticated])
    {
        [self showLoginWindow:NO];
    }
    else
    {
        [self createNewMainNavigation];
        NSError* error;
        [[PFUser currentUser] refresh:&error];
        if ( error )
            NSLog(@"Uh oh. An error occurred: %@", error);
    }
    
    // Retrieving initial data
    
    
	//rootViewController.displayList = [self displayList];
	//rootViewController.calendar = [self calendar];
	

	
	// Configure and show the window


    
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
                                                    UIRemoteNotificationTypeAlert|
                                                    UIRemoteNotificationTypeSound];
    
    [TestFlight passCheckpoint:@"Initialization ended"];
    
    return YES;
}

-(void)createNewMainNavigation{
    LeftMenuController *leftMenu = (LeftMenuController*)self.revealController.leftViewController;
    [leftMenu showMap];

}

-(void)showLoginWindow:(BOOL)animated{
    LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:loginViewController];
    
    [self.revealController presentViewController:nav animated:animated
                                      completion:nil];
}

-(void)userDidLogin{
    [self createNewMainNavigation];
    
}

-(void)userDidLogout{
    [self showLoginWindow:YES];
}


#pragma mark -
#pragma mark Memory management

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.imageCache removeAllObjects];
            NSLog(@"cleaned");
        });
    });
}


#pragma mark -
#pragma mark Some stuff


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [PFFacebookUtils handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    [PFPush storeDeviceToken:newDeviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    NSLog(@"%@", userInfo);
    //[rootViewController reloadData];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if ( bFirstActivation )
        bFirstActivation = false;
    else if ( [[PFUser currentUser] isAuthenticated])
        [globalData reloadInbox:nil];    // TODO: show loading screen here, always open on loading screen
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}


@end
