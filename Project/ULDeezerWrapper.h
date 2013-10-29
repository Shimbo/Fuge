//
//  FUGDeezerWrapper.h
//  Fuge
//
//  Created by Mikhail Larionov on 9/27/13.
//
//

#import <Foundation/Foundation.h>
#import "DeezerConnect.h"
#import "PlayerDelegate.h"
#import "BufferDelegate.h"

#define deezerWrapper [ULDeezerWrapper sharedInstance]

static NSString *const kMusicArtistChanged = @"kMusicArtistChanged";
static NSString *const kMusicTrackChanged = @"kMusicTrackChanged";
static NSString *const kMusicTrackStopped = @"kMusicTrackStopped";
static NSString *const kTrackOrBufferProgressUpdated = @"kTrackOrBufferProgressUpdated";

@interface ULDeezerWrapper : NSObject <DeezerSessionDelegate, DeezerRequestDelegate, PlayerDelegate, BufferDelegate>
{
    DeezerConnect *_deezerConnect;
    PlayerFactory *_deezerPlayer;
    
    NSInteger           _currentTrackNumber;
    NSInteger           _totalTracksCount;
    
    NSMutableDictionary *tracksForArtistAvailable;
    NSString            *_strTempArtistImage;
    NSString            *_strTempArtistLink;
    
    NSString            *_currentArtist;
    NSString            *_currentTrackName;
    NSString            *_currentTrackRating;
    
    NSMutableArray      *_artistsLoadingQueue;
    NSString            *_artistForLookup;
    
    float               _trackProgress, _bufferProgress;
}

@property (readonly) NSString* currentArtist;
@property (readonly) NSString* currentTrackName;
@property (readonly) NSString* currentTrackRating;
@property (readonly) float trackProgress;
@property (readonly) float bufferProgress;
@property (readonly) NSInteger currentTrackNumber;
@property (readonly) NSInteger totalTracksCount;

+ (ULDeezerWrapper*) sharedInstance;

- (void) initializeWithAPIKey:(NSString*)strKey;

- (BOOL) prepareArtist:(NSString*)artist target:(id)target selector:(SEL)callback;

- (NSDictionary*) artistInformation:(NSString*)artist;

//- (void) playArtist:(NSString*)artist target:(id)target selector:(SEL)callback;
- (void) playNextTrack:(NSString*)artist inCycle:(BOOL)loop;
- (void) stopPlaying;

- (NSString*) nowPlaying;

- (void)checkVolume;

- (NSString*)artistCover:(NSString*)artist;

@end
