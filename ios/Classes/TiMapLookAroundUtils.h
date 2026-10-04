/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <MapKit/MapKit.h>

#if IS_SDK_IOS_16

FOUNDATION_EXPORT BOOL TiMapLookAroundCoordinateFromProperties(NSDictionary *properties, CLLocationCoordinate2D *coordinate);
FOUNDATION_EXPORT NSDictionary *TiMapLookAroundCoordinateDictionary(CLLocationCoordinate2D coordinate);
FOUNDATION_EXPORT MKPointOfInterestFilter *TiMapLookAroundPointOfInterestFilterFromValue(id value);
FOUNDATION_EXPORT MKLookAroundSnapshotOptions *TiMapLookAroundSnapshotOptionsFromProperties(NSDictionary *properties,
    CGSize defaultSize,
    CGFloat defaultScale,
    UIUserInterfaceStyle defaultInterfaceStyle,
    MKPointOfInterestFilter *defaultPointOfInterestFilter);

#endif
