//
//  NewOpportunityViewController.h
//  Fuge
//
//  Created by Mikhail Larionov on 10/19/13.
//
//

#import <UIKit/UIKit.h>
#import "ULKeyboardHandler.h"

@class FUGOpportunity;

@interface NewOpportunityViewController : UIViewController <UITextViewDelegate, ULKeyboardHandlerDelegate>
{
    IBOutlet UITextField    *_textBorder;
    IBOutlet UITextView     *_opportunityText;
    IBOutlet UITextView     *_opportunityHint;
    FUGOpportunity          *_op;
    
    IBOutlet UIScrollView   *_scrollView;
    ULKeyboardHandler       *_keyboard;
}

-(void)setOpportunityToEdit:(FUGOpportunity*)op;

@end
