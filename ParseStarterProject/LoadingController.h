//
//  LoadingController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 4/11/13.
//
//

#import <UIKit/UIKit.h>

@interface LoadingController : UIViewController
{
    Boolean bVersionChecked;
    NSUInteger  nAnimationStage;
    Boolean     bAnimation;
}
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIButton *retryButton;
@property (strong, nonatomic) IBOutlet UIButton *updateButton;
@property (strong, nonatomic) IBOutlet UILabel *titleText;
@property (strong, nonatomic) IBOutlet UITextView *descriptionText;
@property (strong, nonatomic) IBOutlet UILabel *miscText;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;

- (IBAction)loginDown:(id)sender;
- (IBAction)retryDown:(id)sender;
- (IBAction)updateDown:(id)sender;

@end
