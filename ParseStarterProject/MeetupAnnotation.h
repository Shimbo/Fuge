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

typedef enum kPinColor{
    PinOrange = 1,
    PinBlue,
    PinGray
}PinColor;

typedef enum kPinPrivacy{
    PinPrivate = 1,
    PinPublic
}PinPrivacy;

@interface MeetupAnnotation : REVClusterPin <MKAnnotation>
{

}

- (id)initWithMeetup:(Meetup*)meetup;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) Meetup* meetup;
@property (nonatomic, strong) NSString *strId;
@property (nonatomic, assign) PinPrivacy pinPrivacy;
@property (nonatomic, assign) PinColor pinColor;
@property (nonatomic, assign) CGFloat time;
@property (nonatomic, readonly)NSUInteger numUnreadCount;


@end





@interface ThreadAnnotation : MeetupAnnotation

@end
