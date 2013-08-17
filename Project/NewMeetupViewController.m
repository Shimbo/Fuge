//
//  NewEventViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import "NewMeetupViewController.h"
#import "VenueSelectViewController.h"
#import <Parse/Parse.h>
#import "FSVenue.h"
#import "GlobalData.h"
#import "MeetupInviteViewController.h"
#import "LocationManager.h"

@implementation NewMeetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        meetup = nil;
        invitee = nil;
        datePicker = nil;
        durationPicker = nil;
        bLocationChanged = bDateChanged = bDurationChanged = false;
        self.navigationItem.leftItemsSupplementBackButton = true;
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void) setMeetup:(Meetup*)m
{
    meetup = m;
    meetupType = m.meetupType;
}

-(void) setInvitee:(Person*)i
{
    invitee = i;
}

-(void) setType:(NSUInteger)t
{
    meetupType = t;
}

-(void) updateFieldsVisibility
{
    if ( ! privacySwitch.isOn )
    {
        priceText.hidden = TRUE;
        priceField.hidden = TRUE;
        imageURLField.hidden = TRUE;
        originalURLField.hidden = TRUE;
        descriptionText.hidden = TRUE;
        iconButton.hidden = TRUE;
        
        CGSize size = scrollView.contentSize;
        size.height = durationBtn.frame.origin.y + durationBtn.frame.size.height + 10;
        scrollView.contentSize = size;
    }
    else
    {
        priceText.hidden = FALSE;
        priceField.hidden = FALSE;
        imageURLField.hidden = FALSE;
        originalURLField.hidden = FALSE;
        descriptionText.hidden = FALSE;
        iconButton.hidden = FALSE;
        
        CGSize size = scrollView.contentSize;
        size.height = descriptionText.frame.origin.y + descriptionText.frame.size.height + 10;
        scrollView.contentSize = size;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Title
    if ( meetupType == TYPE_MEETUP )
    {
        if (meetup)
            self.title = @"Event";
        else
            self.title = @"New event";
    }
    else
        self.title = @"Thread";
    
    // Navigation
    [self.navigationController setNavigationBarHidden:false animated:false];
    [self.navigationItem setHidesBackButton:false animated:false];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonDown)]];
    
    UIBarButtonItem *button = nil;
    if (meetup) {
        button = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    }else{
        button = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(next)];
        
    }
    [self.navigationItem setRightBarButtonItem:button];
    
    if ( meetup )
    {
        [subject setText:meetup.strSubject];
        [privacySwitch setOn:(! meetup.privacy)];
        [location setTitle:meetup.strVenue forState:UIControlStateNormal];
        meetupDate = meetup.dateTime;
        meetupDurationDays = meetup.durationSeconds / (24*3600);
        meetupDurationHours = (meetup.durationSeconds % (24*3600))/3600;
        [self updateDurationText];
        [self dateChanged:nil];
        [priceField setText:meetup.strPrice];
        [imageURLField setText:meetup.strImageURL];
        [originalURLField setText:meetup.strOriginalURL];
        [descriptionText setText:meetup.strDescription];
        meetupIcon = meetup.iconNumber;
        [iconButton setTitle:meetupIcons[meetupIcon] forState:UIControlStateNormal];
    }
    else
    {
        if ( invitee )  // Private meetup created from user profile, turn off publicity
            [privacySwitch setOn:FALSE];
        if ( bIsAdmin ) // Always public for admins by default
            [privacySwitch setOn:TRUE];
        
        // Default time
        NSDateComponents* deltaCompsDefault = [[NSDateComponents alloc] init];
        if (meetupType == TYPE_MEETUP)
            [deltaCompsDefault setMinute:30];
        else
            [deltaCompsDefault setDay:7];
        NSDate* dateDefault = [[NSCalendar currentCalendar] dateByAddingComponents:deltaCompsDefault toDate:[NSDate date] options:0];
        meetupDate = dateDefault;
        meetupDurationDays = 0;
        meetupDurationHours = 1;
        meetupIcon = 0;
        
        // Set focus on text view
        [subject becomeFirstResponder];
    }
    
    if ( meetupType == TYPE_THREAD )
        dateBtn.hidden = TRUE;
    
    [self updateFieldsVisibility];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:self.view.window];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ( textField != subject )
        return YES;
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > TEXT_MAX_MEETUP_SUBJECT_LENGTH) ? NO : YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if ( datePicker )
    {
        CGPoint p = [gestureRecognizer locationInView:datePicker];
        if (p.y > 0) {
            return NO;
        }
    }
    if ( durationPicker )
    {
        CGPoint p = [gestureRecognizer locationInView:durationPicker];
        if (p.y > 0) {
            return NO;
        }
    }
    if ( ! durationPicker && ! datePicker )
        return NO;
    return YES;
}

- (void)tap:(UITapGestureRecognizer *)sender
{
    // Updating data, removing pickers
    location.userInteractionEnabled = NO;
    self.view.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if ( datePicker )
            datePicker.originY = self.view.height;
        if ( durationPicker )
            durationPicker.originY = self.view.height;
    } completion:^(BOOL finished) {
        location.userInteractionEnabled = YES;
        self.view.userInteractionEnabled = YES;
        if ( datePicker && datePicker.originY == self.view.height )
        {
            [datePicker removeFromSuperview];
            datePicker = nil;
        }
        if ( durationPicker && durationPicker.originY == self.view.height )
        {
            [durationPicker removeFromSuperview];
            durationPicker = nil;
        }
    }];
}

- (void)dateChanged:(UIDatePicker *)picker
{
    if ( picker )
    {
        NSDate* oldDate = meetupDate;
        meetupDate = picker.date;
        if ( [oldDate compare:meetupDate] != NSOrderedSame )
            bDateChanged = true;
    }
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDoesRelativeDateFormatting:TRUE];
    [dateBtn setTitle:[formatter stringFromDate:meetupDate] forState:UIControlStateNormal];
}

- (IBAction)selectDateBtn:(id)sender
{
    if (!datePicker) {
        datePicker = [UIDatePicker new];
        
        datePicker.originY = self.view.height;
        datePicker.originX = self.view.width/2 - datePicker.width/2;
        datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        datePicker.minuteInterval = 15;
        
        NSDateComponents* deltaCompsMin = [[NSDateComponents alloc] init];
        [deltaCompsMin setMinute:15];
        NSDate* dateMin = [[NSCalendar currentCalendar] dateByAddingComponents:deltaCompsMin toDate:[NSDate date] options:0];
        NSDateComponents* deltaCompsMax = [[NSDateComponents alloc] init];
        
        if ( [globalVariables isUserAdmin] )
            [deltaCompsMax setDay:60];
        else
            [deltaCompsMax setDay:7];
        NSDate* dateMax = [[NSCalendar currentCalendar] dateByAddingComponents:deltaCompsMax toDate:[NSDate date] options:0];
        
        [datePicker setMinimumDate:dateMin];
        [datePicker setMaximumDate:dateMax];
        [datePicker setDate:meetupDate];
        
        [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:datePicker];
        
        [self.view endEditing:YES];
        location.userInteractionEnabled = NO;
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            datePicker.originY = self.view.height - datePicker.height;
        } completion:^(BOOL finished) {
            location.userInteractionEnabled = YES;
            self.view.userInteractionEnabled = YES;
        }];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ( component == 0 )
        return 7;
    else
        return 24;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    switch ( component )
    {
        case 0: if (row == 0) return @"0 days"; else if (row == 1) return @"1 day"; else return [NSString stringWithFormat:@"%d days", row];
        case 1: if (row == 0) return @"0 hours"; else if (row == 1) return @"1 hour"; else return [NSString stringWithFormat:@"%d hours", row];
    }
    return nil;
}

- (void)updateDurationText
{
    NSString* strDuration;
    if ( meetupDurationDays == 0 )
        strDuration = [NSString stringWithFormat:@"%@",
                       [self pickerView:durationPicker titleForRow:meetupDurationHours forComponent:1]];
    else if ( meetupDurationHours == 0 )
        strDuration = [NSString stringWithFormat:@"%@",
                       [self pickerView:durationPicker titleForRow:meetupDurationDays forComponent:0]];
    
    else
        strDuration = [NSString stringWithFormat:@"%@ and %@",
                       [self pickerView:durationPicker titleForRow:meetupDurationDays forComponent:0],
                       [self pickerView:durationPicker titleForRow:meetupDurationHours forComponent:1]];
    
    [durationBtn setTitle:strDuration forState:UIControlStateNormal];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSUInteger nOldDays = meetupDurationDays;
    NSUInteger nOldHours = meetupDurationHours;
    
    // Preventing 0 days and 0 hours situation
    if ( [durationPicker selectedRowInComponent:0] == 0 &&
        [durationPicker selectedRowInComponent:1] == 0 )
    {
        [durationPicker selectRow:0 inComponent:0 animated:TRUE];
        [durationPicker selectRow:1 inComponent:1 animated:TRUE];
    }
    
    meetupDurationDays = [durationPicker selectedRowInComponent:0];
    meetupDurationHours = [durationPicker selectedRowInComponent:1];
    if ( nOldDays != meetupDurationDays || nOldHours != meetupDurationHours )
        bDurationChanged = true;
    [self updateDurationText];
}

- (IBAction)durationButton:(id)sender {
    if (!durationPicker) {
        durationPicker = [UIPickerView new];
        [self.view addSubview:durationPicker];
        durationPicker.originY = self.view.height;
        durationPicker.originX = self.view.width/2 - durationPicker.width/2;
        durationPicker.showsSelectionIndicator = TRUE;
        durationPicker.delegate = self;
        durationPicker.dataSource = self;
        
        [durationPicker selectRow:meetupDurationDays inComponent:0 animated:FALSE];
        [durationPicker selectRow:meetupDurationHours inComponent:1 animated:FALSE];
        
        [self.view endEditing:YES];
        location.userInteractionEnabled = NO;
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            durationPicker.originY = self.view.height - durationPicker.height;
        } completion:^(BOOL finished) {
            location.userInteractionEnabled = YES;
            self.view.userInteractionEnabled = YES;
        }];
    }
}

- (IBAction)venueButton:(id)sender {
//    [self removePopups];
    if (!venueNavViewController) {
        VenueSelectViewController *venueViewController = [[VenueSelectViewController alloc] initWithNibName:@"VenueSelectView" bundle:nil];
        venueViewController.delegate = self;
        venueNavViewController = [[UINavigationController alloc]initWithRootViewController:venueViewController];
    }
    [self presentViewController:venueNavViewController
                       animated:YES completion:nil];
}


/*-(void)hideKeyBoard{
    [subject resignFirstResponder];
}*/

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.selectedVenue) {
        NSString* oldLocation = [location titleForState:UIControlStateNormal];
        [location setTitle:self.selectedVenue.name forState:UIControlStateNormal];
        if ( [oldLocation compare:self.selectedVenue.name] != NSOrderedSame )
            bLocationChanged = true;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)cancelButtonDown {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)validateForm{
    if ( subject.text.length == 0 )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:NSLocalizedString(@"NEW_MEETUP_NOSUBJECT",nil) delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return NO;
    }
    
    if ( ! self.selectedVenue && ! meetup && ! [locManager getPosition] )
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Not yet!" message:NSLocalizedString(@"NEW_MEETUP_NOVENUE",nil) delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
        [errorAlert show];
        return NO;
    }
    return YES;
}

-(void)populateMeetupWithData{
    meetup.meetupType = meetupType;
    meetup.strOwnerId = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    meetup.strOwnerName = [globalVariables fullUserName];
    meetup.strSubject = subject.text;
    meetup.privacy = privacySwitch.isOn ? MEETUP_PUBLIC : MEETUP_PRIVATE;
    meetup.dateTime = meetupDate;
    meetup.durationSeconds = meetupDurationDays*24*3600 + meetupDurationHours*3600;
    meetup.iconNumber = meetupIcon;
    if ( priceField.text.length > 0 )
        meetup.strPrice = priceField.text;
    if ( imageURLField.text.length > 0 )
        meetup.strImageURL = imageURLField.text;
    if ( originalURLField.text.length > 0 )
        meetup.strOriginalURL = originalURLField.text;
    if ( descriptionText.text.length > 0 )
        meetup.strDescription = descriptionText.text;
    
    if ( self.selectedVenue )
    {
        [meetup populateWithVenue:self.selectedVenue];
        [globalData addRecentVenue:self.selectedVenue];
    }
    else if ( ! meetup.location ) // to preserve previously selected coords/venue
        [meetup populateWithCoords];
}

- (void) callbackMeetupSaved:(Meetup*)m
{
    if ( ! m )
        return;
    
    // Creating comment
    if ( bLocationChanged || bDateChanged || bDurationChanged )
    {
        NSMutableString* strChanged = [NSMutableString stringWithString:@" changed "];
        Boolean bShouldAddComma = false;
        if ( bLocationChanged )
        {
            [strChanged appendString:@"location"];
            bShouldAddComma = true;
        }
        if ( bDateChanged )
        {
            if ( bShouldAddComma )
                [strChanged appendString:@", "];
            [strChanged appendString:@"date-time"];
            bShouldAddComma = true;
        }
        if ( bDurationChanged )
        {
            if ( bShouldAddComma )
                [strChanged appendString:@" and "];
            [strChanged appendString:@"duration"];
            bShouldAddComma = true;
        }
        [strChanged appendString:@" of the event."];
        [globalData createCommentForMeetup:meetup commentType:COMMENT_SAVED commentText:strChanged target:nil selector:nil];
    }
}

-(void)save{
    if (![self validateForm])
        return;
    
    // Saving meetup on server
    [self populateMeetupWithData];
    
    [meetup save:self selector:@selector(callbackMeetupSaved:)];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)nextInternal
{
    // Saving meetup on server
    meetup = [[Meetup alloc] init];
    [self populateMeetupWithData];
    Boolean bResult = [meetup save:nil selector:nil];
    
    // Loading ended
    [activityIndicator stopAnimating];
    
    if ( ! bResult )
        return;
    
    // Adding to the list on client and creating comment
    [globalData addMeetup:meetup];
    [globalData createCommentForMeetup:meetup commentType:COMMENT_CREATED commentText:nil target:nil selector:nil];
    
    // Add to attending list and update meetup attending list (only on client)
    [globalData attendMeetup:meetup addComment:FALSE target:nil selector:nil];
    
    // Invites
    MeetupInviteViewController *inviteController = [[MeetupInviteViewController alloc]init];
    if ( invitee ) // Add invitee if this window was ivoked from user profile
        [inviteController addInvitee:invitee];
    [inviteController setMeetup:meetup newMeetup:true];
    [self.navigationController pushViewController:inviteController animated:YES];
}

- (void)next {
    if (![self validateForm])
        return;
    
    [activityIndicator startAnimating];
    
    [self performSelector:@selector(nextInternal) withObject:nil afterDelay:0.01f];
}

- (IBAction)privacyChanged:(id)sender {
    if ( [pCurrentUser.createdAt compare:[NSDate dateWithTimeIntervalSinceNow:-24*3600*7]] == NSOrderedDescending )
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Too early" message:NSLocalizedString(@"NEW_MEETUP_BLOCKEDPUBLIC",nil) delegate:self cancelButtonTitle:@"Alright" otherButtonTitles:nil, nil];
        [alert show];
        [privacySwitch setOn:FALSE animated:TRUE];
        privacySwitch.enabled = FALSE;
    }
    [self updateFieldsVisibility];
}

- (IBAction)iconChanged:(id)sender {
    meetupIcon++;
    if ( meetupIcon >= meetupIcons.count )
        meetupIcon= 0;
    [iconButton setTitle:meetupIcons[meetupIcon] forState:UIControlStateNormal];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [subject resignFirstResponder];
    [priceField resignFirstResponder];
    [imageURLField resignFirstResponder];
    [originalURLField resignFirstResponder];
    [descriptionText resignFirstResponder];
    return true;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [subject resignFirstResponder];
    [priceField resignFirstResponder];
    [imageURLField resignFirstResponder];
    [originalURLField resignFirstResponder];
    [descriptionText resignFirstResponder];
}

- (void)viewDidUnload {
    durationBtn = nil;
    scrollView = nil;
    priceField = nil;
    imageURLField = nil;
    originalURLField = nil;
    descriptionText = nil;
    priceText = nil;
    iconButton = nil;
    privacySwitch = nil;
    [super viewDidUnload];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    CGPoint origin = activeField.frame.origin;
    origin.y += activeField.frame.size.height;
    origin.y -= scrollView.contentOffset.y;
    if (!CGRectContainsPoint(aRect, origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y+activeField.frame.size.height-(aRect.size.height));
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    activeField = nil;
}

@end
