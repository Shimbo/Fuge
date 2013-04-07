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

@synthesize coordinate,title,subtitle;

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
        self.coordinate = person.getLocation;
        self.person = person;
    }
    return self;
}

-(NSUInteger)numUnreadCount{
    return _person.numUnreadMessages;
}

-(NSString*)imageURL{
    return _person.imageURL;
}

@end
