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

@interface REVClusterBlock : NSObject{
    PinColor _pinColor;
    CGFloat _pinTime;
}


- (void) addAnnotation:(id<MKAnnotation>)annotation;
- (id<MKAnnotation>) getClusteredAnnotation;
-(CLLocation*)location;

@end
