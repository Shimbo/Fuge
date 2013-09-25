//
//  MeetupAnnotation.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "FUGEvent.h"
#import "REVClusterPin.h"



typedef enum kPinPrivacy{
    PinPrivate = 1,
    PinPublic
}PinPrivacy;

@class Person;
@interface MeetupAnnotation : REVClusterPin <MKAnnotation>
{
    FUGEvent* meetup;
}

- (id)initWithMeetup:(FUGEvent*)m;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) FUGEvent* meetup;
@property (nonatomic,strong) NSMutableArray *attendedPersons;
@property (nonatomic, strong) NSString *strId;
@property (nonatomic, assign) PinPrivacy pinPrivacy;
//@property (nonatomic, readonly)NSUInteger numUnreadCount;
@property (nonatomic, readonly)NSUInteger numAttendedPersons;

-(void)addPerson:(Person*)person;
- (void)configureAnnotation;

@end





@interface ThreadAnnotation : MeetupAnnotation

@end
