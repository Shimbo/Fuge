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
        if ( person.strStatus && person.strStatus.length > 0 )
            self.subtitle = person.strStatus;
        else
            self.subtitle = [person jobInfo];
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
    return _person.smallAvatarUrl;
}


- (BOOL)canGroup{
    return CAN_GROUP_PERSON;
}
@end
