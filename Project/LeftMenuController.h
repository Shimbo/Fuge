//
//  LeftMenuController.h
//  SecondCircle
//
//  Created by Constantine Fry on 2/5/13.
//
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
@class MapViewController;
@class ProfileViewController;

@class CustomBadge;
@interface LeftMenuController : UIViewController<UIAlertViewDelegate, UITextFieldDelegate>{
    NSMutableArray *_items;
    NSMutableArray *_selectors;
    RootViewController *_rootViewController;
    MapViewController *_mapViewController;
    ProfileViewController *_profileViewController;
    CustomBadge *_inboxBadge;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    UIAlertView *statusPrompt;
}

@property(nonatomic,weak)FugeAppDelegate *appDelegate;

-(void)showMap;
-(void)showCircles;
-(void)showUser;
-(void)prepareMap;
-(void)clean;

@end
