//
//  GeoObject.h
//  Fuge
//
//  Created by Mikhail Larionov on 8/4/13.
//
//

#import <Foundation/Foundation.h>

@interface GeoObject : NSObject {
    PFGeoPoint* location;
}

@property (nonatomic, retain) PFGeoPoint* location;

- (NSNumber*)distance;
- (NSString*)distanceString:(Boolean)precise;

@end
