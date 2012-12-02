//
//  ProfileViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/1/12.
//
//

#import <UIKit/UIKit.h>
#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@interface ProfileViewController : UIViewController <CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UITextFieldDelegate> {

    CLLocationManager*  locationManager;
    
    IBOutlet UILabel*   labelRoles;
    NSMutableArray*     arrayRoles;
    UIActionSheet*      actionSheet;
    NSInteger           selection;
    
    IBOutlet UITextField *areaEdit;
    IBOutlet UISwitch *discoverySwitch;
}

@property (nonatomic, retain) CLLocationManager* locationManager;

- (IBAction) showSearchWhereOptions;

@end
