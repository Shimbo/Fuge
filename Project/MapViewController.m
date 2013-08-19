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
#import "AnnotationCell.h"

@implementation MapViewController

@synthesize mapView, tableView;

//static Boolean bFirstZoom = true;

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
        //SEL focusMapOnMeetup = NSSelectorFromString(@"focusMapOnUserAndMeetups");  // To avoid stupid warning
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadStatusChanged)
                                                name:kNewMeetupCreated
                                                object:nil];
    }
    return self;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if ( ! _userLocation )
        [self addCurrentPerson];
    _userLocation.coordinate = newLocation.coordinate;
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

- (void)filterClicked{
    FilterViewController *filterViewController = [[FilterViewController alloc] initWithNibName:@"FilterView" bundle:nil];
    [self.navigationController pushViewController:filterViewController animated:YES];
    //[self.navigationController setNavigationBarHidden:true animated:true];
}

- (void)resizeScroll
{
    // Resizing comments
    NSUInteger newHeight = tableView.contentSize.height;
    CGRect frame = tableView.frame;
    frame.size.height = newHeight;
    tableView.frame = frame;
    
    // Resizing scroll view
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, tableView.frame.origin.y + tableView.frame.size.height)];
}

-(void)refreshView:(UIRefreshControl *)refreshControl {
    
    tableView.userInteractionEnabled = FALSE;
    
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
    // Stop animating refresh control
    if ( refreshControl )
        [refreshControl endRefreshing];
    
    // UI
    if ( [globalData getLoadingStatus:LOADING_CIRCLES] != LOAD_STARTED &&
            [globalData getLoadingStatus:LOADING_MAP] != LOAD_STARTED )
    {
        tableView.userInteractionEnabled = TRUE;
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [self.activityIndicator startAnimating];
    }
    
    sortedMeetups = [self getMeetupsByDate];
    
    // Refresh map
    [self reloadMapAnnotations];
    
    // Refresh table
    [tableView reloadData];
    
    // Resize scroll
    [self resizeScroll];
    
    // Focus map
    [self focusMapOnUserAndMeetups];
}

#pragma mark -
#pragma mark Map Operations

static CGRect oldMapFrame;

-(IBAction)mapTouched:(id)sender {
    hiddenButton.hidden = TRUE;
    [UIView animateWithDuration:0.2 animations:^{
        oldMapFrame = mapView.frame;
        mapView.frame = self.view.frame;
    } completion:^(BOOL finished) {
        mapView.userInteractionEnabled = TRUE;
        scrollView.scrollEnabled = FALSE;
        tableView.hidden = TRUE;
        self.navigationItem.rightBarButtonItems = @[ closeButton ];
    }];    
}

-(void)closeMap {
    
    self.navigationItem.rightBarButtonItems = @[ newMeetupButton ];
    tableView.hidden = FALSE;
    [UIView animateWithDuration:0.2 animations:^{
        mapView.frame = oldMapFrame;
    } completion:^(BOOL finished) {
        mapView.userInteractionEnabled = FALSE;
        scrollView.scrollEnabled = TRUE;
        hiddenButton.hidden = FALSE;
    }];
}

- (void)focusMapOnUser
{
    PFGeoPoint *geoPointUser = [pCurrentUser objectForKey:@"location"];
    if ( ! geoPointUser )
        geoPointUser = [locManager getDefaultPosition];
    
    CLLocation* locationUser = [[CLLocation alloc] initWithLatitude:geoPointUser.latitude longitude:geoPointUser.longitude];
    _userLocation.coordinate = locationUser.coordinate;
    MKCoordinateRegion region = { {0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = locationUser.coordinate.latitude;
    region.center.longitude = locationUser.coordinate.longitude;
    region.span.longitudeDelta = 0.05f;
    region.span.latitudeDelta = 0.05f;
    [mapView setRegion:region animated:YES];
}

/*- (void) focusMapOnMeetup:(NSNotification *)notification
{
    //daySelector = 8;
    //daySelectButton.title = dayButtonLabels[ daySelector ];
    [self reloadStatusChanged];
    
    Meetup *meetup = [[notification userInfo] objectForKey:@"meetup"];
    MKCoordinateRegion region = mapView.region;
    region.center.latitude = meetup.location.latitude;
    region.center.longitude = meetup.location.longitude;
    region.span.longitudeDelta = 0.05f;
    region.span.latitudeDelta = 0.05f;
    [mapView setRegion:region animated:YES];
}*/

- (void) focusMapOnUserAndMeetups
{
    PFGeoPoint *geoPointUser = [pCurrentUser objectForKey:@"location"];
    if ( ! geoPointUser )
        return;
    
    MKCoordinateRegion region = mapView.region;
    Boolean bZoom = FALSE;
    
    CLLocationCoordinate2D upper, lower;
    upper = lower = CLLocationCoordinate2DMake(geoPointUser.latitude, geoPointUser.longitude);
    
    // Calculating zoom
    if ( ! sortedMeetups )
        sortedMeetups = [self getMeetupsByDate];
    for ( NSMutableArray* meetupsByDay in sortedMeetups )
        for (Meetup *meetup in meetupsByDay)
        {
            if (meetup.meetupType == TYPE_MEETUP) {

                // Creating zoom for the map
                if ( ! meetup.isCanceled && [globalData isAttendingMeetup:meetup.strId])
                {
                    PFGeoPoint* pt = meetup.location;
                    if(pt.latitude > upper.latitude) upper.latitude = pt.latitude;
                    if(pt.latitude < lower.latitude) lower.latitude = pt.latitude;
                    if(pt.longitude > upper.longitude) upper.longitude = pt.longitude;
                    if(pt.longitude < lower.longitude) lower.longitude = pt.longitude;
                    bZoom = TRUE;
                }
            }
        }
    
    // Default map location
    if ( bZoom )
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
        if ( region.span.longitudeDelta < 0.05f || region.span.latitudeDelta < 0.05f )
        {
            region.span.longitudeDelta = 0.05f;
            region.span.latitudeDelta = 0.05f;
        }
        [mapView setRegion:region animated:YES];
    }
}

- (void)addCurrentPerson
{
    Person* current = currentPerson;
    _userLocation = [[PersonAnnotation alloc] initWithPerson:current];
    _userLocation.title = [globalVariables shortUserName];
    if ( current.strStatus && current.strStatus.length > 0 )
        _userLocation.subtitle = current.strStatus;
    else
        _userLocation.subtitle = @"This is you";
    [self focusMapOnUserAndMeetups];
}

-(void)joinPersonsAndMeetups{
    NSMutableArray *personsAnnotationForRemove = [NSMutableArray arrayWithCapacity:4];
    for (PersonAnnotation* per in _personsAnnotations) {
        for (MeetupAnnotation* meet in _meetupAnnotations) {
            if ([meet.meetup willStartSoon] &&
                    [meet.meetup isPersonNearby:per.person] &&
                    [meet.meetup hasAttendee:per.person.strId]) {
                [meet addPerson:per.person];
                [personsAnnotationForRemove addObject:per];
                break;
            }
        }
    }
    [_personsAnnotations removeObjectsInArray:personsAnnotationForRemove];
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


#pragma mark -
#pragma mark Main Cycle

/*- (void)recalcDateSelectionTexts
{
    // Texts for buttons
    NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
    [theDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [theDateFormatter setDateFormat:@"EEEE"];
    NSDateFormatter* theDateFormatter2 = [[NSDateFormatter alloc] init];
    [theDateFormatter2 setFormatterBehavior:NSDateFormatterBehavior10_4];
    [theDateFormatter2 setDateFormat:@"dd MMM"];
    dayButtonLabels = [NSMutableArray arrayWithCapacity:9];
    selectionChoices = [NSMutableArray arrayWithCapacity:9];
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
    [dayButtonLabels addObject:@"All month"];
    [selectionChoices addObject:@"All month"];
    
    daySelectButton.title = dayButtonLabels[ daySelector ];
}*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Misc
#ifdef IOS7_ENABLE
    mapView.rotateEnabled = FALSE;
#endif
    mapView.userInteractionEnabled = FALSE;
    
    _locationManager = [[CLLocationManager alloc]init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [_locationManager startUpdatingLocation];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
        [self addCurrentPerson];
    
    // Navigation bar: new meetup
    newMeetupButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"MAP_BUTTON_NEWMEETUP",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(newMeetupClicked)];
    self.navigationItem.rightBarButtonItems = @[ newMeetupButton ];
    
    // Close button (for the map)
    closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(closeMap)];
    
//#ifdef TARGET_S2C
    //daySelector = 8;
//#endif
    
    // Navigation bar: date selector
    /*NSArray* oldLeft = self.navigationItem.leftBarButtonItems;
    daySelectButton = [[UIBarButtonItem alloc] initWithTitle:@"Temp" style:UIBarButtonItemStyleBordered target:self action:@selector(dateSelectorClicked)];
    [self recalcDateSelectionTexts];
    if ( oldLeft.count > 0 )
        self.navigationItem.leftBarButtonItems = @[ oldLeft[0], daySelectButton ];*/
    
    // Table
    UINib *nib = [UINib nibWithNibName:@"AnnotationCellMeetup" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"MeetupCell"];
    
    // Setting user location and focusing map
    [self focusMapOnUser];
    
    // Data updating
    [self reloadStatusChanged];
    
    // Refresh control
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [scrollView addSubview:refreshControl];
    
    [TestFlight passCheckpoint:@"Map"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[self recalcDateSelectionTexts];
    [self reloadMapAnnotations];
    [tableView reloadData];
}

- (NSArray*) getMeetupsByDate
{
    NSMutableArray* arrayOfDays = [NSMutableArray arrayWithCapacity:MAX_DAYS_TILL_MEETUP];
    
    // Day by day selection
    for ( NSUInteger n = 0; n < MAX_DAYS_TILL_MEETUP; n++ )
    {
        // Array
        NSMutableArray* arrayOfMeetups = [NSMutableArray arrayWithCapacity:10];
        [arrayOfDays addObject:arrayOfMeetups];
        
        // Timeframe
        NSDate *windowStart, *windowEnd;
        
        // Selecting days
        NSDateComponents* comps = [[NSDateComponents alloc] init];
        [comps setDay:n];
        NSDate* startDay = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:[NSDate date] options:0];
        [comps setDay:n+1];
        NSDate* endDay = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:[NSDate date] options:0];
    
        // Changing window start if not today
        if ( n > 0 )
        {
            comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:startDay];
            [comps setHour:5];
            [comps setMinute:0];
            windowStart = [[NSCalendar currentCalendar] dateFromComponents:comps];
        }
        else
            windowStart = [NSDate date];
        
        // Calculating end date
        comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:endDay];
        [comps setHour:5];
        [comps setMinute:0];
        windowEnd = [[NSCalendar currentCalendar] dateFromComponents:comps];
        
        // Loading annotations
        for (Meetup *meetup in [globalData getMeetups])
        {
            if (meetup.meetupType == TYPE_MEETUP)
                if ( ! meetup.hasPassed && /*! meetup.isCanceled &&*/ [meetup isWithinTimeFrame:windowStart till:windowEnd] )
                    [arrayOfMeetups addObject:meetup];
        }
        
        // Sorting meetups by date
        [arrayOfMeetups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [((Meetup*)obj1).dateTime compare:((Meetup*)obj2).dateTime ];
        }];
    }
    
    return arrayOfDays;
}


/*- (NSArray*) getMeetupsByDate2
{
    // Calculating date windows
    NSDate* windowStart = [NSDate date];
    NSDate* windowEnd = [NSDate date];
    
    // Changing day
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setDay:daySelector];
    NSDate* startDay = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:[NSDate date] options:0];
    if ( daySelector == 8 ) // whole month selected
        [comps setDay:30];
    else if ( daySelector == 7 ) // whole week selected
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
            if ( ! meetup.hasPassed && //! meetup.isCanceled &&
                    [meetup isWithinTimeFrame:windowStart till:windowEnd] )
                [resultMeetups addObject:meetup];
    }
    
    // Sorting meetups by date
    [resultMeetups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((Meetup*)obj1).dateTime compare:((Meetup*)obj2).dateTime ];
    }];
    
    return resultMeetups;
}*/

- (NSUInteger)loadMeetupAndThreadAnnotations:(NSInteger)l
{
    // Loading annotations
    NSUInteger n = 0;
    if ( ! sortedMeetups )
        sortedMeetups = [self getMeetupsByDate];
    for ( NSMutableArray* meetupsByDay in sortedMeetups )
        for (Meetup *meetup in meetupsByDay)
        {
            if (meetup.meetupType == TYPE_MEETUP) {
                MeetupAnnotation *ann = [[MeetupAnnotation alloc] initWithMeetup:meetup];
                [_meetupAnnotations addObject:ann];
            }else{ // Warning! Now getMeetupsByDate will never return any thread at all!
                ThreadAnnotation *ann = [[ThreadAnnotation alloc] initWithMeetup:meetup];
                [_threadAnnotations addObject:ann];
            }
            
            n++;
            if ( n >= l )
                break;
        }
    
    return n;
}

- (NSUInteger)loadPersonAnnotations:(CircleType)circleNumber limit:(NSInteger)l
{
    Circle* circle = [globalData getCircle:circleNumber];
    if ( ! circle )
        return 0;
    
    int n = 0;
    for (Person* person in [circle getPersons] )
    {
        // Location check
        if ( ! person.location || ! person.discoverable )
            continue;
        
        // Date check; we should add active section for the people list as well
        if ( person.isOutdated )
            continue;
        
        PersonAnnotation *ann = [[PersonAnnotation alloc] initWithPerson:person];
        [_personsAnnotations addObject:ann];
        n++;
        if ( n >= l )
            break;
    }
    return n;
}

-(void)reloadMapAnnotations{
    _personsAnnotations = [NSMutableArray arrayWithCapacity:20];
    _meetupAnnotations = [NSMutableArray arrayWithCapacity:20];
    _threadAnnotations = [NSMutableArray arrayWithCapacity:20];
    
    // Persons and meetups adding
    NSUInteger nLimit = MAX_ANNOTATIONS_ON_THE_MAP;
    
#ifndef TARGET_S2C
    //if ( daySelector == 0 ) // Show people only for "today" selection
    {
        nLimit -= [self loadPersonAnnotations:CIRCLE_FB limit:nLimit];
        nLimit -= [self loadPersonAnnotations:CIRCLE_2O limit:nLimit];
        nLimit -= [self loadPersonAnnotations:CIRCLE_RANDOM limit:nLimit];
    }
#endif
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

#pragma mark -
#pragma mark Map View delegate

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
    tableView = nil;
    [self setTableView:nil];
    scrollView = nil;
    hiddenButton = nil;
    [super viewDidUnload];
}


#pragma mark -
#pragma mark Picker View delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 1;
    
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return 9;
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return @"None";//selectionChoices[row];
    
}

// this method runs whenever the user changes the selected list option

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    //daySelectButton.title = dayButtonLabels[ row ];
    //daySelector = row;
    //[self reloadStatusChanged];
}

- (void) dateSelectorClicked {
    
    // Picker view
    CGRect pickerFrame = CGRectMake(0, 40, 320, 445);
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.showsSelectionIndicator = YES;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    //[pickerView selectRow:daySelector inComponent:0 animated:NO];
    
    // Close button
    UISegmentedControl *closeBtn = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Close"]];
    closeBtn.momentary = YES;
    closeBtn.frame = CGRectMake(260, 7, 50, 30);
    closeBtn.segmentedControlStyle = UISegmentedControlStyleBar;
    closeBtn.tintColor = [UIColor blackColor];
    [closeBtn addTarget:self action:@selector(dismissPopup) forControlEvents:UIControlEventValueChanged];
    
    if ( IPAD )
    {
        // View and VC
        UIView *view = [[UIView alloc] init];
        [view addSubview:pickerView];
        [view addSubview:closeBtn];
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
        [actionSheet addSubview:closeBtn];
        [actionSheet showInView:self.view];
        [actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
    }
}

- (void) dismissPopup {
    
    if ( IPAD )
        [popover dismissPopoverAnimated:TRUE];
    else
        [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}


#pragma mark -
#pragma mark Table View delegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* meetupsByDay = sortedMeetups[indexPath.section];
    Meetup* meetup = meetupsByDay[indexPath.row];
    if ( meetup.strFeatured )
        return 92;
    else
        return 70;//(50+10*indexPath.item); // I put some padding on it.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    
    if ( [globalData getMeetups].count == 0 )
        return 1;
    return MAX_DAYS_TILL_MEETUP;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	
    NSMutableArray* meetupsByDay = sortedMeetups[section];
    return meetupsByDay.count;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {

    if ( [globalData getLoadingStatus:LOADING_MAP] == LOAD_STARTED )
        return @"Loading events...";
    
    if ( [globalData getMeetups].count == 0 )
        return @"No upcoming events nearby";
    
    NSMutableArray* meetupsByDay = sortedMeetups[section];
    if ( meetupsByDay.count == 0 )
        return nil;
    
    // Texts for buttons
    NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
    [theDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [theDateFormatter setDateFormat:@"EEEE"];
    NSDateFormatter* theDateFormatter2 = [[NSDateFormatter alloc] init];
    [theDateFormatter2 setFormatterBehavior:NSDateFormatterBehavior10_4];
    [theDateFormatter2 setDateFormat:@"dd MMM"];
    //dayButtonLabels = [NSMutableArray arrayWithCapacity:9];
    //selectionChoices = [NSMutableArray arrayWithCapacity:9];
    
    NSDate* day = [NSDate dateWithTimeIntervalSinceNow:86400*section];
    NSString *weekDay = [theDateFormatter stringFromDate:day];
    if ( section == 0 )
        weekDay = @"Today";
    if ( section == 1 )
        weekDay = @"Tomorrow";
    
    return [NSString stringWithFormat:@"%@, %@", weekDay, [theDateFormatter2 stringFromDate:day]];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
	MeetupAnnotationCell *meetupCell = (MeetupAnnotationCell *)[table dequeueReusableCellWithIdentifier:@"MeetupCell"];
	
    NSMutableArray* meetupsByDay = sortedMeetups[indexPath.section];
    [meetupCell initWithMeetup:meetupsByDay[indexPath.row]];
    
	return meetupCell;
}

/*- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = ((PersonCell*)cell).color;
}*/

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MeetupViewController *meetupController = [[MeetupViewController alloc] initWithNibName:@"MeetupView" bundle:nil];
    
    NSMutableArray* meetupsByDay = sortedMeetups[indexPath.section];
    [meetupController setMeetup:meetupsByDay[indexPath.row]];
    
    [self.navigationController pushViewController:meetupController animated:YES];
    
	[table deselectRowAtIndexPath:indexPath animated:YES];
}



@end
