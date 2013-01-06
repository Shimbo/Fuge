//
//  GlobalData.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <Foundation/Foundation.h>

#define globalData [GlobalData sharedInstance]

@interface GlobalData : NSObject
{
    NSMutableArray *listPersons;
    //NSMutableArray *listCircles;
}

@property (nonatomic, strong) NSArray *listPersons;
//@property (nonatomic, strong) NSArray *listCircles;

+ (id)sharedInstance;

//- (NSMutableArray*) getPersons;
//- (NSMutableArray*) getCircles;

@end
