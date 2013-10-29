//
//  FUGOpportunitiesView.m
//  Fuge
//
//  Created by Mikhail Larionov on 10/19/13.
//
//

#import "FUGOpportunitiesView.h"
#import "Person.h"
#import "NewOpportunityViewController.h"
#import "AppDelegate.h"
#import "UserProfileController.h"
#import "GlobalData.h"

@implementation FUGOpportunityView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.autoresizesSubviews = TRUE;
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        
        _icon = [[UIImageView alloc] initWithFrame:CGRectMake(8, 2, 16, 16)];
        _icon.image = [UIImage imageNamed:@"featured"];
        [self addSubview:_icon];
        
        _opportunityText = [[UITextView alloc] initWithFrame:CGRectMake(22, -6, frame.size.width-22-40-10-5, 50)];
        _opportunityText.font = [UIFont systemFontOfSize:14];
        _opportunityText.contentMode = UIViewContentModeTop;
        _opportunityText.userInteractionEnabled = FALSE;
        _opportunityText.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _opportunityText.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
        _opportunityText.scrollEnabled = FALSE;
        _opportunityText.editable = FALSE;
        _opportunityText.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_opportunityText];
        
        _replyButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _replyButton.frame = CGRectMake(frame.size.width - 70, 0, 60, 22);
        _replyButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_replyButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        if ( IOS_NEWER_OR_EQUAL_TO_7 )
        {
            [_replyButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            [_replyButton setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
        }
        [self addSubview:_replyButton];
    }
    return self;
}

- (void) buttonTapped
{
    if ( _owner.isCurrentUser )
    {
        if ( _op.isOutdated )
        {
            // Activate
            _op.dateUpdated = [NSDate date];
            [_owner saveOpportunity:_op];
            _opportunityText.textColor = [UIColor blackColor];
            [_replyButton setTitle:@"Edit" forState:UIControlStateNormal];
        }
        else
        {
            // Reply
            NewOpportunityViewController *opController = [[NewOpportunityViewController alloc]init];
            [opController setOpportunityToEdit:_op];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:opController];
            [AppDelegate.revealController presentViewController:nav animated:YES completion:nil];
        }
    }
    else
    {
        UINavigationController* root = (UINavigationController*) AppDelegate.revealController.frontViewController;
        UIViewController* current = root.visibleViewController;
        NSString* topic;
        if ( _op.text.length < 21 )
            topic = _op.text;
        else
            topic = [NSString stringWithFormat:@"%@...", [_op.text substringToIndex:20]];
        NSString* message = [NSString stringWithFormat:@"Re \"%@\":", topic];
        if ( [current isKindOfClass:[UserProfileController class]] )
        {
            UserProfileController *userProfileController = (UserProfileController*) current;
            [userProfileController setProfileMode:PROFILE_MODE_MESSAGES];
            [userProfileController setMessageText:message];
            [userProfileController updateUI];
        }
        else
        {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [userProfileController setPerson:_owner];
            [root pushViewController:userProfileController animated:YES];
            [userProfileController performSelector:@selector(setMessageText:) withObject:message afterDelay:0.5];
        }
    }
}

- (void) initWithOpportunity:(FUGOpportunity*)op by:(Person*)person isRead:(BOOL)read
{
    _op = op;
    _opportunityText.text = op.text;
    _owner = person;
    _isRead = read;
    
    //if ( ! read )
    //    self.backgroundColor = [UIColor colorWithHexString:OP_UNREAD_CELL_BG_COLOR];
    
    // Text
    UIColor* color = read ? [UIColor grayColor] : [UIColor blackColor];
    UIFont* font = [UIFont systemFontOfSize:14];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = /*bOwn ? NSTextAlignmentRight :*/ NSTextAlignmentLeft;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          paragraph, NSParagraphStyleAttributeName,
                                          color, NSForegroundColorAttributeName,
                                          nil];
    NSMutableAttributedString* strTemp = [[NSMutableAttributedString alloc] initWithString:op.text attributes:attributesDictionary];
    [strTemp addAttributes:attributesDictionary range:NSMakeRange(0, strTemp.length)];
    _opportunityText.attributedText = strTemp;
    
    // Height
    self.height = [FUGOpportunityView estimateOpportunityHeight:op.text];
    _opportunityText.height = self.height + 20;
    
    // Owner or not
    if ( person.isCurrentUser )
    {
        if ( op.isOutdated )
        {
            [_replyButton setTitle:@"Activate" forState:UIControlStateNormal];
            _opportunityText.textColor = [UIColor grayColor];
        }
        else
            [_replyButton setTitle:@"Edit" forState:UIControlStateNormal];
    }
    else
        [_replyButton setTitle:@"Reply" forState:UIControlStateNormal];
}

+ (NSUInteger) estimateOpportunityHeight:(NSString*)opportunity
{
    NSUInteger nBlockWidth;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    nBlockWidth = screenWidth - 22 -40 -10 -5;
    
    // Height
    UIFont* font = [UIFont systemFontOfSize:14];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = /*bOwn ? NSTextAlignmentRight :*/ NSTextAlignmentLeft;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          paragraph, NSParagraphStyleAttributeName,
                                          nil];
    NSMutableAttributedString* strTemp = [[NSMutableAttributedString alloc] initWithString:opportunity attributes:attributesDictionary];
    [strTemp addAttributes:attributesDictionary range:NSMakeRange(0, strTemp.length)];
    CGSize newSize;
    if ( IOS_NEWER_OR_EQUAL_TO_7 )
    {
        CGRect paragraphRect = [strTemp.string boundingRectWithSize:CGSizeMake(nBlockWidth-10, 9999) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributesDictionary context:nil];
        newSize = paragraphRect.size;
    }
    else
        newSize = [opportunity sizeWithFont:font constrainedToSize:CGSizeMake(nBlockWidth, CGFLOAT_MAX)];
    
    newSize.height += 6;
    if ( newSize.height < 24 )
        newSize.height = 24;
    
    return ceilf(newSize.height);
}

@end

@implementation FUGOpportunitiesView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _opportunities = [NSMutableArray array];
        
        self.height = 0;
        self.autoresizesSubviews = TRUE;
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    }
    return self;
}

- (void) addHideAllButtonFor:(Person*)person
{
    if ( _hideAllButton )
        return;
    
    _owner = person;
    
    // Create button and resize vew
    _hideAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _hideAllButton.frame = CGRectMake(10, -OPPORTUNITY_BREAKOUT/2, self.width-20, OPPORTUNITY_HIDEALL_HEIGHT);
    _hideAllButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_hideAllButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_hideAllButton];
    self.height = OPPORTUNITY_HIDEALL_HEIGHT;
    
    // Set up
    if ( _owner.isCurrentUser )
    {
        [_hideAllButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [_hideAllButton setTitle:@"Add opportunity" forState:UIControlStateNormal];
    }
    else
    {
        [_hideAllButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        //[_hideAllButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [_hideAllButton setTitle:@"Hide these opportunities" forState:UIControlStateNormal];
    }
}

- (void) buttonTapped
{
    if ( _owner.isCurrentUser )
    {
        NewOpportunityViewController *opController = [[NewOpportunityViewController alloc]init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:opController];
        [AppDelegate.revealController presentViewController:nav animated:YES completion:nil];
    }
    else
    {
        [globalData setPersonOpportunityHidden:_owner.strId tillDate:[NSDate date]];
        [_owner update:nil];
        [[NSNotificationCenter defaultCenter]postNotificationName:kOpportunitiesHidden object:_owner];
    }
}

- (void) addOpportunity:(FUGOpportunity*)op by:(Person*)person isRead:(BOOL)read
{
    _owner = person;
    
    NSInteger offset = 0;
    if ( _hideAllButton )
        offset = OPPORTUNITY_HIDEALL_HEIGHT;
    FUGOpportunityView* opportunity = [[FUGOpportunityView alloc] initWithFrame:CGRectMake(0, self.height-offset+OPPORTUNITY_BREAKOUT, self.width, 0)];
    [opportunity initWithOpportunity:op by:person isRead:read];
    [self addSubview:opportunity];
    self.height += opportunity.height+OPPORTUNITY_BREAKOUT;
    if ( _hideAllButton )
        _hideAllButton.originY += opportunity.height+OPPORTUNITY_BREAKOUT;
}

+ (NSUInteger) estimateOpportunitiesHeight:(NSArray*)opportunities
{
    if ( ! opportunities || opportunities.count == 0 )
        return 0;
    
    NSUInteger nHeight = 0;
    for ( FUGOpportunity* op in opportunities )
        nHeight += [FUGOpportunityView estimateOpportunityHeight:op.text] + OPPORTUNITY_BREAKOUT;
    return nHeight+OPPORTUNITY_HIDEALL_HEIGHT;
}

@end
