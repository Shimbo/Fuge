//
//  FUGEvent.h
//  Fuge
//
//  Created by Mikhail Larionov on 9/25/13.
//
//

#import "ULEvent.h"
#import "ULEvent+ThirdPartyLoaders.h"
#import "FSVenue.h"

@interface FUGEvent : ULEvent
{
    PFObject *_meetupData;
    NSString *_featureString;
}

@property (nonatomic, readonly) PFObject *meetupData;
@property (nonatomic, readonly) NSString *featureString;

-(id) initWithParseEvent:(PFObject*)data;
-(Boolean) save:(id)target selector:(SEL)selector;

-(Boolean) feature:(NSString*)feature;
- (void) cancel:(id)target selector:(SEL)selector;

-(void)populateWithVenue:(FSVenue*)venue;
-(void)populateWithCoords:(PFGeoPoint*)newLocation;

@end
