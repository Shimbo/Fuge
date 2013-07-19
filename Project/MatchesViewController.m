

#import <Parse/Parse.h>

#import "MatchesViewController.h"
#import "UserProfileController.h"
#import "PersonCell.h"
#import "LikeCell.h"
#import "Person.h"
#import "Circle.h"
#import "GlobalVariables.h"
#import "GlobalData.h"

#import "AppDelegate.h"
#import "AsyncImageView.h"

#import "TestFlightSDK/TestFlight.h"

@implementation MatchesViewController

#define ROW_HEIGHT  60

#pragma mark -
#pragma mark View loading

- (NSMutableArray*) getPersonListFromIds:(NSArray*)ids
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
}

NSInteger compareDistance(id id1, id id2, void *context)
{
    Person* person1 = id1;
    Person* person2 = id2;
    if ( ! person1.distance )
        return NSOrderedDescending;
    if ( ! person2.distance )
        return NSOrderedAscending;
    if ( person1.distance.floatValue > person2.distance.floatValue )
        return NSOrderedDescending;
    else
        return NSOrderedAscending;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"PersonCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    nib = [UINib nibWithNibName:@"LikeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"LikeCellIdent"];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = ROW_HEIGHT;
    
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelButtonDown)]];
    
    NSArray* tempMatchedFriends = personThis.matchedFriendsToFriends;
    NSArray* tempMatchedFriends2O = personThis.matchedFriendsTo2O;
    NSArray* tempMatched2OFriends = personThis.matched2OToFriends;
    matchedFriends = [self getPersonListFromIds:tempMatchedFriends];
    matchedFriends2O = [self getPersonListFromIds:tempMatchedFriends2O];
    matched2OFriends = [self getPersonListFromIds:tempMatched2OFriends];
    matchedLikes = personThis.matchedLikes;
    
    // Sorting
	[matchedFriends sortUsingFunction:compareDistance context:nil];
    [matched2OFriends sortUsingFunction:compareDistance context:nil];
}

- (void)cancelButtonDown {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) setPerson:(Person*)person
{
    personThis = person;
}

#pragma mark -
#pragma mark Table view datasource and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    
    if ( bIsAdmin )
        return 4;
    else
        return 3;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	
    switch (section)
    {
        case 0: return matchedFriends.count; break;
        case 1: return matchedLikes.count; break;
        case 2: return matchedFriends2O.count; break;
        case 3: return matched2OFriends.count; break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    switch (section)
    {
        case 0: return @"Mutual friends"; break;
        case 1: return @"Mututal likes"; break;
        case 2: return @"Friends who know friends of"; break;
        case 3: return @"For test: 2O in friends"; break;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
    if ( indexPath.section != 1 )
    {
        static NSString *PersonCellIdentifier = @"PersonCellIdent";
        PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:PersonCellIdentifier];
        Person* person = nil;
        switch (indexPath.section)
        {
            case 0: person = matchedFriends[indexPath.row]; break;
            case 2: person = matchedFriends2O[indexPath.row]; break;
            case 3: person = matched2OFriends[indexPath.row]; break;
        }
        
        [personCell.personImage loadImageFromURL:person.imageURL];
        personCell.personName.text = [person fullName];
        if ( person.idCircle == CIRCLE_FBOTHERS )
        {
            if ( indexPath.section != 3 )
                personCell.personDistance.text = @"Invite!";
            else
                personCell.personDistance.text = @"";
        }
        else
            personCell.personDistance.text = [person distanceString];
        personCell.personInfo.text = @"";
        if ( person.strStatus && person.strStatus.length > 0 )
        {
            personCell.personStatus.text = person.strStatus;
            personCell.personStatus.textColor = [UIColor blueColor];
        }
        else
        {
            personCell.personStatus.text = [person jobInfo];
            personCell.personStatus.textColor = [UIColor blackColor];
        }
        return personCell;
    }
    else
    {
        static NSString *LikeCellIdentifier = @"LikeCellIdent";
        LikeCell *likeCell = (LikeCell *)[tableView dequeueReusableCellWithIdentifier:LikeCellIdentifier];
        NSDictionary* like = [personThis getLikeById:matchedLikes[indexPath.row]];
        if ( like )
        {
            likeCell.likeName.text = [like objectForKey:@"name"];
            likeCell.likeCategory.text = [NSString stringWithFormat:@"Category: %@", [like objectForKey:@"cat"]];
            NSString* strImage = [Person imageURLWithId:[like objectForKey:@"id"]];
            [likeCell.likeImage loadImageFromURL:strImage];
        }
        return likeCell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ( indexPath.section != 1 )
    {
        Person* person = nil;
        switch (indexPath.section)
        {
            case 0: person = matchedFriends[indexPath.row]; break;
            case 2: person = matchedFriends2O[indexPath.row]; break;
            case 3: person = matched2OFriends[indexPath.row]; break;
        }
        
        if ( person.idCircle == CIRCLE_FBOTHERS )
        {
            if ( indexPath.section != 3 )
                [Person showInviteDialog:person.strId];
            else if ( bIsAdmin )
                [Person openProfileInBrowser:person.strId];
        }
        else
        {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [userProfileController setPerson:person];
            [self.navigationController pushViewController:userProfileController animated:YES];
        }
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
