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

- (void)addPersonAnnotations:(NSInteger)circleNumber limit:(NSInteger)l
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
        return;
    
    int n = 0;
    for (Person* person in [circle getPersons] )
    {
        PersonAnnotation *ann = [[PersonAnnotation alloc] init];
        ann.title = person.strName;
        ann.subtitle = [[NSString alloc] initWithFormat:@"%@, %@", person.strRole, person.strArea ];
        ann.coordinate = person.getLocation;
        ann.color = color;
        [ann setPerson:person];
        [mapView addAnnotation:ann];
        
        n++;
        if ( n >= l )
            return;
    }
}

- (void)addMeetupAnnotations:(NSInteger)l
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
            case 1: strPrivacy = @"2ndO"; color = MKPinAnnotationColorPurple; break;
            case 2: strPrivacy = @"Private"; color = MKPinAnnotationColorRed; break;
        }
        ann.title = meetup.strSubject;
        ann.subtitle = [[NSString alloc] initWithFormat:@"Organizer: %@", meetup.strOwnerName ];
        ann.strId = meetup.strId;
        ann.color = color;
        
        CLLocationCoordinate2D coord;
        coord.latitude = meetup.location.latitude;
        coord.longitude = meetup.location.longitude;
        ann.coordinate = coord;
        
        [ann setMeetup:meetup];
        [mapView addAnnotation:ann];
        
        n++;
        if ( n >= l )
            return;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Map", @"Map");
    
    mapView.showsUserLocation = TRUE;
    
    [mapView setMapType:MKMapTypeStandard];
    [mapView setZoomEnabled:YES];
    [mapView setScrollEnabled:YES];
    [mapView setDelegate:self];
    
    //[mapView setUserTrackingMode:MKUserTrackingModeFollow animated:FALSE];
    
    // Persons and meetups adding
    //TODO: return count of added to use single limit for persons, move limits to config
    [self addPersonAnnotations:1 limit:20];
    [self addPersonAnnotations:2 limit:20];
    [self addPersonAnnotations:3 limit:20];
    [self addMeetupAnnotations:20];
    
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
        
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(filterClicked)];
    
    [TestFlight passCheckpoint:@"Map"];
}

-(MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKPinAnnotationView *pinView = nil;
    if (annotation != mapView.userLocation)
    {
        static NSString *defaultPinID = @"secondcircle.pin";
        pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
        if ( pinView == nil ) pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
        
        if ( [annotation isMemberOfClass:[PersonAnnotation class]] )
        {
            pinView.pinColor = ((PersonAnnotation*) annotation).color;
            //UIImage *image = ((PersonAnnotation*) annotation).person.image;
            //UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            //[pinView addSubview:imageView];
            pinView.image = ((PersonAnnotation*) annotation).person.image;
        }
        if ( [annotation isMemberOfClass:[MeetupAnnotation class]] )
        {
            pinView.pinColor = ((MeetupAnnotation*) annotation).color;
            //pinView.image = nil;
        }
        
        UIButton *btnView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        pinView.rightCalloutAccessoryView=btnView;
        pinView.canShowCallout = YES;
        pinView.animatesDrop = YES;
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
