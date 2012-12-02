

@class Person;
@class PersonView;

@interface PersonCell : UITableViewCell {
	PersonView *personView;
}

- (void)setPerson:(Person*)newPerson;
@property (nonatomic, retain) PersonView *personView;

- (void)redisplay;

@end
