//
//  FUGDeezerWrapper.m
//  Fuge
//
//  Created by Mikhail Larionov on 9/27/13.
//
//

#import "ULDeezerWrapper.h"
#import "PlayerFactory.h"

@implementation ULDeezerWrapper

#pragma mark -
#pragma mark Singleton

static ULDeezerWrapper *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (ULDeezerWrapper *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// We don't want to allocate a new instance, so return the current one.
+ (id)allocWithZone:(NSZone*)zone {
    return [self sharedInstance];
}

// Equally, we don't want to generate multiple copies of the singleton.
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)init
{
    self = [super init];
    
    return self;
}

- (void) initializeWithAPIKey:(NSString*)strKey
{
    _deezerConnect = [[DeezerConnect alloc] initWithAppId:strKey andDelegate:self];
    
    tracksForArtistAvailable = [NSMutableDictionary dictionary];
    _artistsLoadingQueue = [NSMutableArray array];
    
    // Start playing and perform selector in any case
    _deezerPlayer = [PlayerFactory createPlayer];
    [_deezerPlayer setPlayerDelegate:self];
    [_deezerPlayer setBufferDelegate:self];
}

- (void) loadArtistData:(NSString*)artist
{
    NSString* url = @"search/artist";
    DeezerRequest* request = [_deezerConnect createRequestWithServicePath:url params:[NSDictionary dictionaryWithObjectsAndKeys:artist, @"q", nil] delegate:self];
    [_deezerConnect launchAsyncRequest:request];
}

- (BOOL) prepareArtist:(NSString*)artist target:(id)target selector:(SEL)callback
{
    if ( ! artist )
        return FALSE;
    
    // If data is already loaded
    NSDictionary* alreadyLoaded = [tracksForArtistAvailable objectForKey:artist];
    if ( alreadyLoaded )
    {
        if ( alreadyLoaded == (NSDictionary*) [NSNull null] )
            alreadyLoaded = nil;
        [target performSelector:callback withObject:alreadyLoaded];
        return FALSE;
    }
    
    // Start loading if queue is emtpy
    if ( _artistsLoadingQueue.count == 0 )
    {
        _artistForLookup = artist;
        [self loadArtistData:artist];
    }
    
    // Add artist to the queue
    NSDictionary* callInfo = [NSDictionary dictionaryWithObjectsAndKeys:artist, @"artist",
                              target, @"target", [NSValue valueWithPointer:callback], @"callback", nil];
    [_artistsLoadingQueue addObject:callInfo];
    
    return TRUE;
}

- (NSDictionary*) artistInformation:(NSString*)artist
{
    if ( ! artist )
        return nil;
    
    // No info on server
    if ( [tracksForArtistAvailable objectForKey:artist] == [NSNull null] )
        return nil;
    
    return [tracksForArtistAvailable objectForKey:artist];
}

/*- (void) playArtist:(NSString*)artist target:(id)target selector:(SEL)callback
{
    targetResult = target;
    callbackResult = callback;
    artistForLookup = artist;
    
    currentTrack = -1;
    
    NSString* url = @"search/artist";
    DeezerRequest* request = [_deezerConnect createRequestWithServicePath:url params:[NSDictionary dictionaryWithObjectsAndKeys:artist, @"q", nil] delegate:self];
    [_deezerConnect launchAsyncRequest:request];
}*/

- (void) stopPlaying
{
    if ( _deezerPlayer )
        [_deezerPlayer stop];
    _currentArtist = nil;
    _trackProgress = _bufferProgress = 0.0;
    [[NSNotificationCenter defaultCenter]postNotificationName:kTrackOrBufferProgressUpdated object:nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:kMusicTrackStopped object:nil];
}

- (NSString*) nowPlaying
{
    return _currentArtist;
}

- (void) playNextTrack:(NSString*)artist inCycle:(BOOL)loop
{
    if ( ! artist && ! _currentArtist )
        return;
    
    NSString* artistToPlay = artist;
    if ( ! artistToPlay )
        artistToPlay = _currentArtist;
    
    NSDictionary* artistData = [tracksForArtistAvailable objectForKey:artistToPlay];
    if ( ! artistData )
        return;
    
    NSArray* trackIds = [artistData objectForKey:@"trackIds"];
    NSArray* trackNames = [artistData objectForKey:@"trackNames"];
    NSArray* trackPreviews = [artistData objectForKey:@"trackPreviews"];
    NSArray* trackRatings = [artistData objectForKey:@"trackRatings"];
    if ( ! trackIds || ! trackPreviews )
        return;
    
    // Stop playing what was playing before
    //if ( _deezerPlayer )
    //[_deezerPlayer stop];
    
    _totalTracksCount = trackIds.count;
    if ( ! artist )
    {
        _currentTrackNumber++;
        if ( _currentTrackNumber >= _totalTracksCount )
        {
            if (loop)
                _currentTrackNumber = 0;
            else
                return;
        }
    }
    else
        _currentTrackNumber = 0;
    
    _bufferProgress = _trackProgress = 0.0;
    [[NSNotificationCenter defaultCenter]postNotificationName:kTrackOrBufferProgressUpdated object:nil];
    
    _currentArtist = artistToPlay;
    _currentTrackName = trackNames[ _currentTrackNumber ];
    _currentTrackRating = trackRatings[ _currentTrackNumber ];
    NSString *trackid = trackIds[ _currentTrackNumber ];
    NSString *urlString = trackPreviews[ _currentTrackNumber ];
    
    [_deezerPlayer preparePlayerForPreviewWithURL:urlString trackID:trackid andDeezerConnect:_deezerConnect];
    
    if ( artist )
        [[NSNotificationCenter defaultCenter]postNotificationName:kMusicArtistChanged object:nil];
    else
        [[NSNotificationCenter defaultCenter]postNotificationName:kMusicTrackChanged object:nil];
}

- (void)deezerDidLogin {
    NSLog(@"Deezer did login");
}

- (void)deezerDidNotLogin:(BOOL)cancelled {
    NSLog(@"Deezer Did not login %@", cancelled ? @"Cancelled" : @"Not Cancelled");
}

- (void)deezerDidLogout {
    NSLog(@"Deezer Did logout");
}

- (void)request:(DeezerRequest *)request didReceiveResponse:(NSData *)data {
    NSError *jsonError;
    NSDictionary* jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)NSJSONWritingPrettyPrinted error:&jsonError];
    //NSLog(@"Deezer response received: %@", jsonDictionary);
    
    NSMutableArray  *arrayTrackIds;
    NSMutableArray  *arrayTrackNames;
    NSMutableArray  *arrayPreviews;
    NSMutableArray  *arrayRatings;
    NSDictionary    *dictionaryData;
    
    NSString* type = [jsonDictionary objectForKey:@"type"];
    if ( ! type )
    {
        if ( [jsonDictionary objectForKey:@"total"] )
            if ( [[jsonDictionary objectForKey:@"total"] integerValue] > 0 )
            {
                NSArray* items = [jsonDictionary objectForKey:@"data"];
                for ( NSDictionary* item in items )
                {
                    type = [item objectForKey:@"type"];
                    if ( type )
                    {
                        // We've got artist data
                        if ( [type compare:@"artist"] == NSOrderedSame )
                        {
                            NSString* bandName = [item objectForKey:@"name"];
                            if ( [[bandName lowercaseString] compare:[_artistForLookup lowercaseString]] == NSOrderedSame )
                            {
                                NSString* url = [NSString stringWithFormat:@"artist/%@/top", [item objectForKey:@"id"]];
                                DeezerRequest* request = [_deezerConnect createRequestWithServicePath:url params:nil delegate:self];
                                [_deezerConnect launchAsyncRequest:request];
                                _strTempArtistImage = [item objectForKey:@"picture"];
                                _strTempArtistLink = [item objectForKey:@"link"];
                                return;
                            }
                        }
                        // We've got track data
                        if ( [type compare:@"track"] == NSOrderedSame )
                        {
                            Boolean firstTrack = ! arrayTrackIds;
                            
                            if ( firstTrack )
                            {
                                arrayTrackIds = [NSMutableArray arrayWithCapacity:items.count];
                                arrayTrackNames = [NSMutableArray arrayWithCapacity:items.count];
                                arrayPreviews = [NSMutableArray arrayWithCapacity:items.count];
                                arrayRatings = [NSMutableArray arrayWithCapacity:items.count];
                                dictionaryData = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                arrayTrackIds, @"trackIds",
                                                                arrayTrackNames, @"trackNames",
                                                                arrayPreviews, @"trackPreviews",
                                                                arrayRatings, @"trackRatings",
                                                                _strTempArtistImage, @"artistImage",
                                                                _strTempArtistLink, @"artistLink", nil];
                                [tracksForArtistAvailable setObject:dictionaryData forKey:_artistForLookup];
                            }
                            
                            NSString *trackid = [item objectForKey:@"id"];
                            [arrayTrackIds addObject:trackid];
                            NSString *trackname = [item objectForKey:@"title"];
                            [arrayTrackNames addObject:trackname];
                            NSString *urlString = [item objectForKey:@"preview"];
                            [arrayPreviews addObject:urlString];
                            NSString *rating = [item objectForKey:@"rank"];
                            [arrayRatings addObject:rating];
                        }
                    }
                }
            }
    }
    
    // Return loaded data
    NSDictionary* loadData;
    for ( NSDictionary* data in _artistsLoadingQueue )
        if ( [[data objectForKey:@"artist"] isEqualToString:_artistForLookup] )
        {
            loadData = data;
            [_artistsLoadingQueue removeObject:data];
            break;
        }
    
    // Callback (even with null data passed)
    id target = [loadData objectForKey:@"target"];
    SEL callback = [[loadData objectForKey:@"callback"] pointerValue];
    [target performSelector:callback withObject:dictionaryData];
    
    // Set null array so we won't reload in from server in future
    if ( ! arrayTrackIds )
        [tracksForArtistAvailable setObject:[NSNull null] forKey:_artistForLookup];
    
    // Continue loading
    if ( _artistsLoadingQueue.count > 0 )
    {
        _artistForLookup = [_artistsLoadingQueue[0] objectForKey:@"artist"];
        [self loadArtistData:_artistForLookup];
    }

}

- (void)request:(DeezerRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Deezer response failed: %@", error);
}


#pragma mark - PlayerDelegate
/* The player has a new state */

/*- (void)nextTrackAuto
{
    [self playNextTrack:nil inCycle:NO];
}*/

- (void)player:(PlayerFactory*)player stateChanged:(DeezerPlayerState)playerState {
    /*if ( playerState == DeezerPlayerState_Finished )
    {
        [self playNextTrack:nil inCycle:NO];
        [player performSelector:@selector(play) withObject:nil afterDelay:0.3];
    }*/
    //    [self performSelector:@selector(nextTrackAuto) withObject:nil afterDelay:0.3];
}

/* Progress of playing */
- (void)player:(PlayerFactory*)player timeChanged:(long)time {
    _trackProgress = (float)time / 29.0f;
    [[NSNotificationCenter defaultCenter]postNotificationName:kTrackOrBufferProgressUpdated object:nil];
    //NSLog(@"Deezer player progress changed: %ld", time);
}

/* An error occurred while playing */
- (void)player:(PlayerFactory*)player didFailWithError:(NSError*)error {
    NSLog(@"Deezer player failed: %@", error);
}


#pragma mark - BufferDelegate
/*  The buffer has a new state */
- (void)bufferStateChanged:(BufferState)bufferState {
    if (bufferState == BufferState_Started) {
        [_deezerPlayer play]; /* We try to play the track */
    }
    else if (bufferState == BufferState_Paused) {
    }
    else if (bufferState == BufferState_Ended) {
    }
    else if (bufferState == BufferState_Stopped) {
    }
}

/* Progress of the buffering */
- (void)bufferProgressChanged:(float)bufferProgress {
    _bufferProgress = bufferProgress;
    [[NSNotificationCenter defaultCenter]postNotificationName:kTrackOrBufferProgressUpdated object:nil];
    //NSLog(@"Deezer buffer progress changed: %f", bufferProgress);
}

/* An error occurred while buffering */
- (void)bufferDidFailWithError:(NSError*)error {
    NSLog(@"Deezer buffer failed: %@", error);
}

- (void)checkVolume
{
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    
    // Mute or not
    CFStringRef state;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
    BOOL bMuted = CFStringGetLength(state) <= 0;
    
    // Volume
    Float32 volume;
    propertySize = sizeof(Float32);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputVolume, &propertySize, &volume);
    
    if ( bMuted || volume < 0.05 )
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Friendly advice" message:[NSString stringWithFormat:@"Your volume level is too low or muted. Turn it on to listen."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (NSString*)artistCover:(NSString*)artist
{
    if ( ! artist )
        return nil;
    
    NSDictionary* info = [self artistInformation:artist];
    if ( ! info )
        return nil;
    
    return [info objectForKey:@"artistImage"];
}

@end
