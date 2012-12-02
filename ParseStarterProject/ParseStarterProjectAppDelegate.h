extern NSTimeZone *App_defaultTimeZone;

@class RootViewController;

@interface ParseStarterProjectAppDelegate : NSObject <UIApplicationDelegate> {

    UIWindow *window;
	UINavigationController *navigationController;
	
	NSCalendar *calendar;
    
    NSMutableArray *listPersons;
    NSMutableArray *listCircles;
    NSMutableArray *listGeo;
}

// What left from old
@property (nonatomic, strong) IBOutlet RootViewController *viewController;

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, retain) UINavigationController *navigationController;

- (NSArray *)displayList;
@property (nonatomic, retain, readonly) NSCalendar *calendar;


@property (nonatomic, strong) NSArray *listPersons;
@property (nonatomic, strong) NSArray *listCircles;
@property (nonatomic, strong) NSArray *listGeo;


@end
