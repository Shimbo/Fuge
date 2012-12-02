#include "Person.h"

@interface Region : NSObject {
	NSString *name;
	NSMutableArray *persons;
	NSCalendar *calendar;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *persons;
@property (nonatomic, retain) NSCalendar *calendar;

+ (Region *)regionNamed:(NSString *)name;
+ (Region *)newRegionWithName:(NSString *)regionName;
+ (void)clean;
- (void)addPerson:(Person *)person;
- (void)addPersonWithComponents:(NSArray *)nameComponents;
- (void)sortZones;

@end
