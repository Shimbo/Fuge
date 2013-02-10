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
    // Do any additional setup after loading the view from its nib.
    UINib *nib = [UINib nibWithNibName:@"VenueCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"VenueCell"];
    
    [self updateLocation];
    
    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                     style:UIBarButtonItemStyleBordered
                                    target:self
                                    action:@selector(close)];
    
    self.tableView.tableHeaderView = self.headerView;
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

//-(void)sortByDistance{
//    [v sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
//        return [obj1[@"dist"] compare:obj2[@"dist"]];
//    }];
//}


-(NSArray*)convertToObjects:(NSArray*)venues{
    NSMutableArray *v = [NSMutableArray arrayWithCapacity:venues.count];
    CLLocation *curLoc = self.mapView.userLocation.location;
    for (NSDictionary *dic in venues) {
        FSVenue *venue = [[FSVenue alloc]init];
        NSDictionary *location = dic[@"location"];
        CLLocation *l = [[CLLocation alloc]initWithLatitude:[location[@"lat"]doubleValue]
                                                  longitude:[location[@"lng"] doubleValue]];
        [venue setCoordinate:CLLocationCoordinate2DMake([location[@"lat"] doubleValue],
                                                      [location[@"lng"] doubleValue])];
        venue.dist = [curLoc distanceFromLocation:l]/1000.0;
//        NSLog(@"%f- %d",venue.dist,[location[@"distance"] intValue]);
        venue.name = dic[@"name"];
        venue.venueId = dic[@"id"];
        

        venue.lon = location[@"lng"];
        venue.lat = location[@"lat"];
        
        venue.city = location[@"city"];
        venue.state = location[@"state"];
        venue.country = location[@"country"];
        venue.cc = location[@"cc"];
        venue.postalCode = location[@"postalCode"];
        venue.address = location[@"address"];
        venue.fsVenue = dic;
        
        [v addObject:venue];
        
    }
    [v sortUsingComparator:^NSComparisonResult(FSVenue* obj1, FSVenue* obj2) {
        return [obj1.name localizedCaseInsensitiveCompare:obj2.name];
    }];
    return v;
}

-(void)reload{
    self.refreshButton.hidden = YES;
    self.mapView.userInteractionEnabled = NO;
    [self.activityIndicator startAnimating];
//    [Foursquare2 searchVenuesNearByLatitude:@(_location.latitude)
//                                  longitude:@(_location.longitude)
//                                 accuracyLL:nil
//                                   altitude:nil
//                                accuracyAlt:nil
//                                      query:nil
//                                      limit:nil
//                                     intent:intentBrowse
//                                     radius:@(500)
//                                   callback:^(BOOL success, id result) {
//                                       NSArray *a = [self convertToObjects:result[@"response"][@"venues"]];
//                                       self.venuesForTable = a;
//                                       [self didUpdate];
//                                   }];
    CGFloat offset = 20;
    CGPoint swPoint = CGPointMake(self.mapView.bounds.origin.x+offset, _mapView.bounds.origin.y+ _mapView.bounds.size.height-offset);
    CGPoint nePoint = CGPointMake((self.mapView.bounds.origin.x + _mapView.bounds.size.width-offset), (_mapView.bounds.origin.y+2.5*offset));
    
    //Then transform those point into lat,lng values
    CLLocationCoordinate2D swCoord;
    swCoord = [_mapView convertPoint:swPoint toCoordinateFromView:_mapView];
    
    CLLocationCoordinate2D neCoord;
    neCoord = [_mapView convertPoint:nePoint toCoordinateFromView:_mapView];

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

-(NSArray*)getVenuesForTable:(UITableView*)tableView{
    if (self.searchDisplayController.searchResultsTableView == tableView) {
        return self.venuesForSearch;
    }else{
        return self.venuesForTable;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self getVenuesForTable:tableView].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ident = @"VenueCell";
    VenueCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    FSVenue *venue = [self getVenuesForTable:tableView][indexPath.row];
    cell.name.text = venue.name;
    cell.distance.text = [NSString stringWithFormat:@"%0.1fkm",venue.dist];
    cell.address.text = venue.address;
    [cell.icon loadImageFromURL:[venue iconURL]];
    return cell;
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FSVenue *venue = [self getVenuesForTable:tableView][indexPath.row];
    [self.searchDisplayController setActive:NO animated:YES];
    [self userDidSelectVenue:venue];
    self.venuesForSearch = nil;
}

-(void)searchForString:(NSString*)string{
    CLLocation *curLoc = self.mapView.userLocation.location;
    [Foursquare2 searchVenuesNearByLatitude:@(curLoc.coordinate.latitude)
                                  longitude:@(curLoc.coordinate.longitude)
                                 accuracyLL:nil
                                   altitude:nil
                                accuracyAlt:nil
                                      query:string
                                      limit:@(50)
                                     intent:intentCheckin
                                     radius:nil
                                   callback:^(BOOL success, id result) {
                                       if (success) {
                                           NSArray *a = [self convertToObjects:result[@"response"][@"venues"]];
                                           self.venuesForSearch = a;
                                           [self.searchDisplayController.searchResultsTableView reloadData];
                                       }

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
