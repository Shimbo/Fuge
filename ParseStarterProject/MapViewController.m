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
#import "AsyncAnnotationView.h"


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
    NSUInteger color;
    switch (circleNumber)
    {
        case 1:
            color = MKPinAnnotationColorGreen;
            break;
        case 2:
            color = MKPinAnnotationColorRed;
            break;
        case 3:
            color = MKPinAnnotationColorPurple;
            break;
    }
    
    Circle* circle = [globalData getCircle:circleNumber];
    if ( ! circle )
        return 0;
    
    int n = 0;
    for (Person* person in [circle getPersons] )
    {
        PersonAnnotation *ann = [[PersonAnnotation alloc] init];
        ann.title = person.strName;
        ann.subtitle = [[NSString alloc] initWithFormat:
                        @"%@%@ %@",
                        person.strRole,
                        person.strArea.length?@",":@"",
                        person.strArea ];
        ann.coordinate = person.getLocation;
        ann.color = color;
        
        ann.person = person;
        
        [mapView addAnnotation:ann];
        
        n++;
        if ( n >= l )
            return n;
    }
    
    return n;
}

- (NSUInteger)addMeetupAnnotations:(NSInteger)l
{
    int n = 0;
    
    for (Meetup *meetup in [globalData getMeetups])
    {
        MeetupAnnotation *ann = [[MeetupAnnotation alloc] init];
        
        NSString* strPrivacy = nil;
        NSUInteger color;
        switch ( meetup.privacy )
        {
            case 0: strPrivacy = @"Public"; color = MKPinAnnotationColorGreen; break;
            case 1: strPrivacy = @"Private"; color = MKPinAnnotationColorRed; break;
        }
        ann.title = meetup.strSubject;
        ann.subtitle = [[NSString alloc] initWithFormat:@"Organizer: %@", meetup.strOwnerName ];
        ann.strId = meetup.strId;
        ann.color = color;
        
        CLLocationCoordinate2D coord;
        coord.latitude = meetup.location.latitude;
        coord.longitude = meetup.location.longitude;
        ann.coordinate = coord;
        
        ann.meetup = meetup;
        
        // Useful!!!
        NSUInteger unreadComments = [meetup getUnreadMessagesCount]; // if > 0 show messages count
        Boolean passed = [meetup hasPassed]; // grey?
        Boolean attorsubsc; // orange or just blue?
        if ( meetup.meetupType == TYPE_MEETUP )
            attorsubsc = [globalData isAttendingMeetup:meetup.strId];
        else
            attorsubsc = [globalData isSubscribedToThread:meetup.strId];
        Boolean private = (meetup.privacy == MEETUP_PRIVATE); // lock or normal icon
        Boolean typeMeetup = (meetup.meetupType == TYPE_MEETUP); // meetup or thread
        if ( typeMeetup && ! passed ) // Show timer from 0 to 1 where 1 is max, 0 is min
        {
            float fTimer = [meetup getTimerTill];
            // show timer
        }
        
        [mapView addAnnotation:ann];
        
        n++;
        if ( n >= l )
            return n;
    }
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

#define kAsyncTag 321

-(MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKPinAnnotationView *pinView = nil;
    if (annotation != mapView.userLocation)
    {
        static NSString *defaultPinID = @"secondcircle.pin";
        static NSString *defaultPersonImage = @"person.image";
        
        NSString *identifier = defaultPinID;
        BOOL isPerson = NO;
        if ([annotation isMemberOfClass:[PersonAnnotation class]]) {
            isPerson = YES;
            identifier = defaultPersonImage;
        }
        pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];

        if ( pinView == nil ){
            if (isPerson) {
                pinView = (MKPinAnnotationView*)
                [[AsyncAnnotationView alloc]initWithAnnotation:annotation
                                                      reuseIdentifier:identifier];
            }else{
                pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:defaultPinID];
            }
        }
        
        if ( isPerson ){
            AsyncAnnotationView *pin = (AsyncAnnotationView*)pinView;
            [pin loadImageWithURL:((PersonAnnotation*) annotation).person.imageURL];
        } else{
            pinView.pinColor = ((MeetupAnnotation*) annotation).color;
            pinView.animatesDrop = NO;
        }
        
        UIButton *btnView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        pinView.rightCalloutAccessoryView=btnView;
        pinView.canShowCallout = YES;
        
    }
    else {
        [mapView.userLocation setTitle:@"I am here"];
    }
    return pinView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView*)view calloutAccessoryControlTapped:(UIControl *)control {
    
    if ([(UIButton*)control buttonType] == UIButtonTypeDetailDisclosure){
        if ( [view.annotation isMemberOfClass:[PersonAnnotation class]] )
        {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [self.navigationController pushViewController:userProfileController animated:YES];
            [userProfileController setPerson:((PersonAnnotation*) view.annotation).person];
        }
        if ( [view.annotation isMemberOfClass:[MeetupAnnotation class]] )
        {
            MeetupViewController *meetupController = [[MeetupViewController alloc] initWithNibName:@"MeetupView" bundle:nil];
            [meetupController setMeetup:((MeetupAnnotation*) view.annotation).meetup];
            [self.navigationController pushViewController:meetupController animated:YES];
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
