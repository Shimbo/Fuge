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
}

@property (nonatomic, readonly) PFObject *meetupData;

// For custom event creation


-(id) initWithParseEvent:(PFObject*)data;
-(Boolean) save:(id)target selector:(SEL)selector;

- (void) cancel:(id)target selector:(SEL)selector;

-(void)populateWithVenue:(FSVenue*)venue;
-(void)populateWithCoords:(PFGeoPoint*)newLocation;

@end
