@class RootViewController;

#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@interface ParseStarterProjectAppDelegate : NSObject <CLLocationManagerDelegate, UIApplicationDelegate> {

    UIWindow *window;
	UINavigationController *navigationController;
    
    RootViewController *rootViewController;
    
    CLLocationManager*  locationManager;
}

@property (nonatomic, strong) IBOutlet RootViewController *viewController;

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, retain) UINavigationController *navigationController;

@property (nonatomic, retain) CLLocationManager* locationManager;

//- (NSArray *)displayList;
@property (nonatomic, retain, readonly) RootViewController *rootViewController;

@end
