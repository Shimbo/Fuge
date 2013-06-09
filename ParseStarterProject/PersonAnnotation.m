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
        self.title = person.strName;
        self.subtitle = [[NSString alloc] initWithFormat:
                        @"%@%@ %@",
                        person.strRole,
                        person.strArea.length?@",":@"",
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
