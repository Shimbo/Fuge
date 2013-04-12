//
//  LocationManager.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/14/13.
//
//

#import "LocationManager.h"
#import <Parse/Parse.h>
#import "GlobalData.h"

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
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
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
    
    [globalData setUserPosition:geoPoint];
    
    //[locationManager stopUpdatingLocation];
    
    NSLog(@"Location updated");
}

- (void)locationManager: (CLLocationManager *)manager
       didFailWithError: (NSError *)error {
    
    NSString *errorString;
    [manager stopUpdatingLocation];
    NSLog(@"Error: %@",[error localizedDescription]);
    UIAlertView *alert;
    switch([error code]) {
        case kCLErrorDenied:
            //Access denied by user
            errorString = @"You denied access to location services. It will affect the functionality you will be able to use. We advise to turn it on in settings.";
            [locationManager stopUpdatingLocation];
            alert = [[UIAlertView alloc] initWithTitle:@"Important notice" message:errorString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            break;
        case kCLErrorLocationUnknown:
            //Probably temporary...
            errorString = @"Location data unavailable";
            break;
        default:
            errorString = @"An unknown error has occurred";
            break;
    }
}

-(PFGeoPoint*)getDefaultPosition
{
    return [PFGeoPoint geoPointWithLatitude:37.7750 longitude:-122.4183];
}

-(PFGeoPoint*)getPosition
{
    return geoPoint;
}

-(Boolean) getLocationStatus
{
    if([CLLocationManager locationServicesEnabled] &&
            [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied)
        return TRUE;
    return FALSE;
}

@end
