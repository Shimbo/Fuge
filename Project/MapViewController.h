//
//  MapViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MainViewController.h"
#import "REVClusterMapView.h"

@class Person;
@class PersonAnnotation;
@interface MapViewController : MainViewController <MKMapViewDelegate,CLLocationManagerDelegate,UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate>
{
    IBOutlet REVClusterMapView *mapView;
    IBOutlet UITableView *tableView;
    IBOutlet UIScrollView *scrollView;
    IBOutlet UIButton *hiddenButton;
    UIRefreshControl* refreshControl;
    NSMutableArray *_personsAnnotations;
    NSMutableArray *_meetupAnnotations;
    NSMutableArray *_threadAnnotations;
    CLLocationManager *_locationManager;
    PersonAnnotation *_userLocation;
    
    NSMutableArray*      sortedMeetups;
    NSInteger            sortedMeetupsCount;

    //NSUInteger daySelector;
    UIBarButtonItem*     daySelectButton;
    UIBarButtonItem*     newMeetupButton;
    UIBarButtonItem*     closeButton;
    UIPopoverController* popover;
    UIActionSheet*       actionSheet;
    
    //NSMutableArray* dayButtonLabels;
    //NSMutableArray* selectionChoices;
}

@property (nonatomic, retain) IBOutlet REVClusterMapView *mapView;
@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void) reloadStatusChanged;
- (IBAction)mapTouched:(id)sender;

@end