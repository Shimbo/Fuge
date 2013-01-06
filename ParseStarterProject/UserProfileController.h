//
//  UserProfileController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/2/12.
//
//

#import <UIKit/UIKit.h>
#import "Person.h"

@interface UserProfileController : UIViewController <UITextViewDelegate, UIAlertViewDelegate>
{
    Person* personThis;
    IBOutlet UITextView *messageHistory;
    IBOutlet UITextView *messageNew;
    IBOutlet UIImageView *profileImage;
    UIBarButtonItem *buttonProfile;
    IBOutlet UILabel *labelDistance;
    IBOutlet UILabel *labelCircle;
    
    UIImage *image;
    NSMutableData* imageData;
    NSURLConnection *urlConnection;
    NSURL *pictureURL;
    NSMutableURLRequest *urlRequest;
    IBOutlet UIButton *addButton;
    IBOutlet UIButton *ignoreButton;
}

@property (nonatomic, strong) UIBarButtonItem *buttonProfile;

-(void) setPerson:(Person*)person;

@property (nonatomic, retain) NSMutableData *imageData;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, retain) NSURL *pictureURL;
@property (nonatomic, retain) NSMutableURLRequest *urlRequest;
- (IBAction)addButtonDown:(id)sender;
- (IBAction)ignoreButtonDown:(id)sender;
- (IBAction)meetButtonDown:(id)sender;

@end