//
//  
//    ___  _____   ______  __ _   _________ 
//   / _ \/ __/ | / / __ \/ /| | / / __/ _ \
//  / , _/ _/ | |/ / /_/ / /_| |/ / _// , _/
// /_/|_/___/ |___/\____/____/___/___/_/|_| 
//
//  Created by Bart Claessens. bart (at) revolver . be
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface REVClusterMapView : MKMapView <MKMapViewDelegate> {
    NSMutableArray *annotationsCopy;
    NSUInteger zoomLevel;
}
/** Specifies the receiver‚Äôs delegate object. */
@property(nonatomic,assign) id<MKMapViewDelegate> delegate;

-(void)cleanUpAnnotations;
@end
