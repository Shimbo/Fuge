
//
//  
//    ___  _____   ______  __ _   _________ 
//   / _ \/ __/ | / / __ \/ /| | / / __/ _ \
//  / , _/ _/ | |/ / /_/ / /_| |/ / _// , _/
// /_/|_/___/ |___/\____/____/___/___/_/|_| 
//
//  Created by Bart Claessens. bart (at) revolver . be
//

#import "REVClusterMapView.h"
#import "REVClusterManager.h"

@interface REVClusterMapView (Private)
- (void) setup;
- (BOOL) mapViewDidZoom;
@end

@implementation REVClusterMapView{
    REVClusterManager *_manager;
}

@synthesize delegate;


- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setup];
    }
    return self;
}


- (void) setup
{
    annotationsCopy = [NSMutableArray arrayWithCapacity:10];
    super.delegate = self;
    
    zoomLevel = [self zoomLevelForMapRect:self.visibleMapRect
                  withMapViewSizeInPixels:self.frame.size];
}

- (NSUInteger)zoomLevelForMapRect:(MKMapRect)mRect withMapViewSizeInPixels:(CGSize)viewSizeInPixels
{
    NSUInteger zl = 20; // MAXIMUM_ZOOM is 20 with MapKit
    MKZoomScale zoomScale = mRect.size.width / viewSizeInPixels.width; //MKZoomScale is just a CGFloat typedef
    double zoomExponent = log2(zoomScale);
    zl = (NSUInteger)(20 - ceil(zoomExponent));
    return zl-1;
}



-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if( [delegate respondsToSelector:@selector(mapView:viewForOverlay:)] )
    {
        return [delegate mapView:mapView viewForOverlay:overlay];
    }
    return nil;
}
    
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if( [delegate respondsToSelector:@selector(mapView:viewForAnnotation:)] )
    {
        return [delegate mapView:mapView viewForAnnotation:annotation];
    } 
    return nil;
}


- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if( [delegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)] )
    {
        [delegate mapView:mapView regionWillChangeAnimated:animated];
    } 
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
    if( [delegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)] )
    {
        [delegate mapViewWillStartLoadingMap:mapView];
    }
}
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    if( [delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)] )
    {
        [delegate mapViewDidFinishLoadingMap:mapView];
    }
}
- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
    if( [delegate respondsToSelector:@selector(mapViewDidFailLoadingMap:withError:)] )
    {
        [delegate mapViewDidFailLoadingMap:mapView withError:error];
    }
}
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    if( [delegate respondsToSelector:@selector(mapView:didAddAnnotationViews:)] )
    {
        [delegate mapView:mapView didAddAnnotationViews:views];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if( [delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)] )
    {
        [delegate mapView:mapView annotationView:view calloutAccessoryControlTapped:control];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if( [delegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)] )
    {
        [delegate mapView:mapView didSelectAnnotationView:view];
    }
}
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if( [delegate respondsToSelector:@selector(mapView:didDeselectAnnotationView:)] )
    {
        [delegate mapView:mapView didDeselectAnnotationView:view];
    }
}

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    if( [delegate respondsToSelector:@selector(mapViewWillStartLocatingUser:)] )
    {
        [delegate mapViewWillStartLocatingUser:mapView];
    }
}
- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    if( [delegate respondsToSelector:@selector(mapViewDidStopLocatingUser:)] )
    {
        [delegate mapViewDidStopLocatingUser:mapView];
    }
}
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if( [delegate respondsToSelector:@selector(mapView:didUpdateUserLocation:)] )
    {
        [delegate mapView:mapView didUpdateUserLocation:userLocation];
    }
}
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    if( [delegate respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)] )
    {
        [delegate mapView:mapView didFailToLocateUserWithError:error];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState 
   fromOldState:(MKAnnotationViewDragState)oldState
{
    if( [delegate respondsToSelector:@selector(mapView:annotationView:didChangeDragState:fromOldState:)] )
    {
        [delegate mapView:mapView annotationView:view didChangeDragState:newState fromOldState:oldState];
    }
}

// Called after the provided overlay views have been added and positioned in the map.
- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews
{
    if( [delegate respondsToSelector:@selector(mapView:didAddOverlayViews:)] )
    {
        [delegate mapView:mapView didAddOverlayViews:overlayViews];
    }
}

- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    
    if( [self mapViewDidZoom] )
    {
        NSMutableArray *arr = [self.annotations mutableCopy];
        [arr removeObject:self.userLocation];
        [super removeAnnotations:arr];
        self.showsUserLocation = self.showsUserLocation;
        if( zoomLevel == 19 ){
            [super addAnnotations:annotationsCopy];
        }else{
            NSArray *add = [_manager clusterAnnotationsForZoomLevel:zoomLevel];
            [super addAnnotations:add];
        }
    }
    

    
    if( [delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)] )
    {
        [delegate mapView:mapView regionDidChangeAnimated:animated];
    }
}

- (BOOL) mapViewDidZoom
{
    NSUInteger nzl  = [self zoomLevelForMapRect:self.visibleMapRect
                         withMapViewSizeInPixels:self.frame.size];
    if( zoomLevel == nzl ){
        return NO;
    }
    zoomLevel = nzl;
    return YES;
}

-(void)removeAnnotations:(NSArray *)annotations{
    [NSException raise:@"REVClusterMapView: Use cleanUpAnnotations instead of removeAnnotations:" format:nil];
//    [annotationsCopy removeObjectsInArray:annotations];
//    [super removeAnnotations:annotations];
}

- (void) addAnnotations:(NSArray *)annotations
{
    _manager = [[REVClusterManager alloc]init];
    [annotationsCopy addObjectsFromArray:annotations];
    NSArray *add = [_manager clusterAnnotationsForMapView:self
                                           forAnnotations:annotationsCopy
                                                zoomLevel:zoomLevel];
    
    [super addAnnotations:add];
}

-(void)cleanUpAnnotations{
    [annotationsCopy removeAllObjects];
    NSMutableArray *arr = [self.annotations mutableCopy];
    [arr removeObject:self.userLocation];
    [super removeAnnotations:arr];
}



@end
