

@class AsyncImageView;
@class Person;
@class FUGOpportunitiesView;

@interface FUGMatchView : UIView
@property (strong, nonatomic) UIColor* color;
@end

@interface PersonCell : UITableViewCell
{
    FUGMatchView*           _matchingCircle;
    FUGOpportunitiesView*   _opportunitiesView;
}

@property (strong, nonatomic) IBOutlet UILabel *personDistance;
@property (strong, nonatomic) IBOutlet AsyncImageView *personImage;
@property (strong, nonatomic) IBOutlet UILabel *personName;
@property (strong, nonatomic) IBOutlet UILabel *personInfo;
#ifdef TARGET_FUGE
@property (strong, nonatomic) IBOutlet UILabel *personStatus;
#endif
#ifdef TARGET_S2C
@property (strong, nonatomic) IBOutlet UILabel *personRole;
@property (strong, nonatomic) IBOutlet UILabel *personCompany;
#endif

-(void) initWithPerson:(Person*)person engagement:(Boolean)engagement;

@end
