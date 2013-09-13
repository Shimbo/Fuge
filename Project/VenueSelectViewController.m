//
//  VenueSelectViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "VenueSelectViewController.h"
#import "Foursquare2.h"
#import "VenueCell.h"
#import "NewMeetupViewController.h"
#import "FSVenue.h"
#import "GlobalData.h"

@implementation VenueSelectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.userTrackingMode = MKUserTrackingModeNone;
    if ( IOS_NEWER_OR_EQUAL_TO_7 )
        self.mapView.rotateEnabled = FALSE;
    
    // Do any additional setup after loading the view from its nib.
    UINib *nib = [UINib nibWithNibName:@"VenueCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"VenueCell"];
    
    [self updateLocation];
    
    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                    target:self
                                    action:@selector(close)];
    
    self.tableView.tableHeaderView = self.headerView;
    _recentVenues = [[globalData getRecentVenues] mutableCopy];
}

-(void)updateLocation{
    _locationManager =[[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];
}

-(void)close{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setMapCenter:(CLLocationDegrees)lat lon:(CLLocationDegrees)lon{
    CLLocationCoordinate2D location;
    location.latitude = lat;
    location.longitude = lon;
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.0025;
    span.longitudeDelta = 0.0025;
    region.span = span;
    region.center = location;
    [self.mapView setRegion:region animated:NO];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView setContentOffset:CGPointMake(0, 0)];
    if (_delegate.selectedVenue) {
        [self.mapView selectAnnotation:_delegate.selectedVenue animated:NO];
        [self setMapCenter:_delegate.selectedVenue.lat.doubleValue+0.00035
                       lon:_delegate.selectedVenue.lon.doubleValue];
    }
}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self setMapCenter:newLocation.coordinate.latitude
                   lon:newLocation.coordinate.longitude];
    _location = newLocation.coordinate;
    [self reloadDistanceForRecentStations];
    [self reload];
    [_locationManager stopUpdatingLocation];
    _locationManager = nil;
}
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error{
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setRefreshButton:nil];
    [self setActivityIndicator:nil];
    [self setMapView:nil];
    [self setTableView:nil];
    [self setHeaderView:nil];
    [self setLocationButton:nil];
    [super viewDidUnload];
}

-(void)removeAllAnnotationExceptOfCurrentUser
{
    NSMutableArray *annForRemove = [[NSMutableArray alloc] initWithArray:self.mapView.annotations];
    if ([self.mapView.annotations.lastObject isKindOfClass:[MKUserLocation class]]) {
        [annForRemove removeObject:self.mapView.annotations.lastObject];
    }else{
        for (id <MKAnnotation> annot_ in self.mapView.annotations)
        {
            if ([annot_ isKindOfClass:[MKUserLocation class]] ) {
                [annForRemove removeObject:annot_];
                break;
            }
        }
    }
    
    
    [self.mapView removeAnnotations:annForRemove];
}

-(void)reloadMap{
    [self removeAllAnnotationExceptOfCurrentUser];
    [self.mapView addAnnotations: self.venuesForTable];
}



-(void)reloadTable{
    [self.tableView reloadData];
}

-(void)didUpdate{
    [self.activityIndicator stopAnimating];
    self.mapView.userInteractionEnabled = YES;
    [self reloadMap];
    [self reloadTable];
}

-(void)sortByDistance:(NSMutableArray*)v{
    [v sortUsingComparator:^NSComparisonResult(FSVenue* obj1, FSVenue* obj2) {
        if (obj1.dist < obj2.dist) {
            return NSOrderedAscending;
        }else if (obj1.dist > obj2.dist) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

-(void)sortByName{
    //    [v sortUsingComparator:^NSComparisonResult(FSVenue* obj1, FSVenue* obj2) {
    //        return [obj1.name localizedCaseInsensitiveCompare:obj2.name];
    //    }];
}

-(void)reloadDistanceForRecentStations{
    CLLocation *curLoc = self.mapView.userLocation.location;
    for (FSVenue *venue in _recentVenues) {
        CLLocation *l = [[CLLocation alloc]initWithLatitude:venue.coordinate.latitude
                                                  longitude:venue.coordinate.longitude];
        venue.dist = [curLoc distanceFromLocation:l]/1000.0;
    }
    [self sortByDistance:_recentVenues];
    [self.tableView reloadData];
}

-(NSArray*)convertToObjects:(NSArray*)venues{
    NSMutableArray *v = [NSMutableArray arrayWithCapacity:venues.count];
    CLLocation *curLoc = self.mapView.userLocation.location;
    for (NSDictionary *dic in venues) {
        FSVenue *venue = [[FSVenue alloc]initWithDictionary:dic];
        NSDictionary *location = dic[@"location"];
        CLLocation *l = [[CLLocation alloc]initWithLatitude:[location[@"lat"]doubleValue]
                                                  longitude:[location[@"lng"] doubleValue]];
        venue.dist = [curLoc distanceFromLocation:l]/1000.0;
        [v addObject:venue];
    }
    [self sortByDistance:v];
    return v;
}

-(NSArray*)removeRecentVenues:(NSArray*)venues{
    return [venues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT(venueId in %@)",
                                               [_recentVenues valueForKeyPath:@"venueId"]]];
}

-(void)reload{
    self.refreshButton.hidden = YES;
    self.mapView.userInteractionEnabled = NO;
    [self.activityIndicator startAnimating];
    CGFloat offset = 20;
    CGPoint swPoint = CGPointMake(self.mapView.bounds.origin.x+offset, _mapView.bounds.origin.y+ _mapView.bounds.size.height-offset);
    CGPoint nePoint = CGPointMake((self.mapView.bounds.origin.x + _mapView.bounds.size.width-offset), (_mapView.bounds.origin.y+2.5*offset));
    
    //Then transform those point into lat,lng values
    CLLocationCoordinate2D swCoord;
    swCoord = [_mapView convertPoint:swPoint toCoordinateFromView:_mapView];
    
    CLLocationCoordinate2D neCoord;
    neCoord = [_mapView convertPoint:nePoint toCoordinateFromView:_mapView];

    if (self.venuesForTable.count == 0) {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activity.frame = CGRectMake(0, 0, 320, 40);
        self.tableView.tableFooterView = activity;
        [activity startAnimating];
    }
    [Foursquare2 searchVenuesInBoundingQuadrangleS:@(swCoord.latitude)
                                                 w:@(swCoord.longitude)
                                                 n:@(neCoord.latitude)
                                                 e:@(neCoord.longitude)
                                             query:nil
                                             limit:@(50)
                                            intent:intentBrowse
                                          callback:^(BOOL success, id result) {
                                              if (success) {
                                                  NSArray *a = [self convertToObjects:result[@"response"][@"venues"]];
                                                  a = [self removeRecentVenues:a];
                                                  self.venuesForTable = a;
                                                  
                                              }
                                              [self didUpdate];

                                          }];
}

- (IBAction)refresh:(UIButton*)sender {
    _location = self.mapView.centerCoordinate;
    [self reload];
}

#pragma mark MapView Delegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (!animated) {
        self.refreshButton.hidden = NO;
    }
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    if (annotation == mapView.userLocation){
        return nil;
    }
    static NSString *s =@"ann";
    MKAnnotationView *pin = [mapView dequeueReusableAnnotationViewWithIdentifier:s];
    if (!pin) {
        pin = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:s];
        pin.canShowCallout = YES;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [button addTarget:self
                   action:@selector(select) forControlEvents:UIControlEventTouchUpInside];
        pin.rightCalloutAccessoryView = button;
        
    }
    return pin;
}

-(void)userDidSelectVenue:(FSVenue*)venue{
    self.delegate.selectedVenue = venue;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)select{
    FSVenue *venue = self.mapView.selectedAnnotations.lastObject;
    [self userDidSelectVenue:venue];
}

#pragma mark -

#pragma mark Table Delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if ((tableView == self.searchDisplayController.searchResultsTableView
         &&
         self.venuesForSearch.count == 0)
        ||
        (tableView == self.tableView&&
         self.venuesForTable.count == 0&&
         indexPath.section == 1)){
        return 0;
    }
    return 70;
}

-(NSArray*)getVenuesForTable:(UITableView*)tableView section:(NSUInteger)section{
    if (self.searchDisplayController.searchResultsTableView == tableView) {
        if (self.venuesForSearch.count) {
            return self.venuesForSearch;
        }else{
            return @[@""];
        }
        
    }else{
        if (section == 0) {
            return _recentVenues;
        }else
            if (self.venuesForTable.count) {
                return self.venuesForTable;
            }else{
                return @[@""];
            }
        
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    }else
        return 2;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (tableView == self.tableView) {
        if (_recentVenues.count && section == 0) {
            return @"Recent Venues";
        }
        if (self.venuesForTable && section == 1) {
            return @"Nearby Venues";
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self getVenuesForTable:tableView section:section].count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ((tableView == self.searchDisplayController.searchResultsTableView
        &&
        self.venuesForSearch.count == 0)
        ||
        (tableView == self.tableView&&
         self.venuesForTable.count == 0&&
         indexPath.section == 1)) {
        static NSString *cleanCellIdent = @"cleanCell";
        UITableViewCell *ccell = [tableView dequeueReusableCellWithIdentifier:cleanCellIdent];
        if (ccell == nil) {
            ccell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cleanCellIdent];
            ccell.userInteractionEnabled = NO;
        }
        return ccell;
        
    }
    
    static NSString *ident = @"VenueCell";
    VenueCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    FSVenue *venue = [self getVenuesForTable:tableView section:indexPath.section][indexPath.row];
    cell.name.text = venue.name;
    cell.distance.text = [NSString stringWithFormat:@"%0.1fkm",venue.dist];
    cell.address.text = venue.address;
    [cell.icon loadImageFromURL:[venue iconURL]];
    return cell;
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FSVenue *venue = [self getVenuesForTable:tableView
                                     section:indexPath.section][indexPath.row];
    [self.searchDisplayController setActive:NO animated:YES];
    [self userDidSelectVenue:venue];
    self.venuesForSearch = nil;
}


-(void)searchForString:(NSString*)string{
    
    CLLocationCoordinate2D curLoc = self.mapView.centerCoordinate;
    
    NSString *searchString = [string copy];
    if (_numberOfRequest == 0 && self.venuesForSearch.count == 0) {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activity.frame = CGRectMake(0, 0, 320, 40);
        self.searchDisplayController.searchResultsTableView.tableFooterView = activity;
        [activity startAnimating];
        
    }
    
    //NSString *finalString = [string stringByReplacingOccurrencesOfString:@" " withString: @"+"];
    
    _numberOfRequest++;
    [Foursquare2 searchVenuesNearByLatitude:@(curLoc.latitude)
                                  longitude:@(curLoc.longitude)
                                 accuracyLL:nil
                                   altitude:nil
                                accuracyAlt:nil
                                      query:string
                                      limit:@(50)
                                     intent:intentCheckin
                                     radius:nil
                                   callback:^(BOOL success, id result) {
        _numberOfRequest--;
        if (_numberOfRequest == 0) {
            self.searchDisplayController.searchResultsTableView.tableFooterView = nil;
        }
        
        if (![searchString isEqualToString:self.searchDisplayController.searchBar.text]){
            return;
        }else{
            self.searchDisplayController.searchResultsTableView.tableFooterView = nil;
        }
        if (success) {
            NSArray *a = [self convertToObjects:result[@"response"][@"venues"]];
            self.venuesForSearch = a;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
        else
            NSLog(@"Foursquare error: %@", result);
    }];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(searchForString:)
               withObject:searchText
               afterDelay:0.7];
    
}
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar{
    self.venuesForSearch = nil;
}


- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView{
    UINib *nib = [UINib nibWithNibName:@"VenueCell" bundle:nil];
    [self.searchDisplayController.searchResultsTableView
     registerNib:nib forCellReuseIdentifier:@"VenueCell"];
    self.searchDisplayController.searchResultsTableView.rowHeight = 70;
}
#pragma mark -


@end
