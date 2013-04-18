@class RootViewController;

#import "PKRevealController.h"
#define AppDelegate (ParseStarterProjectAppDelegate*)[[UIApplication sharedApplication]delegate];

@interface ParseStarterProjectAppDelegate : NSObject <UIApplicationDelegate> {

    UIWindow *window;
	//UINavigationController *navigationController;
    Boolean bFirstActivation;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, retain) PKRevealController *revealController;

@property (nonatomic, retain) NSCache *imageCache;
@property (nonatomic, retain) NSCache *circledImageCache;

@property (nonatomic, retain, readonly) RootViewController *rootViewController;

-(void)userDidLogout;

@end
