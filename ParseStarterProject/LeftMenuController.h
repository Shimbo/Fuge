//
//  LeftMenuController.h
//  SecondCircle
//
//  Created by Constantine Fry on 2/5/13.
//
//

#import <UIKit/UIKit.h>

#import "ParseStarterProjectAppDelegate.h"

@interface LeftMenuController : UIViewController<UIAlertViewDelegate>{
    NSArray *_items;
    NSArray *_selectors;
}

@property(nonatomic,weak)ParseStarterProjectAppDelegate *appDelegate;

@end
