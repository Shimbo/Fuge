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

- (void) reloadData;
- (void) reloadFinished;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

@property BOOL initialized;


@end