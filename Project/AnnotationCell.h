//
//  PersonAnnotationCell.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/27/13.
//
//


#import "MeetupAnnotationView.h"
#import "ThreadAnnotationView.h"
#import "PersonAnnotationView.h"

@protocol AnnotationCell <NSObject>

-(void)prepareForAnnotation:(id)annotation;

@end

@interface PersonAnnotationCell : UITableViewCell<AnnotationCell>
{
    IBOutlet PersonPin *_annotationPin;
}
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *subtitle;


@end


@class FUGEvent;
@class ULMusicPlayButton;
@interface MeetupAnnotationCell : UITableViewCell<AnnotationCell>
{
    FUGEvent                *_meetup;
    NSMutableArray          *_avatarList;
    IBOutlet MeetupPin      *_annotationPin;
}
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *subtitle;
@property (strong, nonatomic) IBOutlet UILabel *date;
@property (strong, nonatomic) IBOutlet UILabel *attending;
@property (strong, nonatomic) IBOutlet UILabel *distance;
@property (strong, nonatomic) IBOutlet UILabel *featured;
@property (strong, nonatomic) IBOutlet UIImageView *featuredImage;
@property (strong, nonatomic) ULMusicPlayButton *musicButton;

- (void)initWithMeetup:(FUGEvent*)meetup continuous:(Boolean)continuous;
- (void)previewTapped:(id)sender;

@end


@interface ThreadAnnotationCell : UITableViewCell<AnnotationCell>
{
    IBOutlet ThreadPin *_annotationPin;
}
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *subtitle;

@end