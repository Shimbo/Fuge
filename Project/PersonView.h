
@class Person;

@interface PersonView : UIView {
	Person *person;
	NSDateFormatter *dateFormatter;
	NSString *lookingFor;
	BOOL highlighted;
	BOOL editing;
}

@property (nonatomic, retain) Person *person;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) NSString *lookingFor;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isEditing) BOOL editing;

@end
