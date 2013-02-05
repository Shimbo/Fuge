//
//  FSVenue.m
//  SecondCircle
//
//  Created by Constantine Fry on 1/17/13.
//
//

#import "FSVenue.h"

@implementation FSVenue
-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate{
    _coordinate = newCoordinate;
}

-(CLLocationCoordinate2D)coordinate{
    return _coordinate;
}

-(NSString*)title{
    return self.name;
}


-(NSString*)iconURL{
    if ([self.fsVenue[@"categories"] count]) {
        NSDictionary *iconDic = self.fsVenue[@"categories"][0][@"icon"];
        NSString* url = [NSString stringWithFormat:@"%@bg_88%@",iconDic[@"prefix"],iconDic[@"suffix"]];
        return url;
    }else{
        return nil;
    }
}
@end
