//
//  StatsViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/19/13.
//
//

#import "StatsViewController.h"


@implementation StatsViewController

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
    
    // Some really hardcoded manual code only for stats
    
    //[statsText
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setStatsText:nil];
    [super viewDidUnload];
}
@end
