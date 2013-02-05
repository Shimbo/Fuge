@class RootViewController;

#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import "PKRevealController.h"
#define AppDelegate (ParseStarterProjectAppDelegate*)[[UIApplication sharedApplication]delegate];

@interface ParseStarterProjectAppDelegate : NSObject <CLLocationManagerDelegate, UIApplicationDelegate> {

    UIWindow *window;
	UINavigationController *navigationController;
    
    
    CLLocationManager*  locationManager;
}

//@property (nonatomic, strong) IBOutlet RootViewController *viewController;

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *mainNavigation;
@property (nonatomic, retain) PKRevealController *revealController;

@property (nonatomic, retain) CLLocationManager* locationManager;

@property (nonatomic, retain) NSCache *imageCache;

//- (NSArray *)displayList;
@property (nonatomic, retain, readonly) RootViewController *rootViewController;


-(void)userDidLogout;
-(void)userDidLogin;
@end
