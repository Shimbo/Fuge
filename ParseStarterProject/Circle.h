#include "Person.h"

@interface Circle : NSObject {
	NSString *name;
	NSMutableArray *persons;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *persons;

+ (Circle *)circleNamed:(NSString *)name;
+ (Circle *)newCircleWithName:(NSString *)circleName;
+ (void)clean;
- (void)addPerson:(Person *)person;
- (void)addPersonWithComponents:(NSArray *)nameComponents;
- (void)sortZones;

@end
