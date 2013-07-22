//
//  Comment.h
//  Fuge
//
//  Created by Mikhail Larionov on 7/22/13.
//
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Comment : NSObject
{
    NSString    *strUserFrom;
    NSString    *strNameUserFrom;
    PFUser      *objUserFrom;
    
    NSString    *strComment;
    NSNumber    *systemType;
    
    NSString    *strMeetupId;
    NSString    *strMeetupSubject;
    PFObject    *meetupData;
    NSNumber    *typeNum;
    
    NSDate      *dateCreated;
    
    // Write only during save method and loading
    PFObject    *commentData;
}

@property (nonatomic, copy) NSString *strUserFrom;
@property (nonatomic, copy) NSString *strNameUserFrom;
@property (nonatomic) PFUser *objUserFrom;

@property (nonatomic, copy) NSString *strComment;
@property (nonatomic, copy) NSNumber *systemType;

@property (nonatomic, copy) NSString *strMeetupId;
@property (nonatomic, copy) NSString *strMeetupSubject;
@property (nonatomic) PFObject *meetupData;
@property (nonatomic, copy) NSNumber *typeNum; // meetup or thread, atavism

@property (nonatomic, copy) NSDate *dateCreated;

-(id) init;
-(void) save;
-(void) unpack:(PFObject*)data;

@end
