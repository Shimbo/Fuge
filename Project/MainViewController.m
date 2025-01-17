//
//  MainViewController.m
//  SecondCircle
//
//  Created by Constantine Fry on 2/5/13.
//
//

#import "MainViewController.h"
#import "AppDelegate.h"
#import "CustomBadge.h"
#import "GlobalData.h"

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(unreadDidUpdate)
                                                    name:kInboxUnreadCountDidUpdate
                                                  object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)unreadDidUpdate{
    [_unreadBadge setNumber:[globalData getInboxUnreadCount]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    if ( IOS_NEWER_OR_EQUAL_TO_7 )
        [button setBackgroundImage:[UIImage imageNamed:@"reveal_menu_button7.png"]
                          forState:UIControlStateNormal];
    else
        [button setBackgroundImage:[UIImage imageNamed:@"reveal_menu_button6.png"]
                      forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showLeftView:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    _unreadBadge = [CustomBadge secondCircleCustomBadge];
    _unreadBadge.center = CGPointMake(45, 5);
    [_unreadBadge setNumber:[globalData getInboxUnreadCount]];
    _unreadBadge.userInteractionEnabled = NO;
    [button addSubview:_unreadBadge];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}



- (void)showLeftView:(id)sender
{
    if (AppDelegate.revealController.focusedController == AppDelegate.revealController.leftViewController)
    {
        [AppDelegate.revealController showViewController:AppDelegate.revealController.frontViewController];
    }
    else
    {
        [AppDelegate.revealController showViewController:AppDelegate.revealController.leftViewController];
    }
}


@end
