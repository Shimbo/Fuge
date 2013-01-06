//
//  PersonAnnotation.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import "PersonAnnotation.h"

@implementation PersonAnnotation

@synthesize coordinate,title,subtitle,color,person;

- (void) setPerson:(Person *)p
{
    person = p;
}

@end
