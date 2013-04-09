//
//  
//    ___  _____   ______  __ _   _________ 
//   / _ \/ __/ | / / __ \/ /| | / / __/ _ \
//  / , _/ _/ | |/ / /_/ / /_| |/ / _// , _/
// /_/|_/___/ |___/\____/____/___/___/_/|_| 
//
//  Created by Bart Claessens. bart (at) revolver . be
//

#import "REVClusterAnnotationView.h"
#import "MainStyle.h"

@implementation REVClusterAnnotationView

@synthesize coordinate;

- (id) initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if ( self )
    {
        _badge = [CustomBadge badgeWithWhiteBackgroundAndTextColor:
                  [MainStyle orangeColor]];
//        _badge.center = CGPointMake(0, 0);
        self.frame = _badge.bounds;
        [self addSubview:_badge];
    }
    return self;
}

- (void) setClusterNum:(NSUInteger)num
{
    [_badge setNumber:num];
}


@end
