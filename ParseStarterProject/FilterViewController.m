//
//  FilterViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/2/12.
//
//

#import <Parse/Parse.h>

#import "FilterViewController.h"
#import "RootViewController.h"

#import "TestFlightSDK/TestFlight.h"

@implementation FilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.title = NSLocalizedString(@"Filter", @"Filter");
    
    arrayRoles = [[NSMutableArray alloc] init];
    [arrayRoles addObject:@"Any"];
    [arrayRoles addObject:@"CEO"];
    [arrayRoles addObject:@"CTO"];
    [arrayRoles addObject:@"Product lead"];
    [arrayRoles addObject:@"Engineer"];
    [arrayRoles addObject:@"Designer"];
    [arrayRoles addObject:@"Marketing"];
    [arrayRoles addObject:@"Finance"];
    [arrayRoles addObject:@"Consultant"];
    [arrayRoles addObject:@"Teacher"];
    [arrayRoles addObject:@"Independent"];
    
    if ( [[PFUser currentUser] objectForKey:@"filter1stCircle"] )
        [filter1stCircle setOn:[[[PFUser currentUser] objectForKey:@"filter1stCircle"] boolValue]];
    else
        [filter1stCircle setOn:TRUE];
    
    if ( [[PFUser currentUser] objectForKey:@"filterEverybody"] )
        [filterEverybody setOn:[[[PFUser currentUser] objectForKey:@"filterEverybody"] boolValue]];
    else
        [filterEverybody setOn:TRUE];
    
    if ( [[PFUser currentUser] objectForKey:@"filterDistance"] )
        [filterDistance setSelectedSegmentIndex:[[[PFUser currentUser] objectForKey:@"filterDistance"] intValue]];
    else
        [filterDistance setSelectedSegmentIndex:0];
    
    if ( [[PFUser currentUser] objectForKey:@"filterGender"] )
        [filterGender setSelectedSegmentIndex:[[[PFUser currentUser] objectForKey:@"filterGender"] intValue]];
    else
        [filterGender setSelectedSegmentIndex:0];
    
    if ( [[PFUser currentUser] objectForKey:@"filterRole"] )
        [labelRole setText:[[PFUser currentUser] objectForKey:@"filterRole"]];
    else
        [labelRole setText:@"Any"];
    
    selection = 0;
    
    [super viewDidLoad];
    
    [TestFlight passCheckpoint:@"Filter"];
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
    
    labelRole.text = [arrayRoles objectAtIndex:row];
    
    // keep track of selected option (for next time we open the picker)
    
    selection = row;
}

- (IBAction)roleSelectorDown:(UIButton *)sender {
    
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

- (IBAction)apply:(UIButton *)sender {
    
    NSNumber *bool1stCircle = [NSNumber numberWithBool:filter1stCircle.on];
    NSNumber *boolEverybody = [NSNumber numberWithBool:filterEverybody.on];
    NSNumber *intDistanceSelector = [NSNumber numberWithInt:filterDistance.selectedSegmentIndex];
    NSNumber *intGenderSelector = [NSNumber numberWithInt:filterGender.selectedSegmentIndex];
    [[PFUser currentUser] setObject:bool1stCircle forKey:@"filter1stCircle"];
    [[PFUser currentUser] setObject:boolEverybody forKey:@"filterEverybody"];
    [[PFUser currentUser] setObject:intDistanceSelector forKey:@"filterDistance"];
    [[PFUser currentUser] setObject:intGenderSelector forKey:@"filterGender"];
    [[PFUser currentUser] setObject:labelRole.text forKey:@"filterRole"];
    //[[PFUser currentUser] save];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    UIViewController *rootView = viewControllers[0];
    [(RootViewController*)rootView reloadData];
    
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (void) dismissActionSheet {
    
    // hide action sheet
    
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    filter1stCircle = nil;
    filterEverybody = nil;
    filterDistance = nil;
    filterGender = nil;
    labelRole = nil;
    [super viewDidUnload];
}

@end
