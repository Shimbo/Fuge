//
//  Meetup.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

enum EMeetupType
{
    TYPE_MEETUP     = 0,
    TYPE_THREAD     = 1
};

enum EMeetupPrivacy
{
    MEETUP_PUBLIC   = 0,
    MEETUP_2O       = 1,
    MEETUP_PRIVATE  = 2
};
@class FSVenue;

@interface Meetup : NSObject <EKEventEditViewDelegate, UIAlertViewDelegate>
{
    NSString    *strId;
    NSString    *strOwnerId;
    NSString    *strOwnerName;
    NSString    *strSubject;
    NSString    *strVenue;
    NSString    *strAddress;
    NSDate      *dateTime;
    PFGeoPoint  *location;
    NSUInteger  privacy;
    
    // Write only during save method and loading
    PFObject*   meetupData;
}

@property (nonatomic, copy) NSString *strId;
@property (nonatomic, copy) NSString *strOwnerId;
@property (nonatomic, copy) NSString *strOwnerName;
@property (nonatomic, copy) NSString *strSubject;
@property (nonatomic, copy) NSDate *dateTime;
@property (nonatomic, copy) PFGeoPoint *location;
@property (nonatomic, copy) NSString *strVenue;
@property (nonatomic, copy) NSString *strAddress;
@property (nonatomic, assign) NSUInteger privacy;

@property (nonatomic, copy) PFObject *meetupData;

-(id) init;
-(void) save;
-(void) unpack:(PFObject*)data;

-(Boolean) addedToCalendar;
-(void) addToCalendar:(UIViewController*)controller shouldAlert:(Boolean)alert;


-(void)populateWithVenue:(FSVenue*)venue;
@end
