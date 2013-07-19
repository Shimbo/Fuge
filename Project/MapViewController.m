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

static Boolean bFirstZoom = true;

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
        SEL focusMapOnMeetup = NSSelectorFromString(@"focusMapOnMeetup:");  // To avoid stupid warning
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:focusMapOnMeetup
                                                name:kNewMeetupCreated
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
        if ( ! person.getLocation )
            continue;
        PersonAnnotation *ann = [[PersonAnnotation alloc] initWithPerson:person];
        [_personsAnnotations addObject:ann];
        n++;
        if ( n >= l )
            break;
    }
    return n;
}

- (NSArray*) getMeetupsByDate
{
    // Calculating date windows
    NSDate* windowStart = [NSDate date];
    NSDate* windowEnd = [NSDate date];
    
    // Changing day
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setDay:daySelector];
    NSDate* startDay = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:[NSDate date] options:0];
    if ( daySelector == 7 ) // whole week selected
        [comps setDay:7];
    else
        [comps setDay:daySelector+1];
    NSDate* endDay = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:[NSDate date] options:0];
    
    // Calculating start date for this new day
    comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:startDay];
    [comps setHour:5];
    [comps setMinute:0];
    if ( daySelector > 0 && daySelector < 7 )
        windowStart = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    // Calculating end date for this new day
    comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:endDay];
    [comps setHour:5];
    [comps setMinute:0];
    windowEnd = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    // Loading annotations
    NSMutableArray* resultMeetups = [NSMutableArray arrayWithCapacity:30];
    for (Meetup *meetup in [globalData getMeetups])
    {
        if (meetup.meetupType == TYPE_MEETUP)
            if ( ! meetup.hasPassed && [meetup isWithinTimeFrame:windowStart till:windowEnd] )
                [resultMeetups addObject:meetup];
    }
    return resultMeetups;
}

- (NSUInteger)loadMeetupAndThreadAnnotations:(NSInteger)l
{
    PFGeoPoint *geoPointUser = [pCurrentUser objectForKey:@"location"];
    MKCoordinateRegion region = mapView.region;
    Boolean bZoom = FALSE;
    
    CLLocationCoordinate2D upper, lower;
    if ( geoPointUser )
        upper = lower = CLLocationCoordinate2DMake(geoPointUser.latitude, geoPointUser.longitude);
    
    // Loading annotations
    NSUInteger n = 0;
    NSArray* meetups = [self getMeetupsByDate];
    if ( meetups.count == 0 )
        return 0;
    for (Meetup *meetup in meetups)
    {
        if (meetup.meetupType == TYPE_MEETUP) {
            MeetupAnnotation *ann = [[MeetupAnnotation alloc] initWithMeetup:meetup];
            [_meetupAnnotations addObject:ann];
            
            // Creating zoom for the map
            if ( geoPointUser && [globalData isAttendingMeetup:meetup.strId])
            {
                PFGeoPoint* pt = meetup.location;
                if(pt.latitude > upper.latitude) upper.latitude = pt.latitude;
                if(pt.latitude < lower.latitude) lower.latitude = pt.latitude;
                if(pt.longitude > upper.longitude) upper.longitude = pt.longitude;
                if(pt.longitude < lower.longitude) lower.longitude = pt.longitude;
                bZoom = TRUE;
            }
        }else{ // Warning! Now getMeetupsByDate will never return any thread at all!
            ThreadAnnotation *ann = [[ThreadAnnotation alloc] initWithMeetup:meetup];
            [_threadAnnotations addObject:ann];
        }
        
        n++;
        if ( n >= l )
            break;
    }
    
    // Default map location
    if ( geoPointUser && bFirstZoom && bZoom )
    {
        MKCoordinateSpan locationSpan;
        locationSpan.latitudeDelta = upper.latitude - lower.latitude;
        locationSpan.longitudeDelta = upper.longitude - lower.longitude;
        CLLocationCoordinate2D locationCenter;
        locationCenter.latitude = (upper.latitude + lower.latitude) / 2;
        locationCenter.longitude = (upper.longitude + lower.longitude) / 2;
        
        region = MKCoordinateRegionMake(locationCenter, locationSpan);
        region.span.latitudeDelta *= 1.1f;
        region.span.longitudeDelta *= 1.1f;
        [mapView setRegion:region animated:YES];
    }
    
    bFirstZoom = false;
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
    if ( ! currentPerson )
        [self addCurrentPerson];
}

- (void)focusMapOnUser
{
    PFGeoPoint *geoPointUser = [pCurrentUser objectForKey:@"location"];
    if ( ! geoPointUser )
        geoPointUser = [locManager getDefaultPosition];
    
    CLLocation* locationUser = [[CLLocation alloc] initWithLatitude:geoPointUser.latitude longitude:geoPointUser.longitude];
    _userLocation.coordinate = locationUser.coordinate;
    MKCoordinateRegion region = { {0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = locationUser.coordinate.latitude;//..mapView.userLocation.location.coordinate.latitude;
    region.center.longitude = locationUser.coordinate.longitude;//mapView.userLocation.location.coordinate.longitude;
    region.span.longitudeDelta = 0.05f;
    region.span.latitudeDelta = 0.05f;
    [mapView setRegion:region animated:YES];
}

- (void) focusMapOnMeetup:(NSNotification *)notification
{
    daySelector = 0;
    daySelectButton.title = dayButtonLabels[ daySelector ];
    [self reloadStatusChanged];

    Meetup *meetup = [[notification userInfo] objectForKey:@"meetup"];
    MKCoordinateRegion region = mapView.region;
    region.center.latitude = meetup.location.latitude;
    region.center.longitude = meetup.location.longitude;
    region.span.longitudeDelta = 0.05f;
    region.span.latitudeDelta = 0.05f;
    [mapView setRegion:region animated:YES];
}

- (void)addCurrentPerson
{
    currentPerson = [[Person alloc] init:pCurrentUser circle:CIRCLE_NONE];
    currentPerson.isCurrentUser = YES;
    _userLocation = [[PersonAnnotation alloc] initWithPerson:currentPerson];
    _userLocation.title = [globalVariables shortUserName];
    if ( currentPerson.strStatus && currentPerson.strStatus.length > 0 )
        _userLocation.subtitle = currentPerson.strStatus;
    else
        _userLocation.subtitle = @"This is you";
    [self focusMapOnUser];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Texts for buttons
    NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
    [theDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [theDateFormatter setDateFormat:@"EEEE"];
    NSDateFormatter* theDateFormatter2 = [[NSDateFormatter alloc] init];
    [theDateFormatter2 setFormatterBehavior:NSDateFormatterBehavior10_4];
    [theDateFormatter2 setDateFormat:@"dd MMM"];
    dayButtonLabels = [NSMutableArray arrayWithCapacity:7];
    selectionChoices = [NSMutableArray arrayWithCapacity:8];
    for ( NSUInteger n = 0; n < 7; n++ )
    {
        NSDate* day = [NSDate dateWithTimeIntervalSinceNow:24*n*3600];
        NSString *weekDay = [theDateFormatter stringFromDate:day];
        if ( n == 0 )
            weekDay = @"Today";
        if ( n == 1 )
            weekDay = @"Tomorrow";
        [dayButtonLabels addObject:weekDay];
        NSString* selection = [NSString stringWithFormat:@"%@, %@", weekDay, [theDateFormatter2 stringFromDate:day]];
        [selectionChoices addObject:selection];
    }
    [dayButtonLabels addObject:@"All week"];
    [selectionChoices addObject:@"All week"];
    
    // Misc
    [mapView setMapType:MKMapTypeStandard];
    [mapView setZoomEnabled:YES];
    [mapView setScrollEnabled:YES];
    [mapView setDelegate:self];
    mapView.showsUserLocation = NO;
#ifdef IOS7_ENABLE
    mapView.rotateEnabled = FALSE;
#endif
    
    _locationManager = [[CLLocationManager alloc]init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [_locationManager startUpdatingLocation];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
        [self addCurrentPerson];
    
    // Navigation bar: new meetup
    [self.navigationItem setHidesBackButton:true animated:false];
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"New meetup" style:UIBarButtonItemStyleBordered target:self action:@selector(newMeetupClicked)]];
    
    // Navigation bar: date selector
    NSArray* oldLeft = self.navigationItem.leftBarButtonItems;
    daySelectButton = [[UIBarButtonItem alloc] initWithTitle:@"Today" style:UIBarButtonItemStyleBordered target:self action:@selector(dateSelectorClicked)];
    if ( oldLeft.count > 0 )
        self.navigationItem.leftBarButtonItems = @[ oldLeft[0], daySelectButton ];
    
    // Setting user location and focusing map
    [self focusMapOnUser];
    
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
        for (MeetupAnnotation* meet in _meetupAnnotations) {
            if ([self isMeetupWillStartSoon:meet]&&
                [self isPerson:per nearbyMeetup:meet]) {
                [meet addPerson:per.person];
                [personsAnnotationForRemove addObject:per];
                break;
            }
        }
    }
    [_personsAnnotations removeObjectsInArray:personsAnnotationForRemove];
}


-(void)reloadMapAnnotations{
    _personsAnnotations = [NSMutableArray arrayWithCapacity:20];
    _meetupAnnotations = [NSMutableArray arrayWithCapacity:20];
    _threadAnnotations = [NSMutableArray arrayWithCapacity:20];
    
    // Persons and meetups adding
    NSUInteger nLimit = MAX_ANNOTATIONS_ON_THE_MAP;
    
    if ( daySelector == 0 ) // Show people only for "today" selection
    {
        nLimit -= [self loadPersonAnnotations:CIRCLE_FB limit:nLimit];
        nLimit -= [self loadPersonAnnotations:CIRCLE_2O limit:nLimit];
        nLimit -= [self loadPersonAnnotations:CIRCLE_RANDOM limit:nLimit];
    }
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
            [userProfileController setPerson:((PersonAnnotation*) view.annotation).person];
            [self.navigationController pushViewController:userProfileController animated:YES];
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

-(BOOL)fitMapViewForAnotations:(NSArray*)annotations onlyTest:(Boolean)test{
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
        if ( ! test )
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
        
        //if ([self fitMapViewForAnotations:pin.nodes onlyTest:true] == NO) {
            TableAnnotationsViewController *ctrl = [[TableAnnotationsViewController alloc]init];
            ctrl.annotations = pin.nodes;
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:ctrl];
            nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:nav animated:YES completion:nil];
        /*}
        else
        {
            [self fitMapViewForAnotations:pin.nodes onlyTest:false];
        }*/
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


#pragma mark -
#pragma mark Picker View

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 1;
    
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return 8;
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return selectionChoices[row];
    
}

// this method runs whenever the user changes the selected list option

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    daySelectButton.title = dayButtonLabels[ row ];
    daySelector = row;
    [self reloadStatusChanged];
}

- (void) dateSelectorClicked {
    
    // Picker view
    CGRect pickerFrame = CGRectMake(0, 40, 320, 445);
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.showsSelectionIndicator = YES;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    [pickerView selectRow:daySelector inComponent:0 animated:NO];
    
    // Close button
    UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Close"]];
    closeButton.momentary = YES;
    closeButton.frame = CGRectMake(260, 7, 50, 30);
    closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
    closeButton.tintColor = [UIColor blackColor];
    [closeButton addTarget:self action:@selector(dismissPopup) forControlEvents:UIControlEventValueChanged];
    
    if ( IPAD )
    {
        // View and VC
        UIView *view = [[UIView alloc] init];
        [view addSubview:pickerView];
        [view addSubview:closeButton];
        UIViewController *vc = [[UIViewController alloc] init];
        [vc setView:view];
        [vc setContentSizeForViewInPopover:CGSizeMake(320, 260)];
        
        if ( ! popover )
            popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        [popover presentPopoverFromBarButtonItem:daySelectButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
        [actionSheet addSubview:pickerView];
        [actionSheet addSubview:closeButton];
        [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
        [actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
    }
}

- (void) dismissPopup {
    
    if ( IPAD )
        [popover dismissPopoverAnimated:TRUE];
    else
        [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

@end
