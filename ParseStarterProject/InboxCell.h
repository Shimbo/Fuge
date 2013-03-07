//
//  InboxCell.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 2/11/13.
//
//

#import <UIKit/UIKit.h>

@class AsyncImageView;

@interface InboxCell : UITableViewCell

@property (strong, nonatomic) IBOutlet AsyncImageView *mainImage;
@property (strong, nonatomic) IBOutlet AsyncImageView *iconImage;

@property (strong, nonatomic) IBOutlet UILabel *subject;
@property (strong, nonatomic) IBOutlet UILabel *message;
@property (strong, nonatomic) IBOutlet UILabel *misc;

@end