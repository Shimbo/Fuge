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
#import "MeetupAnnotation.h"
#import "ThreadAnnotationView.h"
#import "PersonAnnotation.h"


@implementation REVClusterBlock{
    REVClusterPin *_pin;
    double xSum;
    double ySum;
    CLLocation *_location;
    NSMutableArray *_nodes;
    int _count;
    id _firsrNode;
}

- (id)init
{
    self = [super init];
    if (self) {
        _nodes = [NSMutableArray arrayWithCapacity:4];
    }
    return self;
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
    
    
    if ([annotation isKindOfClass:[MeetupAnnotation class]]) {
        MeetupAnnotation *a = (MeetupAnnotation*)annotation;
        if (a.pinColor > _pinColor)
            _pinColor = a.pinColor;
        if (a.time > _pinTime)
            _pinTime = a.time;
    }
    [_nodes addObject:annotation];
    if (!_firsrNode) {
        _firsrNode = annotation;
    }
    _count++;
    _location = nil;
    _pin = nil;
    MKMapPoint mapPoint = MKMapPointForCoordinate( [annotation coordinate] );
    xSum += mapPoint.x;
    ySum += mapPoint.y;
}


- (id<MKAnnotation>) getClusteredAnnotation
{
    if (_count == 1)
        return _firsrNode;
    
    if (!_pin) {
        double x = xSum / _count;
        double y = ySum / _count;
        CLLocationCoordinate2D location = MKCoordinateForMapPoint(MKMapPointMake(x, y));
        _pin = [[REVClusterPin alloc] init];
        _pin.coordinate = location;
        _pin.nodes = _nodes;
        _pin.nodeCount = _count;
        _pin.pinColor = _pinColor;
        _pin.time = _pinTime;
    }
    return _pin;
}




@end
