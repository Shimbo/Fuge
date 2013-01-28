
#include "Person.h"

enum ECircle
{
    CIRCLE_FB       = 1,
    CIRCLE_2O       = 2,
    CIRCLE_RANDOM   = 3
};

@interface Circle : NSObject {
    NSUInteger      idCircle;
	NSMutableArray  *persons;
}

@property (nonatomic) NSUInteger idCircle;

- (id)init:(NSUInteger)circle;

- (void)addPerson:(Person *)person;
- (void)addPersonWithComponents:(NSArray *)nameComponents;

- (NSMutableArray*) getPersons;

- (void)sort;

+ (NSString*) getPersonType:(NSUInteger)circle;
+ (NSString*) getCircleName:(NSUInteger)circle;

@end
