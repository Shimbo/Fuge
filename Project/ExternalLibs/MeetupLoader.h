//
//  MeetupLoader.h
//  meetup
//
//  Created by 0 on 7/30/13.
//
//

#import <Foundation/Foundation.h>

#define mtLoader [MeetupLoader sharedInstance]

@interface MeetupLoader : NSObject

+(id)sharedInstance;

-(void)loadMeetup:(NSString*)meetupId owner:(id)target selector:(SEL)callback;
-(void)loadMeetups:(NSString*)groupUrl owner:(id)target selector:(SEL)callback;

@end
