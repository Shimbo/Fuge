

#import "Circle.h"
#import "Person.h"


static NSMutableDictionary *circles;

@implementation Circle

@synthesize name;
@synthesize  persons;

/*
 Class methods to manage global regions.
 */
+ (void)initialize {
	circles = [[NSMutableDictionary alloc] init];
}


+ (Circle *)circleNamed:(NSString *)name {
	return [circles objectForKey:name];
}

+ (void)clean
{
    [circles removeAllObjects];
}

+ (Circle *)newCircleWithName:(NSString *)circleName {
    // Create a new region with a given name; add it to the regions dictionary.
	Circle *newCircle = [[Circle alloc] init];
	newCircle.name = circleName;
	NSMutableArray *array = [[NSMutableArray alloc] init];
	newCircle.persons = array;
	//[array release];
	[circles setObject:newCircle forKey:circleName];
	return newCircle;
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
