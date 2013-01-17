//
//  VenueSelectViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "VenueSelectViewController.h"
#import "FSApi.h"
#import "VenueCell.h"
#import "NewEventViewController.h"
#import "FSVenue.h"



@interface VenueAnnotation : NSObject<MKAnnotation>{
    CLLocationCoordinate2D _coordinate;
}
@property (nonatomic, copy) NSString *title;
@end

@implementation VenueAnnotation

-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate{
    _coordinate = newCoordinate;
}

-(CLLocationCoordinate2D)coordinate{
    return _coordinate;
}

@end









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

    _locationManager =[[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];
    

    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                     style:UIBarButtonItemStyleBordered
                                    target:self
                                    action:@selector(close)];
    
    self.tableView.tableHeaderView = self.headerView;
}

-(void)close{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.005;
    span.longitudeDelta = 0.005;
    CLLocationCoordinate2D location;
    location.latitude = newLocation.coordinate.latitude;
    location.longitude = newLocation.coordinate.longitude;
    region.span = span;
    region.center = location;
    [self.mapView setRegion:region animated:YES];
    _location = newLocation.coordinate;
    [self reload];
    [_locationManager stopUpdatingLocation];
    _locationManager = nil;
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
    [super viewDidUnload];
}

-(void)reloadMap{
    [self.mapView removeAnnotations:_annotations];
    _annotations = [NSMutableArray arrayWithCapacity:self.venues.count];
    for (NSDictionary *ven in self.venues) {
        VenueAnnotation *ann = [[VenueAnnotation alloc]init];
        ann.title = ven[@"name"];
        [ann setCoordinate:CLLocationCoordinate2DMake([ven[@"location"][@"lat"] doubleValue],
                                                      [ven[@"location"][@"lng"] doubleValue])];
        [_annotations addObject:ann];
    }
    [self.mapView addAnnotations: _annotations];
}

-(void)reloadTable{
    CLLocation *curLoc = self.mapView.userLocation.location;
    NSMutableArray *v = [NSMutableArray arrayWithCapacity:self.venues.count];
    for (NSDictionary *ven in self.venues) {
        CLLocation *l = [[CLLocation alloc]initWithLatitude:[ven[@"location"][@"lat"]doubleValue]
                                                  longitude:[ven[@"location"][@"lng"] doubleValue]];
        int dist = (int)[curLoc distanceFromLocation:l];
        [v addObject:@{@"dist":@(dist),@"venue":ven}];
    }
    [v sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
        return [obj1[@"dist"] compare:obj2[@"dist"]];
    }];
    self.venuesForTable = v;
    
    [self.tableView reloadData];
}

-(void)didUpdate{
    [self.activityIndicator stopAnimating];
    self.mapView.userInteractionEnabled = YES;
    [self reloadMap];
    [self reloadTable];
}

-(void)reload{
    self.refreshButton.hidden = YES;
    self.mapView.userInteractionEnabled = NO;
    [self.activityIndicator startAnimating];
    [Foursquare2 searchVenuesNearByLatitude:@(_location.latitude)
                                  longitude:@(_location.longitude)
                                 accuracyLL:nil
                                   altitude:nil
                                accuracyAlt:nil
                                      query:nil
                                      limit:nil
                                     intent:nil
                                     radius:@(500)
                                   callback:^(BOOL success, id result) {
                                       self.venues = result[@"response"][@"venues"];
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
    MKAnnotationView *ann = [mapView dequeueReusableAnnotationViewWithIdentifier:s];
    if (!ann) {
        ann = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:s];
        ann.canShowCallout = YES;
    }
    return ann;
}

#pragma mark -

#pragma mark Table Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.venuesForTable.count;
}

-(NSString*)getIconURLFromVenue:(NSDictionary*)venue{
    if ([venue[@"categories"] count]) {
        NSDictionary *iconDic = venue[@"categories"][0][@"icon"];
        NSString* url = [NSString stringWithFormat:@"%@bg_88%@",iconDic[@"prefix"],iconDic[@"suffix"]];
        return url;
    }else{
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ident = @"VenueCell";
    VenueCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    NSDictionary *venue = self.venuesForTable[indexPath.row][@"venue"];
    cell.name.text = venue[@"name"];
    cell.distance.text = [NSString stringWithFormat:@"%@m",
                          self.venuesForTable[indexPath.row][@"dist"]];
    [cell.icon loadImageFromURL:[self getIconURLFromVenue:self.venues[indexPath.row]]];
    return cell;
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dic = self.venuesForTable[indexPath.row][@"venue"];
    FSVenue *venue = [[FSVenue alloc]init];
    venue.name = dic[@"name"];
    venue.venueId = dic[@"id"];
    
    venue.lon = dic[@"location"][@"lng"];
    venue.lat = dic[@"location"][@"lat"];
    
    venue.city = dic[@"location"][@"city"];
    venue.state = dic[@"location"][@"state"];
    venue.country = dic[@"location"][@"country"];
    venue.cc = dic[@"location"][@"cc"];
    venue.postalCode = dic[@"location"][@"postalCode"];
    
    self.delegate.selectedVenue = venue;
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -

@end
