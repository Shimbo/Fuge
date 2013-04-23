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

@interface MapViewController : MainViewController <MKMapViewDelegate>
{
    IBOutlet REVClusterMapView *mapView;
    NSMutableArray *_personsAnnotations;
    NSMutableArray *_meetupAnnotations;
    NSMutableArray *_threadAnnotations;
}

@property (nonatomic, retain) IBOutlet REVClusterMapView *mapView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIButton *reloadButton;

- (IBAction)reloadTap:(id)sender;
- (void) reloadStatusChanged;

@end