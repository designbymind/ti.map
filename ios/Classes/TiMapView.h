/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "GeoJSONSerialization.h"
#import "TiMKOverlayPathUniversal.h"
#import "TiMapCameraProxy.h"
#import "WildcardGestureRecognizer.h"
#import <MapKit/MapKit.h>
#import <TitaniumKit/TiBase.h>
#import <TitaniumKit/TiUIView.h>

@class TiMapAnnotationProxy;
@class TiMapView;

@protocol TiMapZoomObserver <NSObject>
- (void)mapView:(TiMapView *)mapView zoomDistanceDidChange:(CLLocationDistance)distance;
@end

@protocol TiMapAnnotation
@required
- (NSString *)lastHitName;
@end

@interface TiMapView : TiUIView <MKMapViewDelegate, CLLocationManagerDelegate> {
  MKMapView *map;
  BOOL regionFits;
  BOOL animate;
  BOOL loaded;
  BOOL ignoreClicks;
  BOOL ignoreRegionChanged;
  BOOL forceRender;
  MKCoordinateRegion region;
  NSMutableArray *geoJSONProxies;
  NSMutableArray *polygonProxies;
  NSMutableArray *circleProxies;
  NSMutableArray *polylineProxies;
  NSMutableArray *imageOverlayProxies;
  NSMutableDictionary *clusterAnnotations;

  // selected annotation
  MKAnnotationView<TiMapAnnotation> *selectedAnnotation;

  // dictionary for object tracking and association
  CFMutableDictionaryRef mapObjects2View; // MKOverlay Object -> MKOverlay Object's renderer

  // Location manager needed for iOS 8 permissions
  CLLocationManager *locationManager;
  KrollCallback *cameraAnimationCallback;

  // Optional native compass with custom positioning.
  MKCompassButton *compassButton;
  BOOL compassPositionConfigured;
  BOOL compassHasTop;
  BOOL compassHasLeft;
  BOOL compassHasBottom;
  BOOL compassHasRight;
  CGFloat compassTop;
  CGFloat compassLeft;
  CGFloat compassBottom;
  CGFloat compassRight;

  // Display-synchronized zoom state shared by buttons and zoom controls.
  CADisplayLink *zoomDisplayLink;
  NSHashTable *zoomObservers;
  CLLocationDistance zoomStartDistance;
  CLLocationDistance zoomTargetDistance;
  CLLocationDistance zoomMinimumDistance;
  CLLocationDistance zoomMaximumDistance;
  CFTimeInterval zoomStartTime;
  NSTimeInterval zoomDuration;
  BOOL zoomIsInteractive;
  BOOL applyingProgrammaticZoom;
}

@property (nonatomic, readonly) CLLocationDegrees longitudeDelta;
@property (nonatomic, readonly) CLLocationDegrees latitudeDelta;
@property (nonatomic, readonly) NSArray *customAnnotations;

#pragma mark Private APIs

- (TiMapAnnotationProxy *)annotationFromArg:(id)arg;
- (NSArray *)annotationsFromArgs:(id)value;
- (NSArray *)annotationsFromGeoJSON:(id)value;
- (MKMapView *)map;
- (TiMapCameraProxy *)camera;

#pragma mark Public APIs

- (void)animateCamera:(id)args;
- (void)showAnnotations:(id)args;
- (void)showAllAnnotations:(id)value;
- (void)addAnnotation:(id)args;
- (void)addAnnotations:(id)args;
- (void)setAnnotations_:(id)value;
- (void)removeAnnotation:(id)args;
- (void)removeAnnotations:(id)args;
- (void)removeAllAnnotations:(id)args;
- (void)removeAllGeoJSON:(id)args;
- (void)selectAnnotation:(id)args;
- (void)deselectAnnotation:(id)args;
- (void)selectUserLocationAnnotation:(id)args;
- (void)deselectUserLocationAnnotation:(id)args;
- (void)zoom:(id)args;
- (void)zoomBy:(id)args;
- (void)zoomTo:(id)args;
- (CLLocationDistance)cameraDistance;
- (void)beginInteractiveZoomWithMinimumDistance:(CLLocationDistance)minimumDistance maximumDistance:(CLLocationDistance)maximumDistance;
- (void)updateInteractiveZoomToDistance:(CLLocationDistance)distance;
- (void)endInteractiveZoom;
- (void)addZoomObserver:(id<TiMapZoomObserver>)observer;
- (void)removeZoomObserver:(id<TiMapZoomObserver>)observer;
- (void)addRoute:(id)args;
- (void)removeRoute:(id)args;
- (void)addPolygon:(id)args;
- (void)addPolygons:(id)args;
- (void)removePolygon:(id)args;
- (void)removePolygon:(id)args remove:(BOOL)r;
- (void)removeAllPolygons;
- (void)addCircle:(id)args;
- (void)addCircles:(id)args;
- (void)removeCircle:(id)args;
- (void)removeCircle:(id)args remove:(BOOL)r;
- (void)removeAllCircles;
- (void)addPolyline:(id)args;
- (void)addPolylines:(id)args;
- (void)removePolyline:(id)args;
- (void)removePolyline:(id)args remove:(BOOL)r;
- (void)removeAllPolylines;
- (void)addImageOverlay:(id)arg;
- (void)addImageOverlays:(id)args;
- (void)removeImageOverlay:(id)arg;
- (void)removeAllImageOverlays;

- (void)firePinChangeDragState:(MKAnnotationView *)pinview newState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState;
- (void)setClusterAnnotation:(TiMapAnnotationProxy *)annotation forMembers:(NSArray<TiMapAnnotationProxy *> *)members;
- (void)animateAnnotation:(TiMapAnnotationProxy *)newAnnotation withLocation:(CLLocationCoordinate2D)newLocation;
- (void)setLocation:(id)location;
- (NSNumber *)containsCoordinate:(id)args;

#pragma mark Utils
- (void)addOverlay:(MKPolyline *)polyline level:(MKOverlayLevel)level;

#pragma mark Framework
- (void)refreshAnnotation:(TiMapAnnotationProxy *)proxy readd:(BOOL)yn;
- (void)fireClickEvent:(MKAnnotationView *)pinview source:(NSString *)source deselected:(BOOL)deselected;
- (void)refreshCoordinateChanges:(TiMapAnnotationProxy *)proxy afterRemove:(void (^)(void))callBack;

@end
