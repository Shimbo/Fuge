//
//  FUGOpportunitiesView.h
//  Fuge
//
//  Created by Mikhail Larionov on 10/19/13.
//
//

#import <UIKit/UIKit.h>

@class Person;
@class FUGOpportunity;

@interface FUGOpportunityView : UIView
{
    FUGOpportunity* _op;
    Person*         _owner;
    UIImageView*    _icon;
    UITextView*     _opportunityText;
    UIButton*       _replyButton;
    BOOL            _isRead;
}

- (void) initWithOpportunity:(FUGOpportunity*)op by:(Person*)person isRead:(BOOL)read;

+ (NSUInteger) estimateOpportunityHeight:(NSString*)opportunity;

@end

@interface FUGOpportunitiesView : UIView
{
    Person*             _owner;
    NSMutableArray*     _opportunities;
    UIButton*           _hideAllButton;
}

- (void) addHideAllButtonFor:(Person*)person;
- (void) addOpportunity:(FUGOpportunity*)op by:(Person*)person isRead:(BOOL)read;

+ (NSUInteger) estimateOpportunitiesHeight:(NSArray*)opportunities;

@end
