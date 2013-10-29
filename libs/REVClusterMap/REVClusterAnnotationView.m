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
#import "REVClusterPin.h"
#import "TimerView.h"



@implementation REVClusterAnnotationView

@synthesize coordinate;

- (id) initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if ( self )
    {
        self.frame = CGRectMake(0, 0, 50, 60);
        _backgroundImageView = [[UIImageView alloc]initWithFrame:self.bounds];
        [self addSubview:_backgroundImageView];
        
        _label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 50, 48)];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont fontWithName:@"Helvetica" size:18];
        _label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_label];
        
        _timerView = [[TimerView alloc]init];
        [self addSubview:_timerView];
    }
    return self;
}

- (void) setClusterNum:(NSUInteger)num
{
    _label.hidden = NO;
    [_label setText:[NSString stringWithFormat:@"%d",num]];
}

-(void)updateTimerForColor:(PinColor)color{
    switch (color) {
        case PinBlue:
            _timerView.timerColor = [UIColor FUGlightBlueColor];
            break;
        case PinOrange:
            _timerView.timerColor = [UIColor FUGyellowColor];
            break;
        case PinGray:
            _timerView.timerColor = [UIColor clearColor];
            break;
        default:
            _timerView.timerColor = nil;
            break;
    }
}

-(void)setColor:(PinColor)color{
    switch (color) {
        case PinBlue:
            _backgroundImageView.image = [UIImage imageNamed:@"meetPinBlue.png"];
            break;
        case PinGray:
            _backgroundImageView.image = [UIImage imageNamed:@"meetPinGray.png"];
            break;
        case PinOrange:
            _backgroundImageView.image = [UIImage imageNamed:@"meetPinOrange.png"];
            break;
            
        default:
            break;
    }
}

-(void)setTime:(CGFloat)time{
    _timerView.time = time;
    if (_timerView.time == 0) {
        _timerView.time = 0.00001;
    }
    if (_timerView.time == 1) {
        _timerView.time = 0.99999;
    }
    [_timerView setNeedsDisplay];
}

-(void)prepareForAnnotation:(REVClusterPin*)annotation{
    [self setClusterNum:annotation.nodeCount];
    [self setColor:annotation.pinColor];
    [self updateTimerForColor:annotation.pinColor];
    [self setTime:annotation.time];
}


@end
