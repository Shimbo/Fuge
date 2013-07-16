//
//  VenueCell.h
//  SecondCircle
//
//  Created by Constantine Fry on 1/17/13.
//
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
@interface VenueCell : UITableViewCell
@property (strong, nonatomic) IBOutlet AsyncImageView *icon;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *distance;
@property (strong, nonatomic) IBOutlet UILabel *address;

@end
