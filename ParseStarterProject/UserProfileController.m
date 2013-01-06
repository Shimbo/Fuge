//
//  UserProfileController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/2/12.
//
//

#import <Parse/Parse.h>

#import "UserProfileController.h"

@implementation UserProfileController
@synthesize buttonProfile;

@synthesize image;
@synthesize imageData;
@synthesize urlConnection;
@synthesize pictureURL;
@synthesize urlRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Messages", @"Messages");
    }
    return self;
}

- (void)profileClicked{
    NSString *url = [NSString stringWithFormat:@"http://facebook.com/%@", personThis.strId]; ;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)viewDidLoad
{
    // UI
    buttonProfile = [[UIBarButtonItem alloc] initWithTitle:@"Fb Profile" style:UIBarButtonItemStylePlain target:self action:@selector(profileClicked)];
    [self.navigationItem setRightBarButtonItem:buttonProfile];
        
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

NSInteger sort(id message1, id message2, void *context)
{
//    NSString* strDate1 = [message1 objectForKey:@"createdAt"];
//    NSString* strDate2 = [message2 objectForKey:@"createdAt"];
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    PFObject* mes1 = message1;
    PFObject* mes2 = message2;
    NSDate *date1 = mes1.createdAt;//[dateFormatter dateFromString:strDate1 ];
    NSDate *date2 = mes2.createdAt;//[dateFormatter dateFromString:strDate2 ];

    if ([date2 compare:date1] == NSOrderedDescending)
        return NSOrderedDescending;
    
    return NSOrderedAscending;    
}

-(void) setPerson:(Person*)person
{
    personThis = person;
    
    PFQuery *messageQuery1 = [PFQuery queryWithClassName:@"Message"];
    [messageQuery1 whereKey:@"userFrom" equalTo:[ [PFUser currentUser] objectForKey:@"fbId"] ];
    [messageQuery1 whereKey:@"userTo" equalTo:personThis.strId ];
    
    PFQuery *messageQuery2 = [PFQuery queryWithClassName:@"Message"];
    [messageQuery2 whereKey:@"userFrom" equalTo:personThis.strId ];
    [messageQuery2 whereKey:@"userTo" equalTo:[ [PFUser currentUser] objectForKey:@"fbId"] ];
    
    [messageQuery1 findObjectsInBackgroundWithBlock:^(NSArray *messages1, NSError* error) {
        [messageQuery2 findObjectsInBackgroundWithBlock:^(NSArray *messages2, NSError* error) {
        
            NSMutableString* stringHistory = [[NSMutableString alloc] initWithFormat:@""];
            
            NSMutableSet *set = [NSMutableSet setWithArray:messages1];
            [set addObjectsFromArray:messages2];
            NSArray *array = [set allObjects];
            NSArray *sortedArray = [array sortedArrayUsingFunction:sort context:NULL];
            
            for ( int n = 0; n < sortedArray.count; n++ ) //NSDictionary *message in array)
            {
                NSDictionary* message = sortedArray[n];
                NSString* strText = [message objectForKey:@"text"];
                if ( [ person.strId compare:[ message objectForKey:@"userFrom"] ] == NSOrderedSame )
                {
                    [stringHistory appendString:@"    "];
                    [stringHistory appendString:person.strName];
                    [stringHistory appendString:@": "];
                }
                else
                    [stringHistory appendString:@"    You: "];
                [stringHistory appendString:strText];
                if ( n != sortedArray.count - 1 )
                    [stringHistory appendString:@"\n"];
            }
            
            [messageHistory setText:stringHistory];
        }];
    }];
    
    // Image
    // Download the user's facebook profile picture
    imageData = [[NSMutableData alloc] init]; // the data will be loaded in here
    
    // URL should point to https://graph.facebook.com/{facebookId}/picture?type=large&return_ssl_resources=1
    pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", personThis.strId]];
    
    urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                         cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f];
    
    // Distance and circle
    NSString* strDistance = [[NSString alloc] initWithFormat:@"%@ away", person.strDistance];
    [labelDistance setText:strDistance];
    [labelCircle setText:person.strCircle];
    
    if ( [person.strCircle compare:@""] == NSOrderedSame )
        addButton.hidden = NO;
    else
        addButton.hidden = YES;
    
    // Run network request asynchronously
    urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];

}

// Called every time a chunk of the data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [imageData appendData:data]; // Build the image
}

// Called when the entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Set the image in the header imageView
    image = [UIImage imageWithData:imageData];
    [profileImage setImage:image];
    //[self setNeedsDisplay];
}







- (void)viewDidUnload {
    messageHistory = nil;
    messageNew = nil;
    profileImage = nil;
    labelDistance = nil;
    labelCircle = nil;
    addButton = nil;
    ignoreButton = nil;
    [super viewDidUnload];
}






static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 162;

double animatedDistance;

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    CGRect textFieldRect = [self.view.window convertRect:textView.bounds
                                                fromView:textView];
    CGRect viewRect = [self.view.window convertRect:self.view.bounds
                                           fromView:self.view];
    
    CGFloat midline = textFieldRect.origin.y + 0.5
    * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y
    - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION)
    * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    
    if (heightFraction < 0.0)
    {
        heightFraction = 0.0;
    }
    else if (heightFraction > 1.0)
    {
        heightFraction = 1.0;
    }
    
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT * heightFraction);
    }
    else
    {
        animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    }
    
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y -= animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
	if ( [ text isEqualToString: @"\n" ] )
    {
        [ textView resignFirstResponder ];
        return NO;
    }
    return YES;
}

- (void) textViewDidEndEditing:(UITextView *)textView
{
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y += animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
    
    if ( messageNew.text == @"" )
        return;
    
    PFObject* message = [[PFObject alloc] initWithClassName:@"Message"];
    NSString* stringFrom = (NSString *) [[PFUser currentUser] objectForKey:@"fbId"];
    [message setObject:stringFrom forKey:@"userFrom"];
    [message setObject:personThis.strId forKey:@"userTo"];
    [message setObject:messageNew.text forKey:@"text"];
    [message setObject:[NSNumber numberWithBool:FALSE] forKey:@"isRead"];
    [message save];
    
    NSString* strFrom = [[PFUser currentUser] objectForKey:@"fbName"];
    NSString* strPush =[[NSString alloc] initWithFormat:@"New message from %@!", strFrom];
    NSString* strChannel =[[NSString alloc] initWithFormat:@"fb%@", personThis.strId];
    [PFPush sendPushMessageToChannelInBackground:strChannel withMessage:strPush];
    
    NSMutableString* stringHistory = [[NSMutableString alloc] initWithFormat:@""];
    [stringHistory appendString:@"    You: "];
    [stringHistory appendString:messageNew.text];
    [stringHistory appendString:@"\n"];
    [stringHistory appendString:messageHistory.text];
    [messageHistory setText:stringHistory];
    
    NSRange range;
    range.location = range.length = 0;
    [messageHistory scrollRangeToVisible:range];
    
    [messageNew setText:@""];
}


- (IBAction)addButtonDown:(id)sender {
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"WIP" message:@"'Add to second sircle' method will be implemented later, thanks." delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
    [errorAlert show];
}

- (IBAction)ignoreButtonDown:(id)sender {
    UIAlertView* confirmationView = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure you want to block this user? You won't receive any notifications." delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""),nil];
    
	[confirmationView show];
}

- (IBAction)meetButtonDown:(id)sender {
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"WIP" message:@"'Private invites are under construction and to be added really soon! Thanks." delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 0 )
        return;
    
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"WIP" message:@"Ignore lists and all connected functionality will be added later, thanks." delegate:nil cancelButtonTitle:@"Sure man!" otherButtonTitles:nil];
    [errorAlert show];
}

@end
