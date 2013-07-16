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
    UIPopoverController* popover;
    UIActionSheet*       actionSheet;
    NSInteger           selection;
    
    IBOutlet UIButton *buttonRoles;
    IBOutlet UITextField *areaEdit;
    IBOutlet UISwitch *discoverySwitch;
    IBOutlet UIButton *buttonSave;
}
@property (nonatomic,assign)BOOL main;
- (IBAction) showSearchWhereOptions;

@end
