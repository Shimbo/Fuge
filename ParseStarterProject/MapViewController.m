//
//  MapViewController.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import "MapViewController.h"
#import "PersonAnnotation.h"
#import "MeetupAnnotation.h"
#import "GlobalData.h"
#import "Person.h"
#import "Circle.h"
#import "MeetupViewController.h"
#import "FilterViewController.h"
#import "UserProfileController.h"
#import "TestFlightSDK/TestFlight.h"
#import <Parse/Parse.h>
#import "GlobalVariables.h"
#import "AsyncImageView.h"
#import "ImageLoader.h"
#import "NewMeetupViewController.h"
#import "MeetupInviteViewController.h"
#import "SCAnnotationView.h"
#import "REVClusterAnnotationView.h"
#import "PersonAnnotationView.h"
#import "LocationManager.h"
#import <QuartzCore/QuartzCore.h>
#import "TableAnnotationsViewController.h"

@implementation MapViewController

@synthesize mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadStatusChanged)
                                                name:kLoadingMapComplete
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadStatusChanged)
                                                name:kLoadingCirclesComplete
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadStatusChanged)
                                                name:kLoadingMapFailed
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadStatusChanged)
                                                name:kLoadingCirclesFailed
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadStatusChanged)
                                                name:kAppRestored
                                                object:nil];
    }
    return self;
}

- (NSUInteger)loadPersonAnnotations:(CircleType)circleNumber limit:(NSInteger)l
{
    Circle* circle = [globalData getCircle:circleNumber];
    if ( ! circle )
        return 0;
    
    int n = 0;
    for (Person* person in [circle getPersons] )
    {
        PersonAnnotation *ann = [[PersonAnnotation alloc] initWithPerson:person];
        [_personsAnnotations addObject:ann];
        n++;
        if ( n >= l )
            break;
    }
    return n;
}

- (NSUInteger)loadMeetupAndThreadAnnotations:(NSInteger)l
{
    int n = 0;
    for (Meetup *meetup in [globalData getMeetups])
    {
        if (meetup.meetupType == TYPE_MEETUP) {
            MeetupAnnotation *ann = [[MeetupAnnotation alloc] initWithMeetup:meetup];
            [_meetupAnnotations addObject:ann];
        }else{
            ThreadAnnotation *ann = [[ThreadAnnotation alloc] initWithMeetup:meetup];
            [_threadAnnotations addObject:ann];
        }
        
        n++;
        if ( n >= l )
            break;
    }
    return n;
}

- (void)newThreadClicked{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupViewController" bundle:nil];
    [newMeetupViewController setType:TYPE_THREAD];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];

}


- (void)newMeetupClicked{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupViewController" bundle:nil];
    [newMeetupViewController setType:TYPE_MEETUP];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (IBAction)reloadTap:(id)sender {
    // UI
    [self.activityIndicator startAnimating];
    _reloadButton.hidden = TRUE;
    self.navigationController.view.userInteractionEnabled = NO;
    
    // Reload data
    // Crappy sure there's some easier way!
    CGPoint nePoint = CGPointMake(mapView.bounds.origin.x + mapView.bounds.size.width, mapView.bounds.origin.y);
    CGPoint swPoint = CGPointMake(mapView.bounds.origin.x, mapView.bounds.origin.y + mapView.bounds.size.height);
    CLLocationCoordinate2D neCoord;
    neCoord = [mapView convertPoint:nePoint toCoordinateFromView:mapView];
    CLLocationCoordinate2D swCoord;
    swCoord = [mapView convertPoint:swPoint toCoordinateFromView:mapView];    
    PFGeoPoint* northEast = [PFGeoPoint geoPointWithLatitude:neCoord.latitude longitude:neCoord.longitude];
    PFGeoPoint* southWest = [PFGeoPoint geoPointWithLatitude:swCoord.latitude longitude:swCoord.longitude];

    [globalData reloadMapInfoInBackground:southWest toNorthEast:northEast];
}

- (void) reloadStatusChanged
{
    // UI
    if ( [globalData getLoadingStatus:LOADING_CIRCLES] != LOAD_STARTED &&
            [globalData getLoadingStatus:LOADING_MAP] != LOAD_STARTED )
    {
        _reloadButton.hidden = FALSE;
        self.navigationController.view.userInteractionEnabled = YES;
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [self.activityIndicator startAnimating];
        _reloadButton.hidden = TRUE;
    }
    
    // Refresh map
    [self reloadMapAnnotations];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    _userLocation.coordinate = newLocation.coordinate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Misc
    [mapView setMapType:MKMapTypeStandard];
    [mapView setZoomEnabled:YES];
    [mapView setScrollEnabled:YES];
    [mapView setDelegate:self];
    mapView.showsUserLocation = NO;
    
    _locationManager = [[CLLocationManager alloc]init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [_locationManager startUpdatingLocation];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        _userLocation = [[PersonAnnotation alloc] init];
        Person *p = [[Person alloc]init:[PFUser currentUser] circle:0];
        p.isCurrentUser = YES;
        _userLocation.person = p;
        _userLocation.title = [[PFUser currentUser] objectForKey:@"fbName"];
        _userLocation.subtitle = @"This is you.";
        
    }
    
    // Navigation bar
    [self.navigationItem setHidesBackButton:true animated:false];
    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithTitle:@"New thread" style:UIBarButtonItemStyleBordered target:self action:@selector(newThreadClicked)],                                                                                                                                                                                                                 [[UIBarButtonItem alloc] initWithTitle:@"New meetup" style:UIBarButtonItemStyleBordered target:self action:@selector(newMeetupClicked)]];
    
    // Setting user location
    PFGeoPoint *geoPointUser = [[PFUser currentUser] objectForKey:@"location"];
    float span = 0.05f;
    

    
    // Default position
    if ( ! geoPointUser )
    {
        geoPointUser = [locManager getDefaultPosition];
        span = 0.25f;
    }
    
    // Default map location
    CLLocation* locationUser = [[CLLocation alloc] initWithLatitude:geoPointUser.latitude longitude:geoPointUser.longitude];
    _userLocation.coordinate = locationUser.coordinate;
    MKCoordinateRegion region = { {0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = locationUser.coordinate.latitude;//..mapView.userLocation.location.coordinate.latitude;
    region.center.longitude = locationUser.coordinate.longitude;//mapView.userLocation.location.coordinate.longitude;
    region.span.longitudeDelta = span;
    region.span.latitudeDelta = span;
    [mapView setRegion:region animated:YES];
    
    // Data updating
    [self reloadStatusChanged];
    
    [TestFlight passCheckpoint:@"Map"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self reloadMapAnnotations];
}

-(BOOL)isPerson:(PersonAnnotation*)per
   nearbyMeetup:(MeetupAnnotation*)meet{
    CLLocation *loc1 = [[CLLocation alloc]initWithLatitude:per.coordinate.latitude longitude:per.coordinate.longitude];
    CLLocation *loc2 = [[CLLocation alloc]initWithLatitude:meet.coordinate.latitude longitude:meet.coordinate.longitude];
    if ([loc1 distanceFromLocation:loc2] < DISTANCE_FOR_JOIN_PERSON_AND_MEETUP) {
        return YES;
    }
    return NO;
}

-(BOOL)isMeetupWillStartSoon:(MeetupAnnotation*)meet{
    if (meet.time > TIME_FOR_JOIN_PERSON_AND_MEETUP) {
        return YES;
    }
    return NO;
}

-(void)joinPersonsAndMeetups{
    NSMutableArray *personsAnnotationForRemove = [NSMutableArray arrayWithCapacity:4];
    for (PersonAnnotation* per in _personsAnnotations) {
        BOOL added = NO;
        for (MeetupAnnotation* meet in _meetupAnnotations) {
            if ([self isMeetupWillStartSoon:meet]&&
                [self isPerson:per nearbyMeetup:meet]) {
                [meet addPerson:per.person];
                [personsAnnotationForRemove addObject:per];
                added = YES;
                break;
            }
        }
        
        if (added)
            break;
    }
    [_personsAnnotations removeObjectsInArray:personsAnnotationForRemove];
}


-(void)reloadMapAnnotations{
    _personsAnnotations = [NSMutableArray arrayWithCapacity:20];
    _meetupAnnotations = [NSMutableArray arrayWithCapacity:20];
    _threadAnnotations = [NSMutableArray arrayWithCapacity:20];
    
    // Persons and meetups adding
    NSUInteger nLimit = MAX_ANNOTATIONS_ON_THE_MAP;
    nLimit -= [self loadPersonAnnotations:CIRCLE_FB limit:nLimit];
    nLimit -= [self loadPersonAnnotations:CIRCLE_2O limit:nLimit];
    nLimit -= [self loadPersonAnnotations:CIRCLE_RANDOM limit:nLimit];
    nLimit -= [self loadMeetupAndThreadAnnotations:nLimit];
    
    if (_userLocation)
        [_personsAnnotations addObject:_userLocation];
    [self joinPersonsAndMeetups];
    
    NSMutableArray *array = [_personsAnnotations mutableCopy];
    [array addObjectsFromArray:_meetupAnnotations];
    [array addObjectsFromArray:_threadAnnotations];

    [mapView addAnnotations:array];

    if ( nLimit == 0 ){
        // TODO: show message at the bottom: "Zoom closier to see more."
    }
}


-(MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id <MKAnnotation>)annotation
{
    REVClusterPin *pin = (REVClusterPin *)annotation;
    if( [pin nodeCount] > 0 ){
        pin.title = @"___";
        static NSString *clusterId = @"cluster";
        REVClusterAnnotationView *pinView;
        pinView = (REVClusterAnnotationView*)
        [mapView dequeueReusableAnnotationViewWithIdentifier:clusterId];
        
        if( !pinView )
            pinView = (REVClusterAnnotationView*)
            [[REVClusterAnnotationView alloc] initWithAnnotation:annotation
                                                 reuseIdentifier:clusterId] ;
        
        
        [pinView prepareForAnnotation:pin];
        pinView.canShowCallout = NO;
        return pinView;
    }else{
        SCAnnotationView *pinView;
        pinView = [SCAnnotationView constructAnnotationViewForAnnotation:annotation
                                                                  forMap:mV];
        [pinView prepareForAnnotation:annotation];
        
        if (_userLocation != annotation) {
            UIButton *btnView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            pinView.rightCalloutAccessoryView = btnView;
        }else{
            pinView.rightCalloutAccessoryView = nil;
        }

        pinView.canShowCallout = YES;
        return pinView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mV annotationView:(MKAnnotationView*)view calloutAccessoryControlTapped:(UIControl *)control {
    
    if ([(UIButton*)control buttonType] == UIButtonTypeDetailDisclosure){
        if ( [view.annotation isMemberOfClass:[PersonAnnotation class]] )
        {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [self.navigationController pushViewController:userProfileController animated:YES];
            [userProfileController setPerson:((PersonAnnotation*) view.annotation).person];
        }
        
        if ( [view.annotation isMemberOfClass:[MeetupAnnotation class]]||
            [view.annotation isMemberOfClass:[ThreadAnnotation class]])
        {
            MeetupViewController *meetupController = [[MeetupViewController alloc] initWithNibName:@"MeetupView" bundle:nil];
            [meetupController setMeetup:((MeetupAnnotation*) view.annotation).meetup];
            [self.navigationController pushViewController:meetupController animated:YES];
        }
    }
}

-(BOOL)fitMapViewForAnotations:(NSArray*)annotations{
    if ([self.mapView isMaximumZoom])
        return NO;
    

    
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in annotations){
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y,
                                            0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }

    NSInteger newLevel = [self.mapView zoomLevelForMarRect:zoomRect];
    if (newLevel < MAX_ZOOM_LEVEL) {
        [mapView setVisibleMapRect:zoomRect
                       edgePadding:UIEdgeInsetsMake(60, 30, 20, 30)
                          animated:YES];
        return YES;
    }
    
    return NO;
}

- (void)mapView:(MKMapView *)mv didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[REVClusterAnnotationView class]]) {
        REVClusterPin *pin = (REVClusterPin*)view.annotation;
        
        if ([self fitMapViewForAnotations:pin.nodes] == NO) {
            TableAnnotationsViewController *ctrl = [[TableAnnotationsViewController alloc]init];
            ctrl.annotations = pin.nodes;
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:ctrl];
            nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setMapView:nil];
    [super viewDidUnload];
}


- (void)filterClicked{
    FilterViewController *filterViewController = [[FilterViewController alloc] initWithNibName:@"FilterView" bundle:nil];
    [self.navigationController pushViewController:filterViewController animated:YES];
    //[self.navigationController setNavigationBarHidden:true animated:true];
}

@end
