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
#import "GeoObject.h"

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
    IMPORTED_NOT        = 0,
    IMPORTED_FACEBOOK   = 1,
    IMPORTED_EVENTBRITE = 2,
    IMPORTED_MEETUP     = 3
}EImportedType;

@class FSVenue;
@class Person;

@interface Meetup : GeoObject <EKEventEditViewDelegate, UIAlertViewDelegate>
{
    EMeetupType  meetupType;
    
    NSString    *strId;
    NSString    *strOwnerId;
    NSString    *strOwnerName;
    NSString    *strSubject;
    NSString    *strDescription;
    NSString    *strVenue;
    NSString    *strVenueId;
    NSString    *strAddress;
    NSDate      *dateTime;
    NSDate      *dateTimeExp;
    EMeetupPrivacy  privacy;
    NSUInteger  iconNumber;
    
    NSString    *strPrice;
    NSNumber    *maxGuests;
    NSString    *strImageURL;
    NSString    *strOriginalURL;
    
    NSUInteger  durationSeconds;
    
    NSUInteger  numComments;
    NSMutableArray* attendees;
    NSMutableArray* decliners;
    
    Boolean     bImportedEvent;
    NSUInteger  importedType;
    
    NSString    *strFeatured;
    
    Boolean     isCanceled;
    
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
@property (nonatomic, copy) NSString *strFeatured;

@property (nonatomic, copy) NSString *strPrice;
@property (nonatomic, copy) NSNumber *maxGuests;
@property (nonatomic, copy) NSString *strImageURL;
@property (nonatomic, copy) NSString *strOriginalURL;

@property (nonatomic, copy) PFObject *meetupData;

-(id) init;
-(Boolean) save:(id)target selector:(SEL)selector;
-(void) unpack:(PFObject*)data;
-(Boolean) feature:(NSString*)feature;

-(id) initWithFbEvent:(NSDictionary*)data;
-(id) initWithEbEvent:(NSDictionary*)data;
-(id) initWithMtEvent:(NSDictionary*)data;

-(Boolean) addedToCalendar;
-(void) addToCalendar;

-(void)populateWithVenue:(FSVenue*)venue;
-(void)populateWithCoords;

-(NSUInteger)getUnreadMessagesCount;
-(Boolean)hasPassed;
-(Boolean)isWithinTimeFrame:(NSDate*)windowStart till:(NSDate*)windowEnd;
-(float)getTimerTill;

// Only in local version, not on server (separate cloud code)
-(Boolean)hasAttendee:(NSString*)str;
-(void)addAttendee:(NSString*)str;
-(void)removeAttendee:(NSString*)str;

-(void)setCanceled;
-(Boolean)isCanceled;

-(NSInteger)spotsAvailable;

-(Boolean)willStartSoon;
-(Boolean)isPersonNearby:(Person*)person;

@end
