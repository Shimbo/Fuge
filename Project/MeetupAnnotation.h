//
//  MeetupAnnotation.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Meetup.h"
#import "REVClusterPin.h"



typedef enum kPinPrivacy{
    PinPrivate = 1,
    PinPublic
}PinPrivacy;

@class Person;
@interface MeetupAnnotation : REVClusterPin <MKAnnotation>
{
    Meetup* meetup;
}

- (id)initWithMeetup:(Meetup*)m;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) Meetup* meetup;
@property (nonatomic,strong) NSMutableArray *attendedPersons;
@property (nonatomic, strong) NSString *strId;
@property (nonatomic, assign) PinPrivacy pinPrivacy;
@property (nonatomic, readonly)NSUInteger numUnreadCount;
@property (nonatomic, readonly)NSUInteger numAttendedPersons;

-(void)addPerson:(Person*)person;
- (void)configureAnnotation;

@end





@interface ThreadAnnotation : MeetupAnnotation

@end
