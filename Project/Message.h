//
//  Message.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/31/13.
//
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@class Person;

@interface Message : NSObject
{
    NSString    *strUserFrom;
    NSString    *strUserTo;
    NSString    *strText;
    PFUser      *objUserFrom;
    PFUser      *objUserTo;
    NSString    *strNameUserFrom;
    NSString    *strNameUserTo;
    NSDate      *dateCreated;
    
    // Write only during save method and loading
    PFObject*   messageData;
}

@property (nonatomic, copy) NSString *strUserFrom;
@property (nonatomic, copy) NSString *strUserTo;
@property (nonatomic, copy) NSString *strText;
@property (nonatomic) PFUser *objUserFrom;
@property (nonatomic) PFUser *objUserTo;
@property (nonatomic, copy) NSString *strNameUserFrom;
@property (nonatomic, copy) NSString *strNameUserTo;
@property (nonatomic, copy) NSDate *dateCreated;

-(id) init;
-(id) initWithWelcomeMessage;
-(void) save:(id)target selector:(SEL)selector;
-(void) unpack:(PFObject*)data;
-(Person*) owner;
-(Boolean) isOwn;

@end
