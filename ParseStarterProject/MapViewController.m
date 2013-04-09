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

@implementation MapViewController

@synthesize mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSUInteger)addPersonAnnotations:(NSInteger)circleNumber limit:(NSInteger)l
{
    //NSString* strCircle = [Circle getCircleName:circleNumber];

    
    Circle* circle = [globalData getCircle:circleNumber];
    if ( ! circle )
        return 0;
    
    int n = 0;
    NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:30];
    for (Person* person in [circle getPersons] )
    {
        PersonAnnotation *ann = [[PersonAnnotation alloc] initWithPerson:person];
        [annotations addObject:ann];
        n++;
        if ( n >= l )
            break;
    }
    [mapView addAnnotations:annotations];
    return n;
}

- (NSUInteger)addMeetupAnnotations:(NSInteger)l
{
    int n = 0;
    NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:30];
    for (Meetup *meetup in [globalData getMeetups])
    {
        if (meetup.meetupType == TYPE_MEETUP) {
            MeetupAnnotation *ann = [[MeetupAnnotation alloc] initWithMeetup:meetup];
            [annotations addObject:ann];
        }else{
            ThreadAnnotation *ann = [[ThreadAnnotation alloc] initWithMeetup:meetup];
            [annotations addObject:ann];
        }
        
        n++;
        if ( n >= l )
            break;
    }
    [mapView addAnnotations:annotations];
    return n;
}

- (void)newThreadClicked{
    /*MeetupInviteViewController *invite = [[MeetupInviteViewController alloc] initWithNibName:@"MeetupInviteViewController" bundle:nil];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:invite];
    [self.navigationController presentViewController:navigation
                                            animated:YES completion:nil];*/
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupView" bundle:nil];
    [newMeetupViewController setType:TYPE_THREAD];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];

}


- (void)newMeetupClicked{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupView" bundle:nil];
    [newMeetupViewController setType:TYPE_MEETUP];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (void) reloadFinished
{
    self.initialized = YES;

    [self reloadMapAnnotations];
    [TestFlight passCheckpoint:@"List loading ended"];
    
    [self.activityIndicator stopAnimating];
    self.navigationController.view.userInteractionEnabled = YES;
}

- (void) actualReload
{
    [globalData reload:self];
}

- (void) reloadData {
    [self.activityIndicator startAnimating];
    self.navigationController.view.userInteractionEnabled = NO;
    [self performSelectorOnMainThread:@selector(actualReload) withObject:nil waitUntilDone:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    srand((unsigned)time(0));
    if (!self.initialized) {
        [TestFlight passCheckpoint:@"List loading started"];
        [self reloadData];
    }else{
        [TestFlight passCheckpoint:@"List restored"];
    }
    //self.title = NSLocalizedString(@"Map", @"Map");
    
    mapView.showsUserLocation = TRUE;
    
    [mapView setMapType:MKMapTypeStandard];
    [mapView setZoomEnabled:YES];
    [mapView setScrollEnabled:YES];
    [mapView setDelegate:self];
    
    // Navigation bar
    [self.navigationItem setHidesBackButton:true animated:false];
    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithTitle:@"New thread" style:UIBarButtonItemStyleBordered target:self action:@selector(newThreadClicked)],                                                                                                                                                                                                                 [[UIBarButtonItem alloc] initWithTitle:@"New meetup" style:UIBarButtonItemStyleBordered target:self action:@selector(newMeetupClicked)]];
    
    // Setting user location
    PFGeoPoint *geoPointUser = [[PFUser currentUser] objectForKey:@"location"];
    if ( geoPointUser )
    {
        [mapView setUserTrackingMode:MKUserTrackingModeNone animated:FALSE];
        
        CLLocation* locationUser = [[CLLocation alloc] initWithLatitude:geoPointUser.latitude longitude:geoPointUser.longitude];
        
        MKCoordinateRegion region = { {0.0, 0.0 }, { 0.0, 0.0 } };
        region.center.latitude = locationUser.coordinate.latitude;//..mapView.userLocation.location.coordinate.latitude;
        region.center.longitude = locationUser.coordinate.longitude;//mapView.userLocation.location.coordinate.longitude;
        region.span.longitudeDelta = 0.05f;
        region.span.latitudeDelta = 0.05f;
        [mapView setRegion:region animated:YES];
    }
    else
        [mapView setUserTrackingMode:MKUserTrackingModeFollow animated:TRUE];
    
    [TestFlight passCheckpoint:@"Map"];
}

-(void)reloadMapAnnotations{
    id userLocation = [mapView userLocation];
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[mapView annotations]];
    if ( userLocation != nil ) {
        [pins removeObject:userLocation]; // avoid removing user location off the map
    }
    [mapView removeAnnotations:pins];
    
    // Persons and meetups adding
    NSUInteger nLimit = MAX_ANNOTATIONS_ON_THE_MAP;
    nLimit -= [self addPersonAnnotations:1 limit:nLimit];
    nLimit -= [self addPersonAnnotations:2 limit:nLimit];
    nLimit -= [self addPersonAnnotations:3 limit:nLimit];
    nLimit -= [self addMeetupAnnotations:nLimit];
    
    if ( nLimit == 0 )
    {
        // TODO: show message at the bottom: "Zoom closier to see more."
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [self reloadMapAnnotations];
}




-(MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id <MKAnnotation>)annotation
{
    
    REVClusterPin *pin = (REVClusterPin *)annotation;
    if (annotation != mapView.userLocation)
    {
        if( [pin nodeCount] > 0 ){
            pin.title = @"___";
            REVClusterAnnotationView *annView;
            annView = (REVClusterAnnotationView*)
            [mapView dequeueReusableAnnotationViewWithIdentifier:@"cluster"];
            
            if( !annView )
                annView = (REVClusterAnnotationView*)
                [[REVClusterAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:@"cluster"] ;
            
            
            [annView setClusterNum:[pin nodeCount]];
            
            annView.canShowCallout = NO;
            return annView;
        }else{
            SCAnnotationView *pinView;
            pinView = [SCAnnotationView constructAnnotationViewForAnnotation:annotation
                                                                      forMap:mV];
            [pinView prepareForAnnotation:annotation];
            
            UIButton *btnView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            pinView.rightCalloutAccessoryView = btnView;
            pinView.canShowCallout = YES;
            return pinView;
        }

        
    }
    else {
        [mapView.userLocation setTitle:@"I am here"];
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

- (void)mapView:(MKMapView *)mv didSelectAnnotationView:(MKAnnotationView *)view
{
    
    if ([view isKindOfClass:[REVClusterAnnotationView class]]) {
        CLLocationCoordinate2D centerCoordinate = [(REVClusterPin *)view.annotation coordinate];
        
        MKCoordinateSpan newSpan =
        MKCoordinateSpanMake(mapView.region.span.latitudeDelta/2.0,
                             mapView.region.span.longitudeDelta/2.0);
        
        //mapView.region = MKCoordinateRegionMake(centerCoordinate, newSpan);
        
        [mapView setRegion:MKCoordinateRegionMake(centerCoordinate, newSpan)
                  animated:YES];
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
