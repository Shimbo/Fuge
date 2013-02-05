//
//  ProfileViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/1/12.
//
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"

@interface ProfileViewController : MainViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UITextFieldDelegate> {
    
    IBOutlet UILabel*   labelRoles;
    NSMutableArray*     arrayRoles;
    UIActionSheet*      actionSheet;
    NSInteger           selection;
    
    IBOutlet UIButton *buttonRoles;
    IBOutlet UITextField *areaEdit;
    IBOutlet UISwitch *discoverySwitch;
}
@property (nonatomic,assign)BOOL main;
- (IBAction) showSearchWhereOptions;

@end
