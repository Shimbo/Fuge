

@class AsyncImageView;
@class Person;

@interface PersonCell : UITableViewCell 

@property (strong, nonatomic) IBOutlet UILabel *personDistance;
@property (strong, nonatomic) IBOutlet AsyncImageView *personImage;
@property (strong, nonatomic) IBOutlet UILabel *personName;
@property (strong, nonatomic) IBOutlet UILabel *personInfo;
@property (strong, nonatomic) IBOutlet UILabel *personStatus;
#ifdef TARGET_S2C
@property (strong, nonatomic) IBOutlet UILabel *personRole;
#endif
@property (strong, nonatomic) UIColor *color;
@property (nonatomic, assign) Boolean shouldDrawMatches;

-(void) initWithPerson:(Person*)person engagement:(Boolean)engagement;

@end
