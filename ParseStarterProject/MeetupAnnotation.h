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

typedef enum kPinColor{
    PinOrange = 1,
    PinBlue,
    PinGray
}PinColor;

typedef enum kPinPrivacy{
    PinPrivate = 1,
    PinPublic
}PinPrivacy;

@interface MeetupAnnotation : NSObject <MKAnnotation>
{
    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
    NSString* strId;
}

- (id)initWithMeetup:(Meetup*)meetup;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) Meetup* meetup;
@property (nonatomic, strong) NSString *strId;
@property (nonatomic, assign) PinPrivacy pinPrivacy;
@property (nonatomic, assign) PinColor pinColor;
@property (nonatomic, assign) CGFloat time;
@property (nonatomic, readonly)NSUInteger numUnreadCount;


@end
