//
//  UserProfileController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/2/12.
//
//

#import <UIKit/UIKit.h>
#import "Person.h"

@interface UserProfileController : UIViewController <UITextViewDelegate>
{
    Person* personThis;
    IBOutlet UITextView *messageHistory;
    IBOutlet UITextView *messageNew;
    IBOutlet UIImageView *profileImage;
    UIBarButtonItem *buttonProfile;
    
    UIImage *image;
    NSMutableData* imageData;
    NSURLConnection *urlConnection;
    NSURL *pictureURL;
    NSMutableURLRequest *urlRequest;
}

@property (nonatomic, strong) UIBarButtonItem *buttonProfile;

-(void) setPerson:(Person*)person;

@property (nonatomic, retain) NSMutableData *imageData;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, retain) NSURL *pictureURL;
@property (nonatomic, retain) NSMutableURLRequest *urlRequest;

@end