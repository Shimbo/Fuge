//
//  MusicPlayerController.m
//  Fuge
//
//  Created by Mikhail Larionov on 10/8/13.
//
//

#import "ULMusicPlayerController.h"
#import "ULDeezerWrapper.h"

//////////////////////////////////////////////////////
// Reusable play button
//////////////////////////////////////////////////////

@implementation ULMusicPlayButton

+(ULMusicPlayButton*) buttonWithArtist:(NSString*)artist
{
    ULMusicPlayButton* result = [ULMusicPlayButton buttonWithType:UIButtonTypeCustom];
    result.frame = CGRectMake(0, 0, 50, 50);
    [result updateArtistInfo:artist];
    return result;
}

-(void) updateArtistInfo:(NSString*)artist
{
    // Create indicator
    if ( ! _activityIndicator )
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.frame = CGRectMake(15, 15, 20, 20);
        _activityIndicator.color = [UIColor whiteColor];
        [self addSubview:_activityIndicator];
    }
    
    // Play icon
    if ( ! _iconView )
    {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 16, 18, 18)];
        [self addSubview:_iconView];
    }
    
    // Rating image
    if ( ! _ratingView )
    {
        _ratingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ratingBar"]];
        _ratingView.frame = CGRectMake(7, 50, 36, 5);
        _ratingView.contentMode = UIViewContentModeTopLeft;
        _ratingView.clipsToBounds = YES;
        [self addSubview:_ratingView];
        _ratingView.hidden = YES;
    }
    
    // Misc preparations
    [_activityIndicator startAnimating];
    _artistName = artist;
    
    // Observer for playback
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(artistChanged)
                                            name:kMusicArtistChanged object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(artistChanged)
                                            name:kMusicTrackStopped object:nil];
    [self addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // Start loading
    [deezerWrapper prepareArtist:_artistName target:self selector:@selector(artistInfoLoadedCallback:)];
}

-(void) artistInfoLoadedCallback:(NSDictionary*)data
{
    [_activityIndicator stopAnimating];
    
    // Loading data
    [self artistChanged];
    
    // Rating
    if ( data )
    {
        NSArray* ratings = [data objectForKey:@"trackRatings"];
        if ( ratings && ratings.count > 0 )
        {
            // Normalize
            NSNumber* rating = ratings[0];
            double normalizedRating = [rating doubleValue];
            normalizedRating = normalizedRating/1000000.0f;
            if ( normalizedRating > 1.0 )
                normalizedRating = 1.0;
            if ( normalizedRating < 0.1 )
                normalizedRating = 0.1;
            
            // Show
            if ( _ratingView.hidden )
            {
                _ratingView.hidden = NO;
                double oldWidth = _ratingView.width;
                _ratingView.width = 0.0;
                [UIView animateWithDuration:0.2 animations:^{
                    
                    _ratingView.width = normalizedRating * oldWidth;
                }];
            }
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void) artistChanged
{
    if ( _activityIndicator.isAnimating )
        return;
    
    if ( [deezerWrapper artistInformation:_artistName] )
    {
        BOOL nowPlaying = [[deezerWrapper nowPlaying] isEqualToString:_artistName];
        if ( nowPlaying )
            _iconView.image = [UIImage imageNamed:@"iconStop.png"];
        else
            _iconView.image = [UIImage imageNamed:@"iconPlay.png"];
        _iconView.alpha = 1.0;
    }
    else
    {
        _iconView.image = [UIImage imageNamed:@"iconNoMusic.png"];
        _iconView.alpha = 0.5;
        _ratingView.hidden = YES;
    }
}

- (void)buttonTapped
{
    if ( _artistName )
    {
        // Start/stop playing
        if ( [deezerWrapper artistInformation:_artistName] )
        {
            if ( [[deezerWrapper nowPlaying] isEqualToString:_artistName] )
                [deezerWrapper stopPlaying];
            else
            {
                [deezerWrapper checkVolume];
                [deezerWrapper playNextTrack:_artistName inCycle:TRUE];
            }
            [self artistChanged];
        }
    }
}

@end

#pragma mark -

//////////////////////////////////////////////////////
// Music panel controller
//////////////////////////////////////////////////////

@implementation ULMusicPlaybackView

-(void) drawRect: (CGRect) rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithHexString:TABLE_FOOTER_COLOR].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 1);
    CGContextAddLineToPoint(context, rect.size.width * deezerWrapper.bufferProgress, 1);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithHexString:TABLE_SEPARATOR_COLOR].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, 1);
    CGContextAddLineToPoint(context, rect.size.width * deezerWrapper.trackProgress, 1);
    CGContextDrawPath(context, kCGPathStroke);
    
    UIGraphicsEndImageContext();
}

@end

#pragma mark -

//////////////////////////////////////////////////////
// Playback progress
//////////////////////////////////////////////////////

@implementation ULMusicPlayerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(updatePresentation:)
                                                name:kMusicArtistChanged
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(updatePresentation:)
                                                name:kMusicTrackChanged
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(updatePresentation:)
                                                name:kMusicTrackStopped
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(updateProgress)
                                                name:kTrackOrBufferProgressUpdated
                                                object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void) loadBandCover
{
    // Create cover object if needed
    if ( ! _bandCover )
    {
        _bandCover = [[AsyncImageView alloc] initWithFrame:CGRectMake(0, 2, 48, 48)];
        [self.view addSubview:_bandCover];
        [self.view bringSubviewToFront:_activityIndicator];
    }
    _bandCover.imageView.image = nil;
    
    // Load cover url
    NSString* strURL = [deezerWrapper artistCover:deezerWrapper.currentArtist];
    if ( ! strURL )
        return;
    
    // Start loading
    [_activityIndicator startAnimating];
    [_bandCover loadImageFromURL:strURL withTarger:_activityIndicator selector:@selector(stopAnimating)];
}

- (void) updatePresentation:(BOOL)animate
{
    // Bring to front in case view was hidden behind others
    [_parentController.view bringSubviewToFront:self.view];
    
    // Show animation
    if ( deezerWrapper.nowPlaying && ! _playbackActive )
    {
        _playbackActive = YES;
        self.view.hidden = NO;
        if ( animate )
        {
            self.view.originY += self.view.height;
            [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.view.originY -= self.view.height;
            } completion:nil];
        }
    }
    
    // Hide animation
    if ( ! deezerWrapper.nowPlaying && _playbackActive )
    {
        _playbackActive = NO;
        if ( animate )
        {
            [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.view.originY += self.view.height;
            } completion:^(BOOL finished) {
                self.view.originY -= self.view.height;
                self.view.hidden = YES;
            }];
        }
        else
            self.view.hidden = YES;
    }
    
    // Update labels and cover
    if ( deezerWrapper.nowPlaying )
    {
        _artistLabel.text = deezerWrapper.currentArtist;
        _trackLabel.text = deezerWrapper.currentTrackName;
        _trackNumber.text = [NSString stringWithFormat:@"Track %d of %d", deezerWrapper.currentTrackNumber+1, deezerWrapper.totalTracksCount];
        [self loadBandCover];
    }
}

- (void)updateProgress
{
    // Bring to front in case view was hidden behind others
    [_parentController.view bringSubviewToFront:self.view];
    
    // To call redraw method
    [_playbackView setNeedsDisplay];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _playbackView = [[ULMusicPlaybackView alloc] initWithFrame:self.view.frame];
    _playbackView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    _playbackView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_playbackView];
    [self.view sendSubviewToBack:_playbackView];
    [self updatePresentation:NO];
    self.view.hidden = TRUE;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updatePresentation:NO];
}

- (IBAction)nextButtonTapped:(id)sender {
    [deezerWrapper playNextTrack:nil inCycle:TRUE];
}

- (IBAction)stopButtonTapped:(id)sender {
    [deezerWrapper stopPlaying];
}

- (void) setParentController:(UIViewController*)parent
{
    _parentController = parent;
}

+ (ULMusicPlayerController*) createAndAttachToParent:(UIViewController*)parent
{
    ULMusicPlayerController* controller = [[ULMusicPlayerController alloc] init];
    [controller setParentController:parent];
    controller.view.frame = CGRectMake(0, parent.view.height - controller.view.height, parent.view.width, controller.view.height);
    [parent.view addSubview:controller.view];
    [parent addChildViewController:controller];
    return controller;
}

@end
