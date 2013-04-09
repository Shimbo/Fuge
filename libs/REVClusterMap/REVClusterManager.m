//
//  
//    ___  _____   ______  __ _   _________ 
//   / _ \/ __/ | / / __ \/ /| | / / __/ _ \
//  / , _/ _/ | |/ / /_/ / /_| |/ / _// , _/
// /_/|_/___/ |___/\____/____/___/___/_/|_| 
//
//  Created by Bart Claessens. bart (at) revolver . be
//

#import "REVClusterManager.h"


#define BASE_RADIUS .5 // = 1 mile
#define MINIMUM_LATITUDE_DELTA 0.20
#define BLOCKS 4

#define MINIMUM_CLUSTER_LEVEL 100000

@implementation REVClusterManager



+ (NSArray *) clusterAnnotationsForMapView:(MKMapView *)mapView
                            forAnnotations:(NSArray *)pins
                                 zoomLevel:(NSUInteger)zoomLevel
{

    NSArray *visibleAnnotations = pins;
    

    if( zoomLevel == 19 )
    {
        return visibleAnnotations;
    }
    

    NSMutableArray* clusteredBlocks = [NSMutableArray arrayWithCapacity:40];
    for (REVClusterPin *pin in visibleAnnotations)
    {
        CGPoint p1 = [mapView convertCoordinate:pin.coordinate
                                         toPointToView:mapView];
        BOOL added = NO;
        for (REVClusterBlock *block in clusteredBlocks) {
            id<MKAnnotation>  an = [block getAnnotationForIndex:0];
            CGPoint p2 = [mapView convertCoordinate:an.coordinate
                                      toPointToView:mapView];
            CGFloat xDist = (p2.x - p1.x);
            CGFloat yDist = (p2.y - p1.y);
            CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
            if (distance < 25) {
                added = YES;
                [block addAnnotation:pin];
                break;
            }
        }
        if (!added) {
            REVClusterBlock *block = [[REVClusterBlock alloc] init];
            [block addAnnotation:pin];
            [clusteredBlocks addObject:block];
        }

    }
    
    //create New Pins
    NSMutableArray *newPins = [NSMutableArray arrayWithCapacity:clusteredBlocks.count];
    for ( REVClusterBlock *block in clusteredBlocks )
        [newPins addObject:[block getClusteredAnnotation]];
        

    return newPins;
}
@end
