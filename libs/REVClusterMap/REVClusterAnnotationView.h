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

@class REVClusterPin;
@class TimerView;
@interface REVClusterAnnotationView : MKAnnotationView <MKAnnotation> {
    CustomBadge *_badge;
    UIImageView *_backgroundImageView;
    UILabel *_label;
    TimerView *_timerView;
//    UIActivityIndicatorView *_activity;
}
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

-(void)prepareForAnnotation:(REVClusterPin*)annotation;

@end
