@class RootViewController;
@class JMImageCache;
#import "PKRevealController.h"
#import "ULMusicPlayerController.h"

#define AppDelegate ((FugeAppDelegate*)[[UIApplication sharedApplication]delegate])

@interface FugeAppDelegate : NSObject <UIApplicationDelegate> {

    UIWindow *window;
	//UINavigationController *navigationController;
    Boolean bFirstActivation;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, retain) PKRevealController *revealController;

@property (nonatomic, retain) JMImageCache *imageCache;

//@property (nonatomic, retain, readonly) RootViewController *rootViewController;

@property (nonatomic, retain, readonly) ULMusicPlayerController *musicPanel;

-(void)userDidLogout;

@end
