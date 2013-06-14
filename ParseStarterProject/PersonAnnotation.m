//
//  PersonAnnotation.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import "PersonAnnotation.h"
#import "Person.h"

@implementation PersonAnnotation


- (id)initWithPerson:(Person*)person
{
    self = [super init];
    if (self) {
        self.title = [person shortName];
        NSString* strRole = person.role ? [globalVariables getRoles][[person.role integerValue]] : @"";
        self.subtitle = [[NSString alloc] initWithFormat:
                        @"%@%@%@",
                        strRole,
                        (person.strArea.length && strRole.length) ? @", ":@"",
                        person.strArea ];
        if ( person.getLocation )
            self.coordinate = CLLocationCoordinate2DMake(person.getLocation.latitude, person.getLocation.longitude);
        self.person = person;
        self.pinColor = PinBlue;
        if ( [person isOutdated] )
            self.pinColor = PinGray;
    }
    return self;
}

-(NSUInteger)numUnreadCount{
    return _person.numUnreadMessages;
}

-(NSString*)imageURL{
    return _person.imageURL;
}


- (BOOL)canGroup{
    return CAN_GROUP_PERSON;
}
@end
