//
//  PersonAnnotation.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "REVClusterPin.h"

@class Person;
@interface PersonAnnotation : REVClusterPin <MKAnnotation>
{
//    CLLocationCoordinate2D coordinate;
//    NSString *title;
//    NSString *subtitle;
}
- (id)initWithPerson:(Person*)person;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
//@property (nonatomic, strong) NSString *title;
//@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, readonly) NSString *imageURL;
@property (nonatomic, readonly) NSUInteger numUnreadCount;
@property (nonatomic, strong) Person* person;

@end
