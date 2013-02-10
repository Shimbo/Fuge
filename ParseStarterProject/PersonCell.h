

@class AsyncImageView;
@interface PersonCell : UITableViewCell 

@property (strong, nonatomic) IBOutlet UILabel *personDistance;
@property (strong, nonatomic) IBOutlet AsyncImageView *personImage;
@property (strong, nonatomic) IBOutlet UILabel *personName;
@property (strong, nonatomic) IBOutlet UILabel *personRole;
@property (strong, nonatomic) IBOutlet UILabel *personArea;

@end
