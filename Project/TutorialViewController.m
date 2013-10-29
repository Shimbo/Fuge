//
//  TutorialViewController.m
//  Fuge
//
//  Created by Mikhail Larionov on 10/11/13.
//
//

#import "TutorialViewController.h"
#import "AppDelegate.h"
#import "LeftMenuController.h"
#import "ULDeezerWrapper.h"

@implementation TutorialViewController

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
#ifdef TARGET_FUGE
    [deezerWrapper prepareArtist:@"Jay-Z" target:self selector:@selector(demoLoaded)];
    _loadingIndicator.color = [UIColor whiteColor];
    [_loadingIndicator startAnimating];
#endif
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [AppDelegate.revealController dismissViewControllerAnimated:YES completion:nil];
}

- (void)demoLoaded
{
    [_loadingIndicator stopAnimating];
    _iconDemo.hidden = FALSE;
}

- (IBAction)playDemo:(id)sender {
#ifdef TARGET_FUGE
    if ( [deezerWrapper nowPlaying] )
    {
        [deezerWrapper stopPlaying];
        _iconDemo.image = [UIImage imageNamed:@"iconPlay"];
    }
    else
    {
        [deezerWrapper checkVolume];
        
        [deezerWrapper playNextTrack:@"Jay-Z" inCycle:FALSE];
        _iconDemo.image = [UIImage imageNamed:@"iconStop"];
    }
#endif
}
@end
