

#import "PersonCell.h"

@implementation PersonCell

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.contentMode = UIViewContentModeRedraw;
	}
    
	return self;
}

-(void) drawRect: (CGRect) rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect matchingCircle = CGRectMake(self.bounds.size.width - 20, self.bounds.size.height - 22, 10, 10 );
    
    if ( _shouldDrawMatches )
    {
        CGContextSetFillColorWithColor(context, [_color CGColor]);
        CGContextFillEllipseInRect(context, matchingCircle);
        CGContextSetStrokeColorWithColor(context, [[UIColor grayColor] CGColor]);
        CGContextStrokeEllipseInRect(context, matchingCircle);
    }
    else
    {
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
        CGContextFillEllipseInRect(context, matchingCircle);
        CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
        CGContextStrokeEllipseInRect(context, matchingCircle);
    }
}

@end
