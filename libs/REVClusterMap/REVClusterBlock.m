//
//  
//    ___  _____   ______  __ _   _________ 
//   / _ \/ __/ | / / __ \/ /| | / / __/ _ \
//  / , _/ _/ | |/ / /_/ / /_| |/ / _// , _/
// /_/|_/___/ |___/\____/____/___/___/_/|_| 
//
//  Created by Bart Claessens. bart (at) revolver . be
//

#import "REVClusterMap.h"

@implementation REVClusterBlock{
    REVClusterPin *_pin;
    double xSum;
    double ySum;
    NSInteger count;
    id<MKAnnotation> firstPin;
    CLLocation *_location;
}

-(CLLocation*)location{
    if(!_location){
        id<MKAnnotation> pin = [self getClusteredAnnotation];
        _location = [[CLLocation alloc]initWithLatitude:pin.coordinate.latitude
                                                   longitude:pin.coordinate.longitude];
    }
    return _location;
}

- (void) addAnnotation:(id<MKAnnotation>)annotation
{
    if (!firstPin) {
        firstPin = annotation;
    }
    _location = nil;
    _pin = nil;
    MKMapPoint mapPoint = MKMapPointForCoordinate( [annotation coordinate] );
    xSum += mapPoint.x;
    ySum += mapPoint.y;
    count++;
}


- (id<MKAnnotation>) getClusteredAnnotation
{
    if (count == 1) 
        return firstPin;
    
    if (!_pin) {
        double x = xSum / count;
        double y = ySum / count;
        CLLocationCoordinate2D location = MKCoordinateForMapPoint(MKMapPointMake(x, y));
        _pin = [[REVClusterPin alloc] init];
        _pin.coordinate = location;
        _pin.nodeCount = count;
    }
    return _pin;
}




@end
