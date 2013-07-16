//
//  TableAnnotationsViewViewController.m
//  SecondCircle
//
//  Created by Constantine Fry on 4/27/13.
//
//

#import "TableAnnotationsViewController.h"
#import "AnnotationCell.h"
#import <MapKit/MapKit.h>
#import "MeetupAnnotation.h"
#import "PersonAnnotation.h"
#import "ThreadAnnotationView.h"
#import "UserProfileController.h"
#import "MeetupViewController.h"

@interface TableAnnotationsViewController ()

@end

@implementation TableAnnotationsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)close{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setAnnotations:(NSMutableArray *)annotations{
    _annotations = annotations;
    [self.annotations sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {

        if ([obj1 isKindOfClass:[PersonAnnotation class]]) {
            if ([obj2 isKindOfClass:[PersonAnnotation class]] ) {
                return NSOrderedSame;
            }else{
                return NSOrderedAscending;
            }
        }
        
        if ([obj2 isKindOfClass:[PersonAnnotation class]] ) {
            return NSOrderedDescending;
        }
        
        if (((MeetupAnnotation*)obj1).pinColor != PinGray) {
            if (((MeetupAnnotation*)obj2).pinColor != PinGray) {
                return NSOrderedSame;
            }else{
                return NSOrderedAscending;
            }
        }
        
        if (((MeetupAnnotation*)obj2).pinColor != PinGray) {
            return NSOrderedDescending;
        }
        
        return NSOrderedSame;
    }];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.rowHeight = 70;
    UINib *nib1 = [UINib nibWithNibName:@"AnnotationCellPerson" bundle:nil];
    [self.tableView registerNib:nib1 forCellReuseIdentifier:@"PersonCell"];
    
    UINib *nib2 = [UINib nibWithNibName:@"AnnotationCellMeetup" bundle:nil];
    [self.tableView registerNib:nib2 forCellReuseIdentifier:@"MeetupCell"];
    
    UINib *nib3 = [UINib nibWithNibName:@"AnnotationCellThread" bundle:nil];
    [self.tableView registerNib:nib3 forCellReuseIdentifier:@"ThreadCell"];

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem = item;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //{NSOrderedAscending = -1L, NSOrderedSame, NSOrderedDescending};


}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([_selectedAnnotation isKindOfClass:[MeetupAnnotation class]]) {
        MeetupAnnotation *meetupAnnotation = (MeetupAnnotation *)_selectedAnnotation;
        [meetupAnnotation configureAnnotation];
         int index = [self.annotations indexOfObject:meetupAnnotation];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
        _selectedAnnotation = nil;
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.annotations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdP = @"PersonCell";
    static NSString *cellIdM = @"MeetupCell";
    static NSString *cellIdT = @"ThreadCell";
    id<MKAnnotation> obj = self.annotations[indexPath.row];
    NSString *strId = nil;
    if ([obj isKindOfClass:[PersonAnnotation class]]) {
        strId = cellIdP;
    }else if ([obj isKindOfClass:[ThreadAnnotation class]]){
        strId = cellIdT;
    }else{
        strId = cellIdM;
    }
    UITableViewCell<AnnotationCell> *cell = (UITableViewCell<AnnotationCell>*)[tableView dequeueReusableCellWithIdentifier:strId forIndexPath:indexPath];
    [cell prepareForAnnotation:self.annotations[indexPath.row]];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    _selectedAnnotation = self.annotations[indexPath.row];
    if ( [_selectedAnnotation isMemberOfClass:[PersonAnnotation class]])
    {
        if (((PersonAnnotation*) _selectedAnnotation).person.isCurrentUser == NO) {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [userProfileController setPerson:((PersonAnnotation*) _selectedAnnotation).person];
            [self.navigationController pushViewController:userProfileController animated:YES];
        }
        else{
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }

    }else{
        MeetupViewController *meetupController = [[MeetupViewController alloc] initWithNibName:@"MeetupView" bundle:nil];
        [meetupController setMeetup:((MeetupAnnotation*) _selectedAnnotation).meetup];
        [self.navigationController pushViewController:meetupController animated:YES];
    }
}

@end
