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
static NSUInteger fireLocationEnabledNotification = 0;

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
        geoPoint = geoPointOld = nil;
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
    
    if ( ! currentUserIsAuthenticated ) return;
    
    /*NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0)
    {
    }*/
    
    // New location
    CLLocationCoordinate2D coord = newLocation.coordinate;
    geoPoint = [PFGeoPoint geoPointWithLatitude:coord.latitude longitude:coord.longitude];
    
    // Store in PFUser and get the result
    Boolean bResult = [globalData setUserPosition:geoPoint];
    
    // Distance calculation
    float fDistance;
    if ( geoPointOld )
        fDistance = [geoPoint distanceInKilometersTo:geoPointOld];
    else
        fDistance = 10000000.0f;
    
    // If location was saved and distance is more than it should, save data
    if ( fDistance > LOCATION_UPDATE_KILOMETERS && bResult )
    {
        geoPointOld = geoPoint;
        [pCurrentUser saveInBackground];
        NSLog(@"Location updated");
    }
    
    if ( fireLocationEnabledNotification == 1 )
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:kLocationEnabled object:nil];
        fireLocationEnabledNotification = 2;
    }
    
    // Let's try not to stop
    //[locationManager stopUpdatingLocation];
}

- (void)locationManager: (CLLocationManager *)manager
       didFailWithError: (NSError *)error {
    
    NSString *errorString;
    [manager stopUpdatingLocation];
    NSLog(@"Location manager did fail with error: %@",[error localizedDescription]);
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
    if([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
        return TRUE;
    return FALSE;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized && fireLocationEnabledNotification == 0 )
        fireLocationEnabledNotification = 1;
}

@end
