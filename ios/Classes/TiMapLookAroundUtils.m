/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiMapLookAroundUtils.h"

#if IS_SDK_IOS_16

#import <TitaniumKit/TiUtils.h>

static NSArray *TiMapLookAroundCategoriesFromValue(id value)
{
  if (![value isKindOfClass:[NSArray class]]) {
    return nil;
  }

  NSMutableArray *categories = [NSMutableArray array];
  for (id category in (NSArray *)value) {
    if ([category isKindOfClass:[NSString class]] && [(NSString *)category length] > 0) {
      [categories addObject:category];
    }
  }
  return categories;
}

BOOL TiMapLookAroundCoordinateFromProperties(NSDictionary *properties, CLLocationCoordinate2D *coordinate)
{
  if (![properties isKindOfClass:[NSDictionary class]] || coordinate == NULL) {
    return NO;
  }

  NSDictionary *coordinateProperties = properties;
  id nestedCoordinate = properties[@"coordinate"];
  if ([nestedCoordinate isKindOfClass:[NSDictionary class]]) {
    coordinateProperties = nestedCoordinate;
  }

  id latitude = coordinateProperties[@"latitude"];
  id longitude = coordinateProperties[@"longitude"];
  if (latitude == nil || longitude == nil || latitude == [NSNull null] || longitude == [NSNull null]) {
    return NO;
  }

  CLLocationDegrees latitudeValue = [TiUtils doubleValue:latitude];
  CLLocationDegrees longitudeValue = [TiUtils doubleValue:longitude];
  CLLocationCoordinate2D result = CLLocationCoordinate2DMake(latitudeValue, longitudeValue);
  if (!isfinite(latitudeValue) || !isfinite(longitudeValue) || !CLLocationCoordinate2DIsValid(result)) {
    return NO;
  }

  *coordinate = result;
  return YES;
}

NSDictionary *TiMapLookAroundCoordinateDictionary(CLLocationCoordinate2D coordinate)
{
  return @{
    @"latitude" : @(coordinate.latitude),
    @"longitude" : @(coordinate.longitude)
  };
}

MKPointOfInterestFilter *TiMapLookAroundPointOfInterestFilterFromValue(id value)
{
  if (value == nil || value == [NSNull null]) {
    return nil;
  }

  if ([value isKindOfClass:[NSNumber class]]) {
    return [TiUtils boolValue:value] ? MKPointOfInterestFilter.filterIncludingAllCategories : MKPointOfInterestFilter.filterExcludingAllCategories;
  }

  if ([value isKindOfClass:[NSArray class]]) {
    return [[[MKPointOfInterestFilter alloc] initIncludingCategories:TiMapLookAroundCategoriesFromValue(value) ?: @[]] autorelease];
  }

  if (![value isKindOfClass:[NSDictionary class]]) {
    return nil;
  }

  NSDictionary *properties = (NSDictionary *)value;
  NSArray *includedCategories = TiMapLookAroundCategoriesFromValue(properties[@"includedCategories"] ?: properties[@"include"]);
  if (includedCategories != nil) {
    return [[[MKPointOfInterestFilter alloc] initIncludingCategories:includedCategories] autorelease];
  }

  NSArray *excludedCategories = TiMapLookAroundCategoriesFromValue(properties[@"excludedCategories"] ?: properties[@"exclude"]);
  if (excludedCategories != nil) {
    return [[[MKPointOfInterestFilter alloc] initExcludingCategories:excludedCategories] autorelease];
  }

  NSString *mode = [[TiUtils stringValue:properties[@"mode"]] lowercaseString];
  if ([mode isEqualToString:@"all"] || [mode isEqualToString:@"includeall"]) {
    return MKPointOfInterestFilter.filterIncludingAllCategories;
  }
  if ([mode isEqualToString:@"none"] || [mode isEqualToString:@"excludeall"]) {
    return MKPointOfInterestFilter.filterExcludingAllCategories;
  }

  return nil;
}

MKLookAroundSnapshotOptions *TiMapLookAroundSnapshotOptionsFromProperties(NSDictionary *properties,
    CGSize defaultSize,
    CGFloat defaultScale,
    UIUserInterfaceStyle defaultInterfaceStyle,
    MKPointOfInterestFilter *defaultPointOfInterestFilter)
{
  MKLookAroundSnapshotOptions *options = [[[MKLookAroundSnapshotOptions alloc] init] autorelease];

  CGSize size = defaultSize;
  id sizeValue = properties[@"size"] ?: properties[@"snapshotSize"];
  if ([sizeValue isKindOfClass:[NSDictionary class]]) {
    CGFloat width = [TiUtils floatValue:@"width" properties:sizeValue def:size.width];
    CGFloat height = [TiUtils floatValue:@"height" properties:sizeValue def:size.height];
    if (isfinite(width) && isfinite(height) && width > 0 && height > 0) {
      size = CGSizeMake(MIN(width, 4096.0), MIN(height, 4096.0));
    }
  }
  if (size.width > 0 && size.height > 0) {
    options.size = size;
  }

  id pointOfInterestFilterValue = properties[@"pointOfInterestFilter"] ?: properties[@"snapshotPointOfInterestFilter"];
  MKPointOfInterestFilter *pointOfInterestFilter = pointOfInterestFilterValue != nil ? TiMapLookAroundPointOfInterestFilterFromValue(pointOfInterestFilterValue) : defaultPointOfInterestFilter;
  options.pointOfInterestFilter = pointOfInterestFilter;

  CGFloat scale = defaultScale;
  id scaleValue = properties[@"scale"] ?: properties[@"snapshotScale"];
  if (scaleValue != nil && scaleValue != [NSNull null]) {
    CGFloat requestedScale = [TiUtils floatValue:scaleValue];
    if (isfinite(requestedScale) && requestedScale > 0) {
      scale = MIN(requestedScale, 4.0);
    }
  }

  UIUserInterfaceStyle interfaceStyle = defaultInterfaceStyle;
  NSString *interfaceStyleValue = [[TiUtils stringValue:(properties[@"interfaceStyle"] ?: properties[@"snapshotInterfaceStyle"])] lowercaseString];
  if ([interfaceStyleValue isEqualToString:@"light"]) {
    interfaceStyle = UIUserInterfaceStyleLight;
  } else if ([interfaceStyleValue isEqualToString:@"dark"]) {
    interfaceStyle = UIUserInterfaceStyleDark;
  } else if ([interfaceStyleValue isEqualToString:@"unspecified"] || [interfaceStyleValue isEqualToString:@"system"]) {
    interfaceStyle = UIUserInterfaceStyleUnspecified;
  }

  NSMutableArray *traits = [NSMutableArray array];
  if (scale > 0) {
    [traits addObject:[UITraitCollection traitCollectionWithDisplayScale:scale]];
  }
  if (interfaceStyle != UIUserInterfaceStyleUnspecified) {
    [traits addObject:[UITraitCollection traitCollectionWithUserInterfaceStyle:interfaceStyle]];
  }
  if ([traits count] > 0) {
    options.traitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:traits];
  }

  return options;
}

#endif
