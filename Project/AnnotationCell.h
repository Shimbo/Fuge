//
//  PersonAnnotationCell.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/27/13.
//
//



@class PersonAnnotation;
@class PersonPin;
@class MeetupAnnotation;
@class MeetupPin;
@class ThreadAnnotation;
@class ThreadPin;

@protocol AnnotationCell <NSObject>

-(void)prepareForAnnotation:(id)annotation;

@end

@interface PersonAnnotationCell : UITableViewCell<AnnotationCell>
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *subtitle;
@property (strong, nonatomic) IBOutlet PersonPin *annotation;


@end


@class Meetup;
@interface MeetupAnnotationCell : UITableViewCell<AnnotationCell>
{
    NSMutableArray* avatarList;
}
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *subtitle;
@property (strong, nonatomic) IBOutlet UILabel *date;
@property (strong, nonatomic) IBOutlet UILabel *attending;
@property (strong, nonatomic) IBOutlet UILabel *distance;
@property (strong, nonatomic) IBOutlet MeetupPin *annotation;
@property (strong, nonatomic) IBOutlet UILabel *featured;
@property (strong, nonatomic) IBOutlet UIImageView *featuredImage;

-(void)initWithMeetup:(Meetup*)meetup continuous:(Boolean)continuous;

@end


@interface ThreadAnnotationCell : UITableViewCell<AnnotationCell>
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *subtitle;
@property (strong, nonatomic) IBOutlet ThreadPin *annotation;

@end