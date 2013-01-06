//
//  Meetup.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Meetup : NSObject
{
    NSString    *strId;
    NSString    *strOwnerId;
    NSString    *strOwnerName;
    NSString    *strSubject;
    NSUInteger  privacy;
    CLLocationCoordinate2D  location;
}

@property (nonatomic, copy) NSString *strId;
@property (nonatomic, copy) NSString *strOwnerId;
@property (nonatomic, copy) NSString *strOwnerName;
@property (nonatomic, copy) NSString *strSubject;
@property (nonatomic, assign) NSUInteger privacy;
@property (nonatomic, assign) CLLocationCoordinate2D location;

// TODO: create normal init

@end
