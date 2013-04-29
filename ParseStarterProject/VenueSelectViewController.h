//
//  VenueSelectViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class NewMeetupViewController;

@interface VenueSelectViewController : UIViewController<MKMapViewDelegate,UITableViewDataSource,UITableViewDelegate,CLLocationManagerDelegate>{
    BOOL initilized;
    CLLocationCoordinate2D _location;
    CLLocationManager* _locationManager;
    NSMutableArray *_recentVenues;
}

@property (strong, nonatomic) IBOutlet UIView *headerView;

@property (strong, nonatomic) IBOutlet UIButton *refreshButton;

@property (strong, nonatomic) IBOutlet UIButton *locationButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

//@property (strong, nonatomic) IBOutlet NSArray *venues;
//@property (strong, nonatomic) IBOutlet NSArray *annotations;
@property (strong, nonatomic) IBOutlet NSArray *venuesForTable;
@property (strong, nonatomic) IBOutlet NSArray *venuesForSearch;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic)  NewMeetupViewController *delegate;



- (IBAction)refresh:(id)sender;
-(IBAction)updateLocation;

@end
