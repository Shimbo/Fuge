//
//  LeftMenuController.h
//  SecondCircle
//
//  Created by Constantine Fry on 2/5/13.
//
//

#import <UIKit/UIKit.h>

#import "ParseStarterProjectAppDelegate.h"
@class MapViewController;

@class CustomBadge;
@interface LeftMenuController : UIViewController<UIAlertViewDelegate>{
    NSMutableArray *_items;
    NSMutableArray *_selectors;
    RootViewController *_rootViewController;
    MapViewController *_mapViewController;
    CustomBadge *_inboxBadge;
}

@property(nonatomic,weak)ParseStarterProjectAppDelegate *appDelegate;

-(void)showMap;
-(void)showUser;

-(void)prepareMap;

@end
