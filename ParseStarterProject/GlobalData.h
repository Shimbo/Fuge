//
//  GlobalData.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <Foundation/Foundation.h>
#import "Circle.h"
#import "Meetup.h"
#import "RootViewController.h"

#define globalData [GlobalData sharedInstance]

@interface GlobalData : NSObject
{
    NSMutableDictionary *circles;
    NSMutableArray      *meetups;
}

+ (id)sharedInstance;

- (Circle*) getCircle:(NSUInteger)circle;
- (NSArray*) getCircles;
- (NSArray*) getMeetups;

- (void)addMeetup:(Meetup*)meetup;
- (Meetup*) addMeetupWithData:(PFObject*)meetupData;

- (void)clean;
- (void)reload:(RootViewController*)controller;

@end
