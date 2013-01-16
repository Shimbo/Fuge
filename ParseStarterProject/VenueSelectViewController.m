//
//  VenueSelectViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import "VenueSelectViewController.h"
#import "FSApi.h"





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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:true animated:true];
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
    [super viewDidUnload];
}

-(void)didUpdate{
    [self.activityIndicator stopAnimating];
    self.mapView.userInteractionEnabled = YES;
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
    [self.tableView reloadData];
}



- (IBAction)refresh:(UIButton*)sender {
    self.refreshButton.hidden = YES;
    self.mapView.userInteractionEnabled = NO;
    [self.activityIndicator startAnimating];
    [Foursquare2 searchVenuesNearByLatitude:@(self.mapView.centerCoordinate.latitude)
                                  longitude:@(self.mapView.centerCoordinate.longitude)
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

#pragma mark MapView Delegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (!animated) {
        self.refreshButton.hidden = NO;
    }
}

- (void)mapView:(MKMapView *)aMapView didUpdateUserLocation:(MKUserLocation *)aUserLocation {
    if (self.venues.count)
        return;
    
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.005;
    span.longitudeDelta = 0.005;
    CLLocationCoordinate2D location;
    location.latitude = aUserLocation.coordinate.latitude;
    location.longitude = aUserLocation.coordinate.longitude;
    region.span = span;
    region.center = location;
    [aMapView setRegion:region animated:YES];
   
    [self refresh:nil];
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
    return self.venues.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ident = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident];
    }
    
    cell.textLabel.text = self.venues[indexPath.row][@"name"];
    return cell;
}


#pragma mark -

@end
