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
#import "ProfileViewController.h"
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
    NSString* strCircle;
    NSUInteger color;
    switch (circleNumber)
    {
        case 1:
            strCircle = @"First circle";
            color = MKPinAnnotationColorGreen;
            break;
        case 2:
            strCircle = @"Second circle";
            color = MKPinAnnotationColorRed;
            break;
        case 3:
            strCircle = @"Random connections";
            color = MKPinAnnotationColorPurple;
            break;
    }
    if ( ! strCircle )
        return;
    
    Circle* circle = [Circle circleNamed:strCircle];
    if ( ! circle )
        return;
    
    int n = 0;
    for (Person* person in circle.persons )
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
    PFQuery *meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
    
    // Location filter
    [meetupAnyQuery whereKey:@"location" nearGeoPoint:[[PFUser currentUser] objectForKey:@"location"] withinKilometers:RANDOM_EVENT_KILOMETERS];
    
    // Date-time filter
    NSNumber* timestampNow = [[NSNumber alloc] initWithDouble:[[NSDate date] timeIntervalSince1970]];
    [meetupAnyQuery whereKey:@"meetupTimestamp" greaterThan:timestampNow];
    //[meetupAnyQuery whereKey:@"privacy" notEqualTo:@"2"]; // Hide private events
    // TODO: uncomment it and add another query for the events user is subscribed or invited to, as we need to disable geo-filter for it.
    
    // TODO: refactor this request, moving in a separate method meetup creation
    [meetupAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *meetups, NSError* error)
    {
        int n = 0;
        for (NSDictionary *meetupData in meetups)
        {
            MeetupAnnotation *ann = [[MeetupAnnotation alloc] init];
            
            // TODO: temp
            Meetup* meetup = [[Meetup alloc] init];
            meetup.strSubject = [meetupData objectForKey:@"subject"];
            meetup.strId = [meetupData objectForKey:@"meetupId"];
            meetup.strOwnerId = [meetupData objectForKey:@"userFromId"];
            meetup.strOwnerName = [meetupData objectForKey:@"userFromName"];
            meetup.privacy = [[meetupData objectForKey:@"privacy"] integerValue];
            PFGeoPoint* loc = [meetupData objectForKey:@"location"];
            CLLocationCoordinate2D coord = { loc.latitude, loc.longitude };
            meetup.location = coord;
            
            // Private meetups
            if ( meetup.privacy == 2 )
                if ( FALSE )    // TODO: is in invitation list
                    continue;
            
            // 2ndO meetups (TODO: should be tested)
            if ( meetup.privacy == 1 )
            {
                Boolean bSkip = false;
                NSArray* friends = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
                if ( [friends containsObject:meetup.strOwnerId ] )
                    bSkip = true;
                friends = [[PFUser currentUser] objectForKey:@"fbFriends"];
                if ( [friends containsObject:meetup.strOwnerId ] )
                    bSkip = true;
                if ( bSkip )
                    continue;
            }
            
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
            ann.coordinate = meetup.location;
            ann.color = color;
            [ann setMeetup:meetup];
            
            [mapView addAnnotation:ann];
            n++;
            if ( n >= l )
                break;

        }
    }];
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
        region.span.longitudeDelta = 0.5f;
        region.span.latitudeDelta = 0.5f;
        [mapView setRegion:region animated:YES];
    }
    else
        [mapView setUserTrackingMode:MKUserTrackingModeFollow animated:TRUE];
        
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                               [[UIBarButtonItem alloc] initWithTitle:@"Profile" style:UIBarButtonItemStyleBordered target:self /*.viewDeckController*/ action:@selector(profileClicked)],
                                               [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(filterClicked)],
                                               nil];
    
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
            pinView.image = nil;
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

- (void)profileClicked{
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    [self.navigationController pushViewController:profileViewController animated:YES];
    //[self.navigationController setNavigationBarHidden:true animated:true];
}

- (void)filterClicked{
    FilterViewController *filterViewController = [[FilterViewController alloc] initWithNibName:@"FilterView" bundle:nil];
    [self.navigationController pushViewController:filterViewController animated:YES];
    //[self.navigationController setNavigationBarHidden:true animated:true];
}

@end
