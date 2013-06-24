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

typedef enum kEImportedType
{
    IMPORTED_FACEBOOK    = 0,
    IMPORTED_EVENTBRITE  = 1
}EImportedType;

@class FSVenue;

@interface Meetup : NSObject <EKEventEditViewDelegate, UIAlertViewDelegate>
{
    EMeetupType  meetupType;
    
    NSString    *strId;
    NSString    *strOwnerId;
    NSString    *strOwnerName;
    NSString    *strSubject;
    NSString    *strDescription;    // for exported meetups is be used as the first comment
    NSString    *strVenue;
    NSString    *strVenueId;
    NSString    *strAddress;
    NSDate      *dateTime;
    NSDate      *dateTimeExp;
    PFGeoPoint  *location;
    EMeetupPrivacy  privacy;
    NSUInteger  iconNumber;
    
    NSUInteger  durationSeconds;
    
    NSUInteger  numComments;
    NSMutableArray* attendees;
    NSMutableArray* decliners;
    
    Boolean     bImportedEvent;
    NSUInteger  importedType;
    
    // Write only during save method and loading
    PFObject*   meetupData;
}

@property (nonatomic, copy) NSString *strId;
@property (nonatomic, copy) NSString *strOwnerId;
@property (nonatomic, copy) NSString *strOwnerName;
@property (nonatomic, copy) NSString *strSubject;
@property (nonatomic, copy) NSString *strDescription;
@property (nonatomic, copy) NSDate *dateTime;
@property (nonatomic, copy) NSDate *dateTimeExp;
@property (nonatomic, copy) PFGeoPoint *location;
@property (nonatomic, copy) NSString *strVenue;
@property (nonatomic, copy) NSString *strVenueId;
@property (nonatomic, copy) NSString *strAddress;
@property (nonatomic, assign) EMeetupPrivacy privacy;
@property (nonatomic, assign) EMeetupType meetupType;
@property (nonatomic, assign) NSUInteger numComments;
@property (nonatomic, copy) NSMutableArray* attendees;
@property (nonatomic, copy) NSMutableArray* decliners;
@property (nonatomic, assign) NSUInteger durationSeconds;
@property (nonatomic, assign) NSUInteger iconNumber;
@property (nonatomic, assign) Boolean bImportedEvent;
@property (nonatomic, assign) NSUInteger importedType;

@property (nonatomic, copy) PFObject *meetupData;

-(id) init;
-(Boolean) save;
-(void) unpack:(PFObject*)data;

-(id) initWithFbEvent:(NSDictionary*)data;
-(id) initWithEbEvent:(NSDictionary*)eventData;

-(Boolean) addedToCalendar;
-(void) addToCalendar;

-(void)populateWithVenue:(FSVenue*)venue;
-(void)populateWithCoords;

-(NSUInteger)getUnreadMessagesCount;
-(Boolean)hasPassed;
-(float)getTimerTill;

// Only in local version, not on server (separate cloud code)
-(void)addAttendee:(NSString*)str;
-(void)removeAttendee:(NSString*)str;

-(Boolean) passed;

@end
