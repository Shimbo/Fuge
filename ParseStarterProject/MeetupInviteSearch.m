//
//  MeetupInviteSearch.m
//  SecondCircle
//
//  Created by Constantine Fry on 3/8/13.
//
//

#import "MeetupInviteSearch.h"
#import "PersonInviteCell.h"
#import "Person.h"
#import "GlobalData.h"

@implementation MeetupInviteSearch

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}


-(void)searchFor:(NSString*)str{
    self.searchResult = [globalData searchForUserName:str];
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(searchFor:) withObject:searchText afterDelay:0.05];
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return self.searchResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
	static NSString *CellIdentifier = @"PersonCellIdent";
    
	PersonInviteCell *personCell = (PersonInviteCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	// Get the time zones for the region for the section
	Person *person = self.searchResult[indexPath.row];
    personCell.personName.text = person.strName;
    [personCell.personImage loadImageFromURL:person.imageURL];
    if ([self.selected objectForKey:person.strId]) {
        personCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        personCell.accessoryType = UITableViewCellAccessoryNone;
    }
	return personCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

	Person *person = self.searchResult[indexPath.row];
    
    if ([self.selected objectForKey:person.strId]) {
        [self.selected removeObjectForKey:person.strId];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        self.selected[person.strId] = person;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

@end
