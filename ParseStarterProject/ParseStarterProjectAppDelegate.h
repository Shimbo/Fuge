@class RootViewController;

#import "PKRevealController.h"
#define AppDelegate (ParseStarterProjectAppDelegate*)[[UIApplication sharedApplication]delegate];

@interface ParseStarterProjectAppDelegate : NSObject <UIApplicationDelegate> {

    UIWindow *window;
	UINavigationController *navigationController;
    Boolean bFirstActivation;
}

//@property (nonatomic, strong) IBOutlet RootViewController *viewController;

@property (nonatomic, strong) IBOutlet UIWindow *window;
//@property (nonatomic, retain) UINavigationController *mainNavigation;
@property (nonatomic, retain) PKRevealController *revealController;

@property (nonatomic, retain) NSCache *imageCache;

//- (NSArray *)displayList;
@property (nonatomic, retain, readonly) RootViewController *rootViewController;


-(void)userDidLogout;
-(void)userDidLogin;
@end
