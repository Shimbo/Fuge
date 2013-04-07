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

typedef enum kEMeetupType
{
    TYPE_THREAD     = 0,
    TYPE_MEETUP     = 1
}EMeetupType;

typedef enum kEMeetupPrivacy
{
    MEETUP_PUBLIC   = 0,
    MEETUP_PRIVATE  = 1
}EMeetupPrivacy;
@class FSVenue;

@interface Meetup : NSObject <EKEventEditViewDelegate, UIAlertViewDelegate>
{
    EMeetupType  meetupType;
    
    NSString    *strId;
    NSString    *strOwnerId;
    NSString    *strOwnerName;
    NSString    *strSubject;
    NSString    *strVenue;
    NSString    *strAddress;
    NSDate      *dateTime;
    NSDate      *dateTimeExp;
    PFGeoPoint  *location;
    EMeetupPrivacy  privacy;
    
    NSUInteger  durationSeconds;
    
    NSUInteger  numComments;
    NSUInteger  numAttendees;
    
    // Write only during save method and loading
    PFObject*   meetupData;
}

@property (nonatomic, copy) NSString *strId;
@property (nonatomic, copy) NSString *strOwnerId;
@property (nonatomic, copy) NSString *strOwnerName;
@property (nonatomic, copy) NSString *strSubject;
@property (nonatomic, copy) NSDate *dateTime;
@property (nonatomic, copy) NSDate *dateTimeExp;
@property (nonatomic, copy) PFGeoPoint *location;
@property (nonatomic, copy) NSString *strVenue;
@property (nonatomic, copy) NSString *strAddress;
@property (nonatomic, assign) EMeetupPrivacy privacy;
@property (nonatomic, assign) EMeetupType meetupType;
@property (nonatomic, assign) NSUInteger numComments;
@property (nonatomic, assign) NSUInteger numAttendees;
@property (nonatomic, assign) NSUInteger durationSeconds;

@property (nonatomic, copy) PFObject *meetupData;

-(id) init;
-(void) save;
-(void) unpack:(PFObject*)data;

-(Boolean) addedToCalendar;
-(void) addToCalendar:(UIViewController*)controller shouldAlert:(Boolean)alert;

-(void)populateWithVenue:(FSVenue*)venue;
-(void)populateWithCoords;

-(NSUInteger)getUnreadMessagesCount;
-(Boolean)hasPassed;
-(float)getTimerTill;

@end
