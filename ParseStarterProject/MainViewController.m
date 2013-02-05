//
//  MainViewController.m
//  SecondCircle
//
//  Created by Constantine Fry on 2/5/13.
//
//

#import "MainViewController.h"
#import "ParseStarterProjectAppDelegate.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage *revealImagePortrait = [UIImage imageNamed:@"reveal_menu_icon_portrait.png"];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:revealImagePortrait landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(showLeftView:)];
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
