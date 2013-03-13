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

@interface MapViewController : MainViewController <MKMapViewDelegate>
{
    IBOutlet MKMapView *mapView;
}

@property (nonatomic, retain) IBOutlet MKMapView *mapView;

- (void) reloadData;
- (void) reloadFinished;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

@property BOOL initialized;


@end