
#include "Person.h"

typedef enum ECircle
{
    CIRCLE_NONE     = 0,
    CIRCLE_FB       = 1,
    CIRCLE_2O       = 2,
    CIRCLE_RANDOM   = 3,
    CIRCLE_FBOTHERS = 4
} CircleType;

@interface Circle : NSObject {
    CircleType      idCircle;
	NSMutableArray  *persons;
    NSMutableArray  *personsSortedByRank;
}

@property (nonatomic) CircleType idCircle;

- (id)init:(NSUInteger)circle;

- (void)addPerson:(Person *)person;
- (void)removePerson:(Person *)person;
- (id)addPersonWithData:(PFUser*)data;

- (NSMutableArray*) getPersons;
- (NSMutableArray*) getPersonsSortedByRank;

- (void)sort;

+ (NSString*) getPersonType:(NSUInteger)circle;
+ (NSString*) getCircleName:(NSUInteger)circle;

@end
