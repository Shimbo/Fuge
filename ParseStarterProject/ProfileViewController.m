//
//  ProfileViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/1/12.
//
//

#import <Parse/Parse.h>

#import "ProfileViewController.h"
#include "RootViewController.h"

#import "TestFlightSDK/TestFlight.h"

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)donePressed:(UIButton *)sender {
    
    NSNumber *boolDiscovery = [NSNumber numberWithBool:discoverySwitch.on];
    [[PFUser currentUser] setObject:boolDiscovery forKey:@"profileDiscoverable"];
    [[PFUser currentUser] setObject:labelRoles.text forKey:@"profileRole"];
    [[PFUser currentUser] setObject:areaEdit.text forKey:@"profileArea"];
    //[[PFUser currentUser] save];
    
    [self.navigationController setNavigationBarHidden:false animated:true];
    //[self.navigationController popViewControllerAnimated:true];
    [self.navigationController popToRootViewControllerAnimated:true];
}







///////////////////////// Dropdown list stuff


/*- (void)viewDidUnload {
    labelRoles = nil;
    [self setOutlet:nil];
    [super viewDidUnload];
}*/

- (void)viewDidLoad
{
    arrayRoles = [[NSMutableArray alloc] init];
    [arrayRoles addObject:@"CEO"];
    [arrayRoles addObject:@"CTO"];
    [arrayRoles addObject:@"Product lead"];
    [arrayRoles addObject:@"Engineer"];
    [arrayRoles addObject:@"Designer"];
    [arrayRoles addObject:@"Marketing"];
    [arrayRoles addObject:@"Finance"];
    [arrayRoles addObject:@"Consultant"];
    [arrayRoles addObject:@"Teacher"];
    [arrayRoles addObject:@"Other"];
    
    if ( [[PFUser currentUser] objectForKey:@"profileDiscoverable"] )
        [discoverySwitch setOn:[[[PFUser currentUser] objectForKey:@"profileDiscoverable"] boolValue]];
    else
        [discoverySwitch setOn:TRUE];

    if ( [[PFUser currentUser] objectForKey:@"profileRole"] )
        [labelRoles setText:[[PFUser currentUser] objectForKey:@"profileRole"]];
    else
        [labelRoles setText:@"Other"];
    
    if ( [[PFUser currentUser] objectForKey:@"profileArea"] )
        [areaEdit setText:[[PFUser currentUser] objectForKey:@"profileArea"]];
    else
        [areaEdit setText:@""];
    
    selection = 0;
    
    // Another version of drop-down menu
    /*UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"A title here"                                                        delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Dismiss"
        otherButtonTitles:@"One option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option", @"Another option",nil];
    [action  showInView:self.view];*/
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 1;
    
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return [arrayRoles count];
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return [arrayRoles objectAtIndex:row];
    
}

// this method runs whenever the user changes the selected list option

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    // update label text to show selected option
    
    labelRoles.text = [arrayRoles objectAtIndex:row];
    
    // keep track of selected option (for next time we open the picker)
    
    selection = row;
}

- (IBAction) showSearchWhereOptions {

    // create action sheet
    
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    
    // create frame for picker view
    
    CGRect pickerFrame = CGRectMake(0, 40, 0, 0);
    
    // create picker view
    
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    
    pickerView.showsSelectionIndicator = YES;
    
    pickerView.dataSource = self;
    
    pickerView.delegate = self;
    
    // set selected option to what was previously selected
    
    [pickerView selectRow:selection inComponent:0 animated:NO];
    
    // add picker view to action sheet
    
    [actionSheet addSubview:pickerView];
    
    // create close button to hide action sheet
    
    UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Close"]];
    
    closeButton.momentary = YES;
    
    closeButton.frame = CGRectMake(260, 7.0f, 50.0f, 30.0f);
    
    closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
    
    closeButton.tintColor = [UIColor blackColor];
    
    // link close button to our dismissActionSheet method
    
    [closeButton addTarget:self action:@selector(dismissActionSheet) forControlEvents:UIControlEventValueChanged];
    
    [actionSheet addSubview:closeButton];
    
    // show action sheet
    
    [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
    
    [actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
    
}

- (void) dismissActionSheet {
    
    // hide action sheet
    
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
    [super viewDidUnload];
}
@end
