

#import "Circle.h"
#import "Person.h"

@implementation Circle

@synthesize idCircle;

- (id)init:(NSUInteger)circle
{
    idCircle = circle;
	persons = [[NSMutableArray alloc] initWithCapacity:30];
    return self;
}

- (void)addPerson:(Person *)person {
	[persons addObject:person];
}

- (void)removePerson:(Person *)person{
    [persons removeObject:person];
}

- (id)addPersonWithData:(PFUser*)data {
	Person *person = [[Person alloc] init:data circle:idCircle];
	[persons addObject:person];
    return person;
}

- (void)sort
{
	[persons sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Person* person1 = obj1;
        Person* person2 = obj2;
        if ( idCircle == CIRCLE_FBOTHERS )
            return [person1.strFirstName compare:person2.strFirstName];
        if ( ! person1.distance )
            return NSOrderedDescending;
        if ( ! person2.distance )
            return NSOrderedAscending;
        if ( person1.distance.floatValue > person2.distance.floatValue )
            return NSOrderedDescending;
        else
            return NSOrderedAscending;
    }];
}

- (NSMutableArray*) getPersons
{
    return persons;
}

+ (NSString*) getPersonType:(NSUInteger)circle
{
    switch (circle)
    {
        case CIRCLE_FB: return @"Friend";
        case CIRCLE_2O: return @"Friend of a friend";
        case CIRCLE_RANDOM: return @"Random encounter";
        case CIRCLE_FBOTHERS: return @"Facebook friend";
    }
    return @"";
}

+ (NSString*) getCircleName:(NSUInteger)circle
{
    switch (circle)
    {
        case CIRCLE_FB: return @"Connections";
        case CIRCLE_2O: return @"Second circle";
        case CIRCLE_RANDOM: return @"Encounters";
        case CIRCLE_FBOTHERS: return @"Facebook friends";
    }
    return @"";
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%@ :%d persons",[Circle getCircleName:self.idCircle],persons.count];
}

@end
