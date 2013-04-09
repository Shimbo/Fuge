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
#import "CustomBadge.h"

@interface REVClusterAnnotationView : MKAnnotationView <MKAnnotation> {
    CustomBadge *_badge;
}
- (void) setClusterNum:(NSUInteger)num;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@end
