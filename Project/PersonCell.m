

#import "PersonCell.h"
#import "Person.h"
#import "Circle.h"
#import "AsyncImageView.h"
#import "FUGOpportunitiesView.h"

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
    
    self.personInfo.text = @"";
    
#ifdef TARGET_S2C
    // Opportunities
    if ( _opportunitiesView )
        [_opportunitiesView removeFromSuperview];
    if ( person.visibleOpportunities )
    {
        _opportunitiesView = [[FUGOpportunitiesView alloc] initWithFrame:CGRectMake(0, 60, self.width, 0)];
        [_opportunitiesView addHideAllButtonFor:person];
        for ( FUGOpportunity* op in person.visibleOpportunities )
            [_opportunitiesView addOpportunity:op by:person isRead:NO];
        [self addSubview:_opportunitiesView];
    }
    
    //self.personStatus.text = person.strStatus;
    self.personRole.text = person.strPosition;//[person jobInfo];
    self.personCompany.text = person.strEmployer;
    
#elif defined TARGET_FUGE
    // Matches
    if ( person.idCircle != CIRCLE_FBOTHERS )
    {
        if ( _matchingCircle )
        {
            [_matchingCircle removeFromSuperview];
            _matchingCircle = nil;
            self.personInfo.originX += 15;
        }
        if ( person.idCircle != CIRCLE_FB )
        {
            NSUInteger matchesRank = person.matchesRank;
            if ( matchesRank > 0 )
            {
                _matchingCircle = [[FUGMatchView alloc] initWithFrame:CGRectMake(self.width - 20, self.height - 22, 10, 10 )];
                _matchingCircle.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
                float fColor = 1.0f - ((float)(matchesRank > MATCHING_COLOR_RANK_MAX ? MATCHING_COLOR_RANK_MAX : matchesRank))/MATCHING_COLOR_RANK_MAX / MATCHING_COLOR_BRIGHTNESS;
                _matchingCircle.color = [UIColor
                                          colorWithRed: (MATCHING_COLOR_COMPONENT_R+(255.0f-MATCHING_COLOR_COMPONENT_R)*fColor)/255.0f
                                          green:(MATCHING_COLOR_COMPONENT_G+(255.0f-MATCHING_COLOR_COMPONENT_G)*fColor)/255.0f
                                          blue:(MATCHING_COLOR_COMPONENT_B+(255.0f-MATCHING_COLOR_COMPONENT_B)*fColor)/255.0f alpha:1.0f];
                _matchingCircle.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
                [self addSubview:_matchingCircle];
                self.personInfo.originX -= 15;
                self.personInfo.text = @"Match:";
            }
            else
                self.personInfo.text = @"";
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

@end

#ifdef TARGET_FUGE

@implementation FUGMatchView

-(void) drawRect: (CGRect) rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    
    CGRect matchingCircle = CGRectMake(1, 1, 8, 8);
    
    CGContextSetFillColorWithColor(context, _color.CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    
    //CGContextFillEllipseInRect(context, matchingCircle);
    //CGContextStrokeEllipseInRect(context, matchingCircle);
    //    CGContextAddEllipseInRect(context, matchingCircle);
    //    CGContextStrokePath(context);
    //    CGContextFillEllipseInRect(context, matchingCircle);
    //    UIGraphicsEndImageContext();
    
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, matchingCircle);
    CGContextDrawPath(context, kCGPathFillStroke); // Or kCGPathFill
    
    UIGraphicsEndImageContext();
}

@end

#endif
