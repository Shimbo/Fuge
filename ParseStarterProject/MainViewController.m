//
//  MainViewController.m
//  SecondCircle
//
//  Created by Constantine Fry on 2/5/13.
//
//

#import "MainViewController.h"
#import "ParseStarterProjectAppDelegate.h"
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
    [button setBackgroundImage:[UIImage imageNamed:@"reveal_menu_button_portrait.png"]
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
    ParseStarterProjectAppDelegate *delegate = AppDelegate;
    if (delegate.revealController.focusedController == delegate.revealController.leftViewController)
    {
        [delegate.revealController showViewController:delegate.revealController.frontViewController];
    }
    else
    {
        [delegate.revealController showViewController:delegate.revealController.leftViewController];
    }
}


@end
