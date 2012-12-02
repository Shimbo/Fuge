

#import "PersonCell.h"
#import "Person.h"
#import "PersonView.h"
#import "ParseStarterProjectAppDelegate.h"


@implementation PersonCell

@synthesize personView;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {

	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		
		// Create a time zone view and add it as a subview of self's contentView.
		CGRect frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
		personView = [[PersonView alloc] initWithFrame:frame];
		personView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:personView];
	}
	return self;
}


- (void)setPerson:(Person *)newPerson {
	personView.person = newPerson;
    [personView setNeedsDisplay];
}


- (void)redisplay {
	[personView setNeedsDisplay];
}


- (void)dealloc {

}


@end
