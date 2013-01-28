//
//  GlobalData.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <Foundation/Foundation.h>
#import "Circle.h"
#import "RootViewController.h"

#define globalData [GlobalData sharedInstance]

@interface GlobalData : NSObject
{
    NSMutableDictionary *circles;
}

+ (id)sharedInstance;

- (Circle*) getCircle:(NSUInteger)circle;
- (NSArray*) getCircles;

- (void)clean;
- (void)reload:(RootViewController*)controller;

@end
