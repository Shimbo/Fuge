//
//  FilterViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/2/12.
//
//

#import <UIKit/UIKit.h>

@interface FilterViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate>
{
    IBOutlet UILabel*   labelRole;
    NSMutableArray*     arrayRoles;
    UIActionSheet*      actionSheet;
    NSInteger           selection;
    
    IBOutlet UISwitch   *filter1stCircle;
    IBOutlet UISwitch   *filterEverybody;
    IBOutlet UISegmentedControl *filterDistance;
    IBOutlet UISegmentedControl *filterGender;
}

- (IBAction) roleSelectorDown:(UIButton *)sender;
- (IBAction) apply:(UIButton *)sender;


@end
