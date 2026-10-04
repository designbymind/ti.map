/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <MapKit/MapKit.h>
#import <TitaniumKit/TiUIView.h>

#if IS_SDK_IOS_16

@interface TiMapLookAroundView : TiUIView <MKLookAroundViewControllerDelegate> {
  MKLookAroundViewController *lookAroundViewController;
  MKLookAroundSceneRequest *sceneRequest;
  MKLookAroundSnapshotter *snapshotter;
  MKLookAroundScene *scene;
  MKPointOfInterestFilter *pointOfInterestFilter;
  MKPointOfInterestFilter *snapshotPointOfInterestFilter;
  CLLocationCoordinate2D coordinate;
  BOOL coordinateIsSet;
  BOOL latitudeIsSet;
  BOOL longitudeIsSet;
  BOOL available;
  BOOL loading;
  BOOL snapshotPointOfInterestFilterIsSet;
  CGSize snapshotSize;
  BOOL snapshotSizeIsSet;
  CGFloat snapshotScale;
  UIUserInterfaceStyle snapshotInterfaceStyle;
  NSUInteger requestGeneration;
}

- (BOOL)isLookAroundAvailable;
- (BOOL)isLookAroundLoading;
- (void)reloadScene;
- (void)cancelRequests;
- (void)takeSnapshot:(id)args;

@end

#else

@interface TiMapLookAroundView : TiUIView
@end

#endif
