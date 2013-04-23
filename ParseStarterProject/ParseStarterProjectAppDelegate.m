#import <Parse/Parse.h>
#import "ParseStarterProjectAppDelegate.h"
#import "RootViewController.h"
#import "Circle.h"
#import "GlobalData.h"
#import "LeftMenuController.h"
#import "LocationManager.h"
#import "LoadingController.h"


@implementation ParseStarterProjectAppDelegate

@synthesize window;

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    if ( launchOptions )
        NSLog(@"Launch options: %@", launchOptions);
    
    self.imageCache = [[NSCache alloc]init];
    [self.imageCache setCountLimit:90];
    
    self.circledImageCache = [[NSCache alloc]init];
    [self.circledImageCache setCountLimit:90];
    
    bFirstActivation = true;
    
    // Left menu
    LeftMenuController *leftMenu = [[LeftMenuController alloc]init];
    self.revealController = [PKRevealController revealControllerWithFrontViewController:nil leftViewController:leftMenu rightViewController:nil options:nil];
    window.rootViewController = self.revealController;
    [window makeKeyAndVisible];
    
    // Loading screen
    LoadingController *loadingViewController = [[LoadingController alloc] initWithNibName:@"LoadingController" bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:loadingViewController];
    [self.revealController presentViewController:nav animated:NO completion:nil];
        
    // Notifications
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
                                                    UIRemoteNotificationTypeAlert|
                                                    UIRemoteNotificationTypeSound];
    
    return YES;
}



// TODONOW: check it (add some variable for login right away)
-(void)userDidLogout{
    LoadingController *loadingViewController = [[LoadingController alloc] initWithNibName:@"LoadingController" bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:loadingViewController];
    [self.revealController presentViewController:nav animated:NO completion:nil];
}


#pragma mark -
#pragma mark Memory management

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.imageCache removeAllObjects];
            [self.circledImageCache removeAllObjects];
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
    
    // Pushes information
    [PFPush storeDeviceToken:newDeviceToken];
    
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
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
    {
        [globalData reloadFriendsInBackground];
        [globalData reloadMapInfoInBackground:nil toNorthEast:nil];
        [globalData reloadInboxInBackground];
        [[NSNotificationCenter defaultCenter]postNotificationName:kAppRestored
                                                           object:nil];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}



@end
