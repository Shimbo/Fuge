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
    
}
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIButton *retryButton;
@property (strong, nonatomic) IBOutlet UIButton *updateButton;
@property (strong, nonatomic) IBOutlet UILabel *titleText;
@property (strong, nonatomic) IBOutlet UITextView *descriptionText;
@property (strong, nonatomic) IBOutlet UILabel *miscText;

- (IBAction)loginDown:(id)sender;
- (IBAction)retryDown:(id)sender;
- (IBAction)updateDown:(id)sender;

@end
