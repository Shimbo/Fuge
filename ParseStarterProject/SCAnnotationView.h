//
//  SCAnnotationView.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/9/13.
//
//

#import <MapKit/MapKit.h>

@interface SCAnnotationView : MKAnnotationView

+(SCAnnotationView*)constructAnnotationViewForAnnotation:(id)annotation
                                                  forMap:(MKMapView*)mapView;
-(void)prepareForAnnotation:(id)ann;
@end
