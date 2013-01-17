//
//  VenueSelectViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class NewEventViewController;
@interface VenueSelectViewController : UIViewController<MKMapViewDelegate,UITableViewDataSource,UITableViewDelegate,CLLocationManagerDelegate>{
    NSMutableArray *_annotations;
    BOOL initilized;
    CLLocationCoordinate2D _location;
    CLLocationManager* _locationManager;
}

@property (strong, nonatomic) IBOutlet UIView *headerView;

@property (strong, nonatomic) IBOutlet UIButton *refreshButton;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) IBOutlet NSArray *venues;
@property (strong, nonatomic) IBOutlet NSArray *annotations;
@property (strong, nonatomic) IBOutlet NSArray *venuesForTable;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic)  NewEventViewController *delegate;



- (IBAction)refresh:(id)sender;

@end
