

#import <Parse/Parse.h>

#import "PeopleViewController.h"
#import "PersonCell.h"
#import "Person.h"
#import "Circle.h"
#import "AsyncImageView.h"
#import "GlobalData.h"
#import "UserProfileController.h"

@implementation PeopleViewController

#define ROW_HEIGHT  60

-(void) setIdsList:(NSArray*)people
{
    idsList = people;
}

/*- (NSMutableArray*) getPersonListFromIds:(NSArray*)ids
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:30];
    
    for ( NSString* strId in ids )
    {
        Person* person = [globalData getPersonById:strId];
        if ( ! person ) // Fb person
        {
            person = [[Person alloc] initEmpty:CIRCLE_FBOTHERS];
            person.strFirstName = @"Private";
            person.strId = strId;
        }
        
        [result addObject:person];
    }
    
    return result;
}*/

- (void) updateList
{
    [self.activityIndicator stopAnimating];
    personList = [NSMutableArray arrayWithArray:[globalData getPersonsByIds:idsList]];
    [personList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Person* p1 = obj1;
        Person* p2 = obj2;
        return [p1.fullName compare:p2.fullName];
    }];
    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"PersonCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = ROW_HEIGHT;
    
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelButtonDown)]];
    
    // Adding existing persons
    [self updateList];
    
    // Creating missing list
    NSMutableArray* missingPersonIdsList = [NSMutableArray arrayWithCapacity:idsList.count];
    for ( NSString* strId in idsList )
    {
        Person* person = [globalData getPersonById:strId];
        if ( ! person )
            [missingPersonIdsList addObject:strId];
    }
    
    // Loading missing persons in background
    if ( missingPersonIdsList.count > 0 )
    {
        [self.activityIndicator startAnimating];
        [globalData loadPersonsByIdsList:missingPersonIdsList target:self selector:@selector(updateList)];
    }
}

- (void)cancelButtonDown {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark Table view datasource and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    
	return personList.count;
}

/*- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    
    return nil;
}*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
    static NSString *PersonCellIdentifier = @"PersonCellIdent";
    PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:PersonCellIdentifier];
    Person* person = personList[ indexPath.row ];
    [personCell initWithPerson:person engagement:FALSE];
    return personCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Person* person = personList[ indexPath.row ];
    UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
    [userProfileController setPerson:person];
    [userProfileController setProfileMode:PROFILE_MODE_SUMMARY];
    [self.navigationController pushViewController:userProfileController animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (void)viewDidUnload {
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}
@end
