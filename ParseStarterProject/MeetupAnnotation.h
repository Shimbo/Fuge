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

@interface MeetupAnnotation : NSObject <MKAnnotation>
{
    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
    NSUInteger color;
    Meetup* meetup;
    NSString* strId;
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) NSUInteger color;
@property (nonatomic, retain) Meetup* meetup;
@property (nonatomic, copy) NSString *strId;

@end
