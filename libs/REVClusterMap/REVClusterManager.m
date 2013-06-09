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
#import "GlobalVariables.h"



@implementation REVClusterManager{
    NSMutableDictionary *_cache;
    NSArray *_pins;
    __weak MKMapView *_map;
    NSMutableDictionary *dist;
}

- (id)init
{
    self = [super init];
    if (self) {
        _cache = [NSMutableDictionary dictionaryWithCapacity:20];
        dist = [NSMutableDictionary dictionaryWithCapacity:20];
        CGFloat a = DISTANCE_FOR_GROUPING_PINS;
        for (int i = 1; i<=19; i++) {
            if (i == 19)
                dist[@(i)] = @(1.0);
            else
                dist[@(i)] = @(a);
            a/=2;

        }
//        NSLog(@"%@",dist);
    }
    return self;
}

-(NSArray*)clusterAnnotationsForZoomLevel:(NSInteger)zoomLevel{
    NSArray *pins = _cache[@(zoomLevel)];
    if (!pins){
        pins = [self clusterAnnotationsForMapView:_map
                                   forAnnotations:_pins
                                        zoomLevel:zoomLevel];
    }
    return pins;
}

-(CGFloat)distanceBetwen:(CGPoint)p1 and:(CGPoint)p2{
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    return distance;
}

-(REVClusterBlock*)findNearbyBlockToPoint:(CLLocation*)point
                                  inArray:(NSArray*)array
                              distanceMax:(NSInteger)distanceMax{
    REVClusterBlock *result = nil;
    CGFloat min = CGFLOAT_MAX;
    for (REVClusterBlock *block in array) {
        double distance = [point distanceFromLocation:block.location];
        if (distance < distanceMax &&
            min > distance) {
            min = distance;
            result = block;
        }
    }
    return result;
}


- (NSArray *) clusterAnnotationsForMapView:(MKMapView *)mapView
                            forAnnotations:(NSArray *)pins
                                 zoomLevel:(NSInteger)zoomLevel
{

    _map = mapView;
    _pins = pins;

    NSMutableArray* clusteredBlocks = [NSMutableArray arrayWithCapacity:40];
    NSMutableArray* notClusteredPins = [NSMutableArray arrayWithCapacity:10];
    CGFloat max = [dist[@(zoomLevel)] floatValue];
    for (REVClusterPin *pin in pins)
    {
        if (![pin canGroup]) {
            [notClusteredPins addObject:pin];
            continue;
        }
        CLLocation *l1 = [[CLLocation alloc]initWithLatitude:pin.coordinate.latitude
                                                   longitude:pin.coordinate.longitude];
        
        REVClusterBlock *block = [self findNearbyBlockToPoint:l1
                                                      inArray:clusteredBlocks
                                                  distanceMax:max];
        if (block) {
            [block addAnnotation:pin];
        }else{
            REVClusterBlock *block = [[REVClusterBlock alloc] init];
            [block addAnnotation:pin];
            [clusteredBlocks addObject:block];
        }
    }
    
    //create New Pins
    NSMutableArray *newPins = [NSMutableArray arrayWithCapacity:clusteredBlocks.count+
                               notClusteredPins.count];
    for ( REVClusterBlock *block in clusteredBlocks )
        [newPins addObject:[block getClusteredAnnotation]];
    
    [newPins addObjectsFromArray:notClusteredPins];
        
    _cache[@(zoomLevel)] = newPins;
    return newPins;
}
@end
