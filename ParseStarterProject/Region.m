

#import "Region.h"
#import "Person.h"


static NSMutableDictionary *regions;

@implementation Region

@synthesize name;
@synthesize  persons;
@synthesize  calendar;

/*
 Class methods to manage global regions.
 */
+ (void)initialize {
	regions = [[NSMutableDictionary alloc] init];	
}


+ (Region *)regionNamed:(NSString *)name {
	return [regions objectForKey:name];
}

+ (void)clean
{
    [regions removeAllObjects];
}

+ (Region *)newRegionWithName:(NSString *)regionName {
    // Create a new region with a given name; add it to the regions dictionary.
	Region *newRegion = [[Region alloc] init];
	newRegion.name = regionName;
	NSMutableArray *array = [[NSMutableArray alloc] init];
	newRegion.persons = array;
	//[array release];
	[regions setObject:newRegion forKey:regionName];
	return newRegion;
}

- (void)addPerson:(Person *)person {
	[persons addObject:person];
}

- (void)addPersonWithComponents:(NSArray *)nameComponents {
	Person *person = [[Person alloc] init:nameComponents];
	[persons addObject:person];
}

- (void)sortZones {
    // Sort the zone wrappers by locale name.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeZoneLocaleName" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	[persons sortUsingDescriptors:sortDescriptors];
}


@end
