//
//  MeetupInviteViewController.m
//  SecondCircle
//
//  Created by Constantine Fry on 3/8/13.
//
//

#import "MeetupInviteViewController.h"
#import "Person.h"
#import "Circle.h"
#import "GlobalVariables.h"
#import "GlobalData.h"
#import "PersonInviteCell.h"
#import "MeetupInviteSearch.h"
@interface MeetupInviteViewController ()

@end

@implementation MeetupInviteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)done{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Invite";
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(done)];
    [self.navigationItem setRightBarButtonItem:done];
    
    selected = [NSMutableDictionary dictionaryWithCapacity:10];
    UINib *nib = [UINib nibWithNibName:@"PersonInviteCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    
    
    searcher = [[MeetupInviteSearch alloc]init];
    searcher.selected = selected;
    self.searchDisplayController.searchResultsDelegate = searcher;
    self.searchDisplayController.searchResultsDataSource = searcher;
    self.searchDisplayController.searchBar.delegate = searcher;
    
    // Do any additional setup after loading the view from its nib.
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView{
    searcher.searchResult = nil;
    searcher.tableView = self.searchDisplayController.searchResultsTableView;
    UINib *nib = [UINib nibWithNibName:@"PersonInviteCell" bundle:nil];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
    NSInteger nCount = [[globalData getCircles] count];
	return nCount;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	// Number of rows is the number of time zones in the region for the specified section
	Circle *circle = [globalData getCircleByNumber:section];
	NSArray *persons = [circle getPersons];
	return [persons count];
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
    Circle *circle = [globalData getCircleByNumber:section];
	return [Circle getCircleName:circle.idCircle];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
	static NSString *CellIdentifier = @"PersonCellIdent";
    
	PersonInviteCell *personCell = (PersonInviteCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	// Get the time zones for the region for the section
	Circle* circle = [globalData getCircleByNumber:indexPath.section];
	Person *person = [circle getPersons][indexPath.row];
    personCell.personName.text = person.strName;
    [personCell.personImage loadImageFromURL:person.imageURL];
    if ([selected objectForKey:person.strId]) {
        personCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        personCell.accessoryType = UITableViewCellAccessoryNone;
    }
	return personCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    Circle* circle = [globalData getCircleByNumber:indexPath.section];
	Person *person = [circle getPersons][indexPath.row];
    
    if ([selected objectForKey:person.strId]) {
        [selected removeObjectForKey:person.strId];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        selected[person.strId] = person;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

-(NSArray*)selectedPersons{
    return selected.allValues;
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
