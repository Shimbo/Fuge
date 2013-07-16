//
//  PersonInviteCell.h
//  SecondCircle
//
//  Created by Constantine Fry on 3/8/13.
//
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface PersonInviteCell : UITableViewCell
@property (strong, nonatomic) IBOutlet AsyncImageView *personImage;
@property (strong, nonatomic) IBOutlet UILabel *personName;

@end
