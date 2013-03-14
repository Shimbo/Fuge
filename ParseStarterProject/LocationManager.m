//
//  LocationManager.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/14/13.
//
//

#import "LocationManager.h"
#import <Parse/Parse.h>

@implementation LocationManager

@synthesize locationManager;

static LocationManager *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (LocationManager *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// Initialization
- (id)init
{
    self = [super init];
    
    if (self) {
        geoPoint = nil;
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        locationManager.distanceFilter = 100.0f;
    }
    
    return self;
}

-(void)startUpdating
{
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    if (newLocation.horizontalAccuracy < 0) return;
    
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0)
    {
    }
    
    CLLocationCoordinate2D coord = newLocation.coordinate;
    
    geoPoint = [PFGeoPoint geoPointWithLatitude:coord.latitude
                                                  longitude:coord.longitude];
    [[PFUser currentUser] setObject:geoPoint forKey:@"location"];
    
    //[locationManager stopUpdatingLocation];
    
    NSLog(@"Location updated");
}

-(PFGeoPoint*)getPosition
{
    return geoPoint;
}

@end
