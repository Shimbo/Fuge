//
//  LocationManager.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/14/13.
//
//

#import <Foundation/Foundation.h>
#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>

#define locManager [LocationManager sharedInstance]

@class PFGeoPoint;

@interface LocationManager : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager*  locationManager;
    PFGeoPoint          *geoPoint;
    PFGeoPoint          *geoPointOld;
}

+ (id)sharedInstance;

@property (nonatomic, retain) CLLocationManager* locationManager;

-(void)startUpdating;
-(PFGeoPoint*)getPosition;
-(PFGeoPoint*)getDefaultPosition;
-(Boolean) getLocationStatus;

@end
