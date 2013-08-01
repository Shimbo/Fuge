//
//  ProfileViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/1/12.
//
//

#import <Parse/Parse.h>
#import "AppDelegate.h"
#import "LeftMenuController.h"
#import "ProfileViewController.h"
#include "RootViewController.h"

#import "TestFlightSDK/TestFlight.h"

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.main = NO;
        popover = nil;
        actionSheet = nil;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Do any additional setup after loading the view from its nib.
    
    self.title = NSLocalizedString(@"Profile", @"Profile");
    
    [TestFlight passCheckpoint:@"Profile"];
}

- (void)save
{
    NSNumber *boolDiscovery = [NSNumber numberWithBool:discoverySwitch.on];
    [[PFUser currentUser] setObject:boolDiscovery forKey:@"profileDiscoverable"];
    //[[PFUser currentUser] setObject:[NSNumber numberWithInt:selection] forKey:@"profileRole"];
    //[[PFUser currentUser] setObject:areaEdit.text forKey:@"profileArea"];
    [[PFUser currentUser] saveInBackground];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self save];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)donePressed:(UIButton *)sender {
    
    FugeAppDelegate *delegate = AppDelegate;
    [delegate.revealController dismissViewControllerAnimated:TRUE completion:nil];
    LeftMenuController *leftMenu = (LeftMenuController*)delegate.revealController.leftViewController;
    [leftMenu showMap];
}


///////////////////////// Dropdown list stuff



- (void)viewDidLoad
{
    [super viewDidLoad];
    if ( _main )
        buttonSave.hidden = TRUE;
    else
        self.navigationItem.leftBarButtonItem = nil;
    
    if ( [[PFUser currentUser] objectForKey:@"profileDiscoverable"] )
        [discoverySwitch setOn:[[[PFUser currentUser] objectForKey:@"profileDiscoverable"] boolValue]];
    else
        [discoverySwitch setOn:TRUE];
    
    [buttonLogout setTitle:NSLocalizedString(@"SETTINGS_LOGOUT_TEXT",nil) forState:UIControlStateNormal];
    
    /*if ( [[PFUser currentUser] objectForKey:@"profileRole"] )
        selection = [[pCurrentUser objectForKey:@"profileRole"] integerValue];
    else
        selection = [globalVariables getRoles].count-1;
    [labelRoles setText:[globalVariables roleByNumber:selection]];*/
    
    /*if ( [[PFUser currentUser] objectForKey:@"profileArea"] )
        [areaEdit setText:[[PFUser currentUser] objectForKey:@"profileArea"]];
    else
        [areaEdit setText:@""];*/
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 1;
    
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return [globalVariables getRoles].count;
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return [globalVariables roleByNumber:row];
    
}

// this method runs whenever the user changes the selected list option

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    // update label text to show selected option
    
    labelRoles.text = [[globalVariables getRoles] objectAtIndex:row];
    
    // keep track of selected option (for next time we open the picker)
    
    selection = row;
}

- (IBAction) showSearchWhereOptions {

    // Picker view
    CGRect pickerFrame = CGRectMake(0, 40, 320, 445);
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.showsSelectionIndicator = YES;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    [pickerView selectRow:selection inComponent:0 animated:NO];
    
    // Close button
    UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Close"]];
    closeButton.momentary = YES;
    closeButton.frame = CGRectMake(260, 7, 50, 30);
    closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
    closeButton.tintColor = [UIColor blackColor];
    [closeButton addTarget:self action:@selector(dismissPopup) forControlEvents:UIControlEventValueChanged];
    
    if ( IPAD )
    {
        // View and VC
        UIView *view = [[UIView alloc] init];
        [view addSubview:pickerView];
        [view addSubview:closeButton];
        UIViewController *vc = [[UIViewController alloc] init];
        [vc setView:view];
        [vc setContentSizeForViewInPopover:CGSizeMake(320, 260)];
        
        popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        [popover presentPopoverFromRect:buttonRoles.bounds inView:buttonRoles permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
        [actionSheet addSubview:pickerView];
        [actionSheet addSubview:closeButton];
        [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
        [actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
    }
}

- (IBAction)logout:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Logout" message:@"Are you sure you want to logout? " delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [PFUser logOut];
        [(LeftMenuController*)AppDelegate.revealController.leftViewController clean];
        [globalVariables setUnloaded];
        [AppDelegate userDidLogout];
    }
}


- (void) dismissPopup {
    
    if ( IPAD )
        [popover dismissPopoverAnimated:TRUE];
    else
        [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [areaEdit resignFirstResponder];
    return true;
}

- (void)viewDidUnload {
    areaEdit = nil;
    labelRoles = nil;
    discoverySwitch = nil;
    buttonRoles = nil;
    buttonLogout = nil;
    [super viewDidUnload];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [areaEdit resignFirstResponder];
}

@end
