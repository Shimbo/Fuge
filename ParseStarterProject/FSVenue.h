//
//  FSVenue.h
//  SecondCircle
//
//  Created by Constantine Fry on 1/17/13.
//
//

#import <Foundation/Foundation.h>

@interface FSVenue : NSObject

@property(nonatomic,strong)NSString *name;
@property(nonatomic,strong)NSNumber *venueId;

@property(nonatomic,strong)NSNumber *lat;
@property(nonatomic,strong)NSNumber *lon;


@property(nonatomic,strong)NSString *city;
@property(nonatomic,strong)NSString *state;
@property(nonatomic,strong)NSString *country;
@property(nonatomic,strong)NSString *cc;
@property(nonatomic,strong)NSString *postalCode;

@end
