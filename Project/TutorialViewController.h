//
//  TutorialViewController.h
//  Fuge
//
//  Created by Mikhail Larionov on 10/11/13.
//
//

#import <UIKit/UIKit.h>

@interface TutorialViewController : UIViewController
{
    IBOutlet UIImageView *_iconDemo;
    IBOutlet UIActivityIndicatorView *_loadingIndicator;
    
}
- (IBAction)done:(id)sender;
- (IBAction)playDemo:(id)sender;

@end
