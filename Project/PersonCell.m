

#import "PersonCell.h"
#import "Person.h"
#import "Circle.h"
#import "AsyncImageView.h"

@implementation PersonCell

-(void) initWithPerson:(Person*)person engagement:(Boolean)engagement
{
    [self.personImage loadImageFromURL:person.smallAvatarUrl];
    
#ifdef TARGET_FUGE
    self.personName.text = [person fullName];
#elif defined TARGET_S2C
    NSMutableString* strPersonName = [NSMutableString stringWithString:[person fullName]];
    if ( person.idCircle == CIRCLE_FB )
        [strPersonName appendString:@" (1st)"];
    else if ( person.idCircle == CIRCLE_2O )
        [strPersonName appendString:@" (2nd)"];
    self.personName.text = strPersonName;
#endif
    if ( person.idCircle == CIRCLE_FBOTHERS )
        self.personDistance.text = @"Invite!";
    else
    {
        NSString* distanceString = [person distanceString:FALSE];
        if ( distanceString.length > 0 )
            self.personDistance.text = distanceString;
        else
            self.personDistance.text = @"Unknown";
    }
    
    self.color = [UIColor whiteColor];
    self.personInfo.text = @"";
    self.shouldDrawMatches = FALSE;
    
#ifdef TARGET_S2C
    self.personStatus.text = person.strStatus;
    self.personRole.text = [person jobInfo];
#elif defined TARGET_FUGE
    // Matches
    if ( person.idCircle != CIRCLE_FBOTHERS )
    {
        if ( person.matchesTotal )
            self.personInfo.text = @"Match:    ";
        if ( person.idCircle != CIRCLE_FB )
        {
            NSUInteger matchesRank = person.matchesRank;
            float fColor = 1.0f - ((float)(matchesRank > MATCHING_COLOR_RANK_MAX ? MATCHING_COLOR_RANK_MAX : matchesRank))/MATCHING_COLOR_RANK_MAX / MATCHING_COLOR_BRIGHTNESS;
            self.color = [UIColor
                                colorWithRed: (MATCHING_COLOR_COMPONENT_R+(255.0f-MATCHING_COLOR_COMPONENT_R)*fColor)/255.0f
                                green:(MATCHING_COLOR_COMPONENT_G+(255.0f-MATCHING_COLOR_COMPONENT_G)*fColor)/255.0f
                                blue:(MATCHING_COLOR_COMPONENT_B+(255.0f-MATCHING_COLOR_COMPONENT_B)*fColor)/255.0f alpha:1.0f];
            if ( matchesRank > 0 )
                self.shouldDrawMatches = TRUE;
        }
        else
            self.personInfo.text = @"FB friend";
    }
    
    // Engagement details
    if ( engagement )
    {
        NSString* strMatches = [NSString stringWithFormat:@"%d/%d/%d/%d", [person getConversationCountStats:TRUE onlyMessages:FALSE], [person getConversationCountStats:FALSE onlyMessages:FALSE], [person getConversationCountStats:TRUE onlyMessages:TRUE], [person getConversationCountStats:FALSE onlyMessages:TRUE]];
        self.personInfo.text = strMatches;
    }
    if ( person.strStatus && person.strStatus.length > 0 )
    {
        self.personStatus.text = person.strStatus;
        self.personStatus.textColor = [UIColor blueColor];
    }
    else
    {
        self.personStatus.text = [person jobInfo];
        self.personStatus.textColor = [UIColor blackColor];
    }
#endif
}

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.contentMode = UIViewContentModeRedraw;
	}
    
	return self;
}

#ifdef TARGET_FUGE
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
#endif

@end
