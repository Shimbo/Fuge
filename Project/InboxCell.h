//
//  InboxCell.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 2/11/13.
//
//

#import <UIKit/UIKit.h>

@class AsyncImageView;
@class MeetupPin;

@interface InboxCell : UITableViewCell

@property (strong, nonatomic) IBOutlet AsyncImageView *mainImage;
@property (strong, nonatomic) IBOutlet MeetupPin *pinImage;

@property (strong, nonatomic) IBOutlet UILabel *subject;
@property (strong, nonatomic) IBOutlet UILabel *message;
@property (strong, nonatomic) IBOutlet UILabel *misc;

@end