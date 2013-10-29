//
//  MusicPlayerController.h
//  Fuge
//
//  Created by Mikhail Larionov on 10/8/13.
//
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

//////////////////////////////////////////////////////
// Reusable play button
//////////////////////////////////////////////////////

@interface ULMusicPlayButton : UIButton
{
    UIActivityIndicatorView *_activityIndicator;
    UIImageView             *_iconView;
    UIImageView             *_ratingView;
    NSString                *_artistName;
}
+(ULMusicPlayButton*) buttonWithArtist:(NSString*)artist;
-(void) updateArtistInfo:(NSString*)artist;
@end

//////////////////////////////////////////////////////
// Playback progress
//////////////////////////////////////////////////////

@interface ULMusicPlaybackView : UIView
@end

//////////////////////////////////////////////////////
// Music panel controller
//////////////////////////////////////////////////////

@interface ULMusicPlayerController : UIViewController
{
    // Parent controller
    UIViewController        *_parentController;
    
    // Playback progress
    ULMusicPlaybackView     *_playbackView;
    BOOL                    _playbackActive;
    
    // Artist information
    AsyncImageView          *_bandCover;
    IBOutlet UILabel        *_artistLabel;
    IBOutlet UILabel        *_trackLabel;
    IBOutlet UILabel        *_trackNumber;
    
    // Active controls
    IBOutlet UIButton       *_stopButton;   // Could be changed to play
    
    // Load indicator
    IBOutlet UIActivityIndicatorView    *_activityIndicator;
}

// Initialization
+ (ULMusicPlayerController*) createAndAttachToParent:(UIViewController*)parent;

// Actions
- (IBAction)nextButtonTapped:(id)sender;
- (IBAction)stopButtonTapped:(id)sender;

@end
