/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiMapModule.h"
#import "TiApp.h"
#import "TiBlob.h"
#import "TiMapCameraProxy.h"
#import "TiMapConstants.h"
#import "TiMapLookAroundUtils.h"
#import "TiMapLookAroundViewProxy.h"
#import "TiMapUtils.h"
#import "TiMapViewProxy.h"
#import "TiMapZoomControlProxy.h"
#import <Contacts/CNPostalAddress.h>

@implementation TiMapModule

#pragma mark Internal

// this is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"fee93b77-8eb3-418c-8f04-013664c4af83";
}

// this is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"ti.map";
}

- (NSString *)apiName
{
  return @"Ti.Map";
}

- (void)dealloc
{
  _searchCompleter.delegate = nil;
  [_searchCompleter cancel];
  RELEASE_TO_NIL(_searchCompleter);
  for (NSDictionary *state in [_resolvedSearches allValues]) {
    [state[@"search"] cancel];
  }
  RELEASE_TO_NIL(_resolvedSearches);
  [super dealloc];
}

#pragma mark Public APIs

- (TiMapViewProxy *)createView:(id)args
{
  return [[[TiMapViewProxy alloc] _initWithPageContext:[self pageContext] args:args] autorelease];
}

- (TiMapCameraProxy *)createCamera:(id)args
{
  return [[[TiMapCameraProxy alloc] _initWithPageContext:[self pageContext] args:args] autorelease];
}

- (TiMapZoomControlProxy *)createZoomControl:(id)args
{
  return [[[TiMapZoomControlProxy alloc] _initWithPageContext:[self pageContext] args:args] autorelease];
}

#if IS_SDK_IOS_16

- (TiMapLookAroundViewProxy *)createLookAroundView:(id)args
{
  return [[[TiMapLookAroundViewProxy alloc] _initWithPageContext:[self pageContext] args:args] autorelease];
}

- (KrollCallback *)_lookAroundCallbackFromProperties:(NSDictionary *)properties required:(BOOL)required
{
  id callback = properties[@"callback"];
  if ([callback isKindOfClass:[KrollCallback class]]) {
    return callback;
  }
  if (required) {
    [self throwException:@"Missing required callback"
               subreason:@"Please provide callback as a Function"
                location:CODELOCATION];
  }
  return nil;
}

- (void)_callLookAroundCallback:(KrollCallback *)callback event:(NSDictionary *)event
{
  if (callback == nil) {
    return;
  }

  TiThreadPerformOnMainThread(
      ^{
        [callback call:@[ event ] thisObject:self];
      },
      NO);
}

- (NSDictionary *)_lookAroundFailureEventWithMessage:(NSString *)message error:(NSError *)error available:(BOOL)available
{
  NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
    @"success" : @(NO),
    @"available" : @(available),
    @"error" : error.localizedDescription ?: message ?
                                                     : @"Unable to load Look Around."
  }];
  if (error != nil) {
    event[@"code"] = @(error.code);
  }
  return event;
}

- (void)isLookAroundAvailable:(id)args
{
  ENSURE_SINGLE_ARG(args, NSDictionary);
  KrollCallback *callback = [self _lookAroundCallbackFromProperties:args required:YES];
  if (callback == nil) {
    return;
  }

  if (![TiUtils isIOSVersionOrGreater:@"16.0"]) {
    [self _callLookAroundCallback:callback
                            event:[self _lookAroundFailureEventWithMessage:@"Look Around requires iOS 16 or later."
                                                                     error:nil
                                                                 available:NO]];
    return;
  }

  CLLocationCoordinate2D coordinate;
  if (!TiMapLookAroundCoordinateFromProperties(args, &coordinate)) {
    [self _callLookAroundCallback:callback
                            event:[self _lookAroundFailureEventWithMessage:@"A valid latitude and longitude are required."
                                                                     error:nil
                                                                 available:NO]];
    return;
  }

  MKLookAroundSceneRequest *request = [[[MKLookAroundSceneRequest alloc] initWithCoordinate:coordinate] autorelease];
  [request getSceneWithCompletionHandler:^(MKLookAroundScene *_Nullable scene, NSError *_Nullable error) {
    (void)request;
    if (error != nil) {
      [self _callLookAroundCallback:callback
                              event:[self _lookAroundFailureEventWithMessage:nil error:error available:NO]];
      return;
    }

    [self _callLookAroundCallback:callback
                            event:@{
                              @"success" : @(YES),
                              @"available" : @(scene != nil),
                              @"coordinate" : TiMapLookAroundCoordinateDictionary(coordinate)
                            }];
  }];
}

- (void)getLookAroundImage:(id)args
{
  ENSURE_SINGLE_ARG(args, NSDictionary);
  KrollCallback *callback = [self _lookAroundCallbackFromProperties:args required:YES];
  if (callback == nil) {
    return;
  }

  if (![TiUtils isIOSVersionOrGreater:@"16.0"]) {
    [self _callLookAroundCallback:callback
                            event:[self _lookAroundFailureEventWithMessage:@"Look Around requires iOS 16 or later."
                                                                     error:nil
                                                                 available:NO]];
    return;
  }

  CLLocationCoordinate2D coordinate;
  if (!TiMapLookAroundCoordinateFromProperties(args, &coordinate)) {
    [self _callLookAroundCallback:callback
                            event:[self _lookAroundFailureEventWithMessage:@"A valid latitude and longitude are required."
                                                                     error:nil
                                                                 available:NO]];
    return;
  }

  MKLookAroundSceneRequest *request = [[[MKLookAroundSceneRequest alloc] initWithCoordinate:coordinate] autorelease];
  [request getSceneWithCompletionHandler:^(MKLookAroundScene *_Nullable scene, NSError *_Nullable error) {
    (void)request;
    TiThreadPerformOnMainThread(
        ^{
          if (error != nil) {
            [self _callLookAroundCallback:callback
                                    event:[self _lookAroundFailureEventWithMessage:nil error:error available:NO]];
            return;
          }

          if (scene == nil) {
            [self _callLookAroundCallback:callback
                                    event:@{
                                      @"success" : @(NO),
                                      @"available" : @(NO),
                                      @"error" : @"Look Around is not available at this coordinate.",
                                      @"coordinate" : TiMapLookAroundCoordinateDictionary(coordinate)
                                    }];
            return;
          }

          MKLookAroundSnapshotOptions *options = TiMapLookAroundSnapshotOptionsFromProperties(args,
              CGSizeMake(256, 256),
              UIScreen.mainScreen.scale,
              UIUserInterfaceStyleUnspecified,
              nil);
          MKLookAroundSnapshotter *lookAroundSnapshotter = [[[MKLookAroundSnapshotter alloc] initWithScene:scene options:options] autorelease];
          [lookAroundSnapshotter getSnapshotWithCompletionHandler:^(MKLookAroundSnapshot *_Nullable snapshot, NSError *_Nullable snapshotError) {
            (void)lookAroundSnapshotter;
            TiThreadPerformOnMainThread(
                ^{
                  if (snapshotError != nil || snapshot == nil) {
                    [self _callLookAroundCallback:callback
                                            event:[self _lookAroundFailureEventWithMessage:@"Unable to create the Look Around snapshot."
                                                                                     error:snapshotError
                                                                                 available:YES]];
                    return;
                  }

                  TiBlob *blob = [[[TiBlob alloc] initWithImage:snapshot.image] autorelease];
                  [blob setMimeType:@"image/png" type:TiBlobTypeImage];
                  [self _callLookAroundCallback:callback
                                          event:@{
                                            @"success" : @(YES),
                                            @"available" : @(YES),
                                            @"image" : blob,
                                            @"coordinate" : TiMapLookAroundCoordinateDictionary(coordinate)
                                          }];
                },
                NO);
          }];
        },
        NO);
  }];
}

- (void)openLookAroundDialog:(id)args
{
  ENSURE_SINGLE_ARG(args, NSDictionary);

  if (![TiUtils isIOSVersionOrGreater:@"16.0"]) {
    KrollCallback *callback = [self _lookAroundCallbackFromProperties:args required:NO];
    [self _callLookAroundCallback:callback
                            event:[self _lookAroundFailureEventWithMessage:@"Look Around requires iOS 16 or later."
                                                                     error:nil
                                                                 available:NO]];
    return;
  }

  KrollCallback *callback = [self _lookAroundCallbackFromProperties:args required:NO];
  CLLocationCoordinate2D coordinate;
  if (!TiMapLookAroundCoordinateFromProperties(args, &coordinate)) {
    [self _callLookAroundCallback:callback
                            event:[self _lookAroundFailureEventWithMessage:@"A valid latitude and longitude are required."
                                                                     error:nil
                                                                 available:NO]];
    return;
  }

  MKLookAroundSceneRequest *request = [[[MKLookAroundSceneRequest alloc] initWithCoordinate:coordinate] autorelease];

  [request getSceneWithCompletionHandler:^(MKLookAroundScene *_Nullable scene, NSError *_Nullable error) {
    (void)request;
    if (error != nil) {
      [self _callLookAroundCallback:callback
                              event:[self _lookAroundFailureEventWithMessage:nil error:error available:NO]];
      return;
    }

    if (scene == nil) {
      [self _callLookAroundCallback:callback
                              event:@{
                                @"success" : @(NO),
                                @"available" : @(NO),
                                @"error" : @"Look Around is not available at this coordinate.",
                                @"coordinate" : TiMapLookAroundCoordinateDictionary(coordinate)
                              }];
      return;
    }

    TiThreadPerformOnMainThread(
        ^{
          MKLookAroundViewController *vc = [[[MKLookAroundViewController alloc] initWithScene:scene] autorelease];
          vc.delegate = self;
          vc.navigationEnabled = [TiUtils boolValue:@"navigationEnabled" properties:args def:YES];
          vc.showsRoadLabels = [TiUtils boolValue:@"showsRoadLabels" properties:args def:YES];
          vc.pointOfInterestFilter = TiMapLookAroundPointOfInterestFilterFromValue(args[@"pointOfInterestFilter"]);

          NSInteger badgePosition = [TiUtils intValue:@"badgePosition" properties:args def:MKLookAroundBadgePositionTopLeading];
          if (badgePosition < MKLookAroundBadgePositionTopLeading || badgePosition > MKLookAroundBadgePositionBottomTrailing) {
            badgePosition = MKLookAroundBadgePositionTopLeading;
          }
          vc.badgePosition = (MKLookAroundBadgePosition)badgePosition;

          BOOL animated = [TiUtils boolValue:@"animated" properties:args def:YES];
          [[TiApp app] showModalController:vc animated:animated];
          [self _callLookAroundCallback:callback
                                  event:@{
                                    @"success" : @(YES),
                                    @"available" : @(YES),
                                    @"coordinate" : TiMapLookAroundCoordinateDictionary(coordinate)
                                  }];
        },
        NO);
  }];
}

- (void)lookAroundViewControllerDidDismissFullScreen:(MKLookAroundViewController *)viewController
{
  [self fireEvent:@"lookAroundClose"];
}

- (void)lookAroundViewControllerDidPresentFullScreen:(MKLookAroundViewController *)viewController
{
  [self fireEvent:@"lookAroundOpen"];
}

#endif

// --- BEGIN SEARCH --------------------------------------------------------------------------------------------------------------------------------------------

- (MKLocalSearchCompleter *)searchCompleter
{
  if (_searchCompleter == nil) {
    _searchCompleter = [[MKLocalSearchCompleter alloc] init];
    _searchCompleter.delegate = self;
  }

  return _searchCompleter;
}

// Resolved search owns its requests separately from the shared autocomplete completer.
- (NSMutableDictionary *)_dictionaryFromSearchMapItem:(MKMapItem *)mapItem
{
  NSMutableDictionary *place = [NSMutableDictionary dictionaryWithDictionary:[TiMapUtils dictionaryFromPlacemark:mapItem.placemark]];
  CNPostalAddress *postalAddress = mapItem.placemark.postalAddress;
  if (postalAddress != nil) {
    // Preserve the complete street, including house number and any unit/suite.
    place[@"postalAddress"] = @{
      @"street" : postalAddress.street ?: @"",
      @"city" : postalAddress.city ?: @"",
      @"state" : postalAddress.state ?: @"",
      @"postalCode" : postalAddress.postalCode ?: @"",
      @"country" : postalAddress.country ?: @"",
      @"countryCode" : postalAddress.ISOCountryCode ?: @"",
      @"ISOCountryCode" : postalAddress.ISOCountryCode ?: @""
    };
  }
  NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:@{
    @"identifier" : [NSNull null],
    @"alternateIdentifiers" : @[],
    @"name" : NULL_IF_NIL(mapItem.name),
    @"title" : mapItem.name ?: @"",
    @"subtitle" : place[@"address"] ?: @"",
    @"address" : place[@"address"] ?: @"",
    @"place" : place,
    @"latitude" : @(mapItem.placemark.coordinate.latitude),
    @"longitude" : @(mapItem.placemark.coordinate.longitude),
    @"pointOfInterestCategory" : NULL_IF_NIL(mapItem.pointOfInterestCategory),
    @"phoneNumber" : NULL_IF_NIL(mapItem.phoneNumber),
    @"timeZone" : NULL_IF_NIL(mapItem.timeZone.name),
    @"url" : NULL_IF_NIL(mapItem.url.absoluteString)
  }];

#if IS_SDK_IOS_18
  if (@available(iOS 18.0, *)) {
    result[@"identifier"] = NULL_IF_NIL(mapItem.identifier.identifierString);
    NSMutableArray *alternateIdentifiers = [NSMutableArray array];
    for (MKMapItemIdentifier *identifier in mapItem.alternateIdentifiers) {
      if (identifier.identifierString.length > 0) {
        [alternateIdentifiers addObject:identifier.identifierString];
      }
    }
    result[@"alternateIdentifiers"] = [alternateIdentifiers sortedArrayUsingSelector:@selector(compare:)];
  }
#endif

  return result;
}

- (void)cancelSearch:(id)args
{
  ENSURE_UI_THREAD(cancelSearch, args);
  ENSURE_SINGLE_ARG(args, NSDictionary);

  NSString *requestId = [TiUtils stringValue:args[@"requestId"]];
  if (requestId.length == 0) {
    [self throwException:@"Missing required requestId" subreason:@"Provide the resolved search requestId as a nonempty String" location:CODELOCATION];
    return;
  }

  MKLocalSearch *search = [[_resolvedSearches[requestId][@"search"] retain] autorelease];
  // Remove first so any completion after cancellation is ignored.
  [_resolvedSearches removeObjectForKey:requestId];
  [search cancel];
}

- (void)_searchResolvedValue:(NSString *)value options:(NSDictionary *)options
{
  NSString *requestId = [TiUtils stringValue:options[@"requestId"]];
  KrollCallback *callback = options[@"callback"];
  if (requestId.length == 0 || ![callback isKindOfClass:[KrollCallback class]]) {
    [self throwException:@"Missing resolved search options" subreason:@"Provide a nonempty requestId String and a callback Function" location:CODELOCATION];
    return;
  }

  MKLocalSearchRequest *request = [[[MKLocalSearchRequest alloc] init] autorelease];
  request.naturalLanguageQuery = value;
  NSDictionary *region = options[@"region"];
  if (region != nil) {
    if (![region isKindOfClass:[NSDictionary class]] || region[@"latitude"] == nil || region[@"longitude"] == nil || region[@"latitudeDelta"] == nil || region[@"longitudeDelta"] == nil) {
      [self throwException:@"Invalid search region" subreason:@"Provide latitude, longitude, latitudeDelta, and longitudeDelta" location:CODELOCATION];
      return;
    }
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([TiUtils doubleValue:region[@"latitude"]], [TiUtils doubleValue:region[@"longitude"]]);
    MKCoordinateSpan span = MKCoordinateSpanMake([TiUtils doubleValue:region[@"latitudeDelta"]], [TiUtils doubleValue:region[@"longitudeDelta"]]);
    if (!CLLocationCoordinate2DIsValid(coordinate) || !isfinite(span.latitudeDelta) || !isfinite(span.longitudeDelta) || span.latitudeDelta <= 0 || span.longitudeDelta <= 0 || span.latitudeDelta > 180 || span.longitudeDelta > 360) {
      [self throwException:@"Invalid search region" subreason:@"Provide valid coordinates and positive latitude/longitude deltas" location:CODELOCATION];
      return;
    }
    request.region = MKCoordinateRegionMake(coordinate, span);
  }

#if IS_SDK_IOS_18
  if (@available(iOS 18.0, *)) {
    NSString *priority = [TiUtils stringValue:options[@"regionPriority"]];
    if (priority && [priority caseInsensitiveCompare:@"required"] == NSOrderedSame) {
      request.regionPriority = MKLocalSearchRegionPriorityRequired;
    } else if (priority && [priority caseInsensitiveCompare:@"default"] != NSOrderedSame) {
      NSLog(@"[WARN] The \"regionPriority\" option must be either \"default\" or \"required\". Falling back to \"default\".");
    }
  } else if (options[@"regionPriority"]) {
    NSLog(@"[WARN] The \"regionPriority\" option requires iOS 18 or later. Using MapKit's default region behavior.");
  }
#endif

  if (options[@"resultTypes"] != nil) {
    NSArray *types = options[@"resultTypes"];
    if (![types isKindOfClass:[NSArray class]]) {
      [self throwException:@"Invalid resultTypes" subreason:@"Provide an Array of SEARCH_RESULT_TYPE_ADDRESS and/or SEARCH_RESULT_TYPE_POINT_OF_INTEREST" location:CODELOCATION];
      return;
    }
    MKLocalSearchResultType resultTypes = 0;
    for (id type in types) {
      if (![type isKindOfClass:[NSNumber class]] || ([type unsignedIntegerValue] != MKLocalSearchCompleterResultTypeAddress && [type unsignedIntegerValue] != MKLocalSearchCompleterResultTypePointOfInterest)) {
        [self throwException:@"Invalid resolved search result type" subreason:@"Resolved search supports ADDRESS and POINT_OF_INTEREST; QUERY is only supported by autocomplete" location:CODELOCATION];
        return;
      }
      if ([type unsignedIntegerValue] == MKLocalSearchCompleterResultTypeAddress) {
        resultTypes |= MKLocalSearchResultTypeAddress;
      } else {
        resultTypes |= MKLocalSearchResultTypePointOfInterest;
      }
    }
    if (@available(iOS 13.0, *)) {
      request.resultTypes = resultTypes;
    }
  }

  [self cancelSearch:@[ @{ @"requestId" : requestId } ]];
  if (_resolvedSearches == nil) {
    _resolvedSearches = [[NSMutableDictionary alloc] init];
  }
  MKLocalSearch *search = [[[MKLocalSearch alloc] initWithRequest:request] autorelease];
  NSObject *token = [[[NSObject alloc] init] autorelease];
  _resolvedSearches[requestId] = @{ @"search" : search, @"token" : token };

  [search startWithCompletionHandler:^(MKLocalSearchResponse *_Nullable response, NSError *_Nullable error) {
    TiThreadPerformOnMainThread(
        ^{
          if (_resolvedSearches[requestId][@"token"] != token) {
            return;
          }
          [_resolvedSearches removeObjectForKey:requestId];
          NSMutableArray *results = [NSMutableArray array];
          if (error == nil) {
            for (MKMapItem *mapItem in response.mapItems) {
              [results addObject:[self _dictionaryFromSearchMapItem:mapItem]];
            }
          }
          NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
            @"success" : @(error == nil),
            @"requestId" : requestId,
            @"results" : results
          }];
          if (error != nil) {
            event[@"error"] = error.localizedDescription ?: @"Unable to search for places.";
            event[@"code"] = @(error.code);
          }
          [callback call:@[ event ] thisObject:self];
        },
        NO);
  }];
}

- (void)search:(id)args
{
  ENSURE_UI_THREAD(search, args);

  ENSURE_ARG_COUNT(args, 1);
  NSString *value = [TiUtils stringValue:args[0]];

  // Require a search value
  if (!value) {
    [self throwException:@"Missing required search value" subreason:@"Please provide the value as a String" location:CODELOCATION];
    return;
  }

  NSDictionary *options = [args count] > 1 ? args[1] : nil;
  if (options != nil && ![options isKindOfClass:[NSDictionary class]]) {
    [self throwException:@"Invalid search options" subreason:@"Please provide options as an Object" location:CODELOCATION];
    return;
  }
  if ([[TiUtils stringValue:options[@"mode"]] isEqualToString:@"resolved"]) {
    [self _searchResolvedValue:value options:options];
    return;
  }

  MKLocalSearchCompleter *searchCompleter = [self searchCompleter];
#if IS_SDK_IOS_18
  if (@available(iOS 18.0, *)) {
    searchCompleter.regionPriority = MKLocalSearchRegionPriorityDefault;
  }
#endif

  // Pass additional options like search region
  if ([args count] > 1) {
    NSDictionary *options = (NSDictionary *)args[1];
    if (options == nil) {
      [self throwException:@"Options have to be called within an Object" subreason:@"Please provide the value as an Object" location:CODELOCATION];
    }

    // Handle search region
    if (options[@"region"]) {
      NSDictionary<NSString *, NSNumber *> *region = options[@"region"];
      CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([TiUtils doubleValue:region[@"latitude"]], [TiUtils doubleValue:region[@"longitude"]]);
      MKCoordinateSpan span = MKCoordinateSpanMake([TiUtils doubleValue:region[@"latitudeDelta"]], [TiUtils doubleValue:region[@"longitudeDelta"]]);

      if (CLLocationCoordinate2DIsValid(coordinate)) {
        [searchCompleter setRegion:MKCoordinateRegionMake(coordinate, span)];
      }
    }

#if IS_SDK_IOS_18
    if (@available(iOS 18.0, *)) {
      NSString *priority = [TiUtils stringValue:options[@"regionPriority"]];
      if (priority && [priority caseInsensitiveCompare:@"required"] == NSOrderedSame) {
        searchCompleter.regionPriority = MKLocalSearchRegionPriorityRequired;
      } else if (priority && [priority caseInsensitiveCompare:@"default"] != NSOrderedSame) {
        NSLog(@"[WARN] The \"regionPriority\" option must be either \"default\" or \"required\". Falling back to \"default\".");
      }
    } else if (options[@"regionPriority"]) {
      NSLog(@"[WARN] The \"regionPriority\" option requires iOS 18 or later. Using MapKit's default region behavior.");
    }
#endif

    // Handle filter types
    if ([TiUtils isIOSVersionOrGreater:@"13.0"] && options[@"resultTypes"]) {
      if (@available(iOS 13.0, *)) {
        searchCompleter.resultTypes = [TiMapUtils mappedResultTypes:options[@"resultTypes"]];
      } else {
        NSLog(@"[ERROR] The \"resultTypes\" options are only available on iOS 13+");
      }
    }
  }

  [searchCompleter setQueryFragment:value];
}

- (void)geocodeAddress:(id)args
{
  NSString *address = (NSString *)args[0];
  KrollCallback *callback = (KrollCallback *)args[1];

  CLGeocoder *geocoder = [[CLGeocoder alloc] init];
  [geocoder geocodeAddressString:address
               completionHandler:^(NSArray<CLPlacemark *> *_Nullable placemarks, NSError *_Nullable error) {
                 if (placemarks.count == 0 || error != nil) {
                   [callback call:@[ @{@"success" : @(NO),
                     @"error" : error.localizedDescription ?: @"Unknown error"} ]
                       thisObject:self];
                   return;
                 }

                 CLPlacemark *place = placemarks[0];

                 NSDictionary<NSString *, id> *proxyPlace = @{
                   @"name" : NULL_IF_NIL(place.name),
                   @"street" : NULL_IF_NIL([self formattedStreetNameFromPlace:place]),
                   @"thoroughfare" : NULL_IF_NIL(place.thoroughfare),
                   @"subThoroughfare" : NULL_IF_NIL(place.subThoroughfare),
                   @"postalCode" : NULL_IF_NIL(place.postalCode),
                   @"city" : NULL_IF_NIL(place.locality),
                   @"subLocality" : NULL_IF_NIL(place.subLocality),
                   @"country" : NULL_IF_NIL(place.country),
                   @"state" : NULL_IF_NIL(place.administrativeArea),
                   @"subAdministrativeArea" : NULL_IF_NIL(place.subAdministrativeArea),
                   @"latitude" : @(place.location.coordinate.latitude),
                   @"longitude" : @(place.location.coordinate.longitude),
                 };

                 [callback call:@[ @{@"success" : @(YES),
                   @"place" : proxyPlace} ]
                     thisObject:self];
               }];
}

- (NSString *)formattedStreetNameFromPlace:(CLPlacemark *)place
{
  if (place.thoroughfare == nil) {
    return nil;
  } else if (place.subThoroughfare == nil) {
    return place.thoroughfare;
  }

  return [NSString stringWithFormat:@"%@ %@", place.thoroughfare, place.subThoroughfare];
}

- (void)completer:(MKLocalSearchCompleter *)completer didFailWithError:(NSError *)error
{
  [self fireEvent:@"didUpdateResults" withObject:@{ @"results" : @[], @"error" : error.localizedDescription }];
}

- (void)completerDidUpdateResults:(MKLocalSearchCompleter *)completer
{
  NSMutableArray<NSDictionary<NSString *, id> *> *proxyResults = [NSMutableArray arrayWithCapacity:completer.results.count];

  [completer.results enumerateObjectsUsingBlock:^(MKLocalSearchCompletion *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    NSMutableArray<NSDictionary<NSString *, NSNumber *> *> *titleHighlightRanges = [NSMutableArray arrayWithCapacity:obj.titleHighlightRanges.count];
    NSMutableArray<NSDictionary<NSString *, NSNumber *> *> *subtitleHighlightRanges = [NSMutableArray arrayWithCapacity:obj.subtitleHighlightRanges.count];

    [obj.titleHighlightRanges enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
      [titleHighlightRanges addObject:@{@"offset" : @(obj.rangeValue.location),
        @"length" : @(obj.rangeValue.length)}];
    }];

    [obj.subtitleHighlightRanges enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
      [subtitleHighlightRanges addObject:@{@"offset" : @(obj.rangeValue.location),
        @"length" : @(obj.rangeValue.length)}];
    }];

    [proxyResults addObject:@{
      @"title" : obj.title,
      @"subtitle" : obj.subtitle,
      @"titleHighlightRanges" : titleHighlightRanges,
      @"subtitleHighlightRanges" : subtitleHighlightRanges
    }];
  }];

  [self fireEvent:@"didUpdateResults" withObject:@{ @"results" : proxyResults }];
}

/*
- (void)completerDidUpdateResults:(MKLocalSearchCompleter *)completer
{
  // Create an array to hold the filtered results.
  NSMutableArray<NSDictionary<NSString *, id> *> *filteredResults = [NSMutableArray array];

  // Create a dispatch group to coordinate multiple asynchronous MKLocalSearch requests.
  dispatch_group_t searchGroup = dispatch_group_create();

  // Loop through each autocomplete result.
  for (MKLocalSearchCompletion *completion in completer.results) {
    dispatch_group_enter(searchGroup);

    // Create an MKLocalSearchRequest for the current completion.
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] initWithCompletion:completion];
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];

    [search startWithCompletionHandler:^(MKLocalSearchResponse *_Nullable response, NSError *_Nullable error) {
      // If there is an error or no map items were returned, ignore this completion.
      if (error || response.mapItems.count == 0) {
        dispatch_group_leave(searchGroup);
        return;
      }

      // Grab the first map item from the results.
      MKMapItem *mapItem = response.mapItems.firstObject;
      CLLocationCoordinate2D coordinate = mapItem.placemark.coordinate;

      // Check if we have valid coordinates. If not, omit this result.
      if (CLLocationCoordinate2DIsValid(coordinate)) {
        // Build highlight ranges arrays for the title and subtitle.
        NSMutableArray<NSDictionary<NSString *, NSNumber *> *> *titleHighlightRanges = [NSMutableArray array];
        NSMutableArray<NSDictionary<NSString *, NSNumber *> *> *subtitleHighlightRanges = [NSMutableArray array];

        for (NSValue *rangeValue in completion.titleHighlightRanges) {
          [titleHighlightRanges addObject:@{
            @"offset" : @(rangeValue.rangeValue.location),
            @"length" : @(rangeValue.rangeValue.length)
          }];
        }

        for (NSValue *rangeValue in completion.subtitleHighlightRanges) {
          [subtitleHighlightRanges addObject:@{
            @"offset" : @(rangeValue.rangeValue.location),
            @"length" : @(rangeValue.rangeValue.length)
          }];
        }

        // Create a dictionary for this result.
        NSDictionary *result = @{
          @"title" : completion.title,
          @"subtitle" : completion.subtitle,
          @"latitude" : @(coordinate.latitude),
          @"longitude" : @(coordinate.longitude),
          @"titleHighlightRanges" : titleHighlightRanges,
          @"subtitleHighlightRanges" : subtitleHighlightRanges
        };

        // Synchronize access to the filteredResults array
        @synchronized(filteredResults) {
          [filteredResults addObject:result];
        }
      }

      // Leave the dispatch group when this search is complete.
      dispatch_group_leave(searchGroup);
    }];
  }

  // Once all searches have completed, fire the event with the filtered results.
  dispatch_group_notify(searchGroup, dispatch_get_main_queue(), ^{
    [self fireEvent:@"didUpdateResults" withObject:@{ @"results" : filteredResults }];
  });
}
*/
// --- Begin Custom Code from ChatGPT --------------------------------------------------------------------------------------------------------------------------
- (void)searchForCompletionResult:(id)args
{
  ENSURE_UI_THREAD(searchForCompletionResult, args);
  ENSURE_SINGLE_ARG(args, NSDictionary);

  // Expecting:
  // {
  //   "index": <NSNumber: index in self.searchCompleter.results>,
  //   "callback": <KrollCallback>
  // }
  NSNumber *indexNumber = args[@"index"];
  KrollCallback *callback = args[@"callback"];

  if (!indexNumber || !callback) {
    NSLog(@"[ERROR] searchForCompletionResult :: Missing 'index' or 'callback' parameter!");
    return;
  }

  if (@available(iOS 16.0, *)) {

    NSInteger index = [indexNumber integerValue];
    if (index < 0 || index >= [self.searchCompleter.results count]) {
      [callback call:@[ @{
        @"success" : @(NO),
        @"error" : @"searchForCompletionResult :: Index out of range"
      } ]
          thisObject:self];
      return;
    }

    // Get the user-selected search completer result
    MKLocalSearchCompletion *completion = self.searchCompleter.results[index];

    // Create the MKLocalSearchRequest from the completion
    MKLocalSearchRequest *request = [[[MKLocalSearchRequest alloc] initWithCompletion:completion] autorelease];

    // Perform the actual search
    MKLocalSearch *search = [[[MKLocalSearch alloc] initWithRequest:request] autorelease];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *_Nullable response, NSError *_Nullable error) {
      if (error != nil || response.mapItems.count == 0) {
        [callback call:@[ @{
          @"success" : @(NO),
          @"error" : error.localizedDescription ?: @"No results found"
        } ]
            thisObject:self];
        return;
      }

      // For simplicity, just take the first map item from the results
      MKMapItem *mapItem = response.mapItems.firstObject;

      // Share the resolved-search fields; Place IDs require iOS 18 or later.
      NSMutableDictionary *resultDict = [self _dictionaryFromSearchMapItem:mapItem];
      resultDict[@"success"] = @(YES);

      // Pass back the result in the callback
      [callback call:@[ resultDict ] thisObject:self];
    }];

  } else {
    [callback call:@[ @{
      @"success" : @(NO),
      @"error" : @"searchForCompletionResult requires iOS 16 or later."
    } ]
        thisObject:self];
  }
}
// --- End Custom Code from ChatGPT ----------------------------------------------------------------------------------------------------------------------------

// --- END SEARCH ----------------------------------------------------------------------------------------------------------------------------------------------

MAKE_SYSTEM_PROP(STANDARD_TYPE, MKMapTypeStandard);
MAKE_SYSTEM_PROP(NORMAL_TYPE, MKMapTypeStandard); // For parity with Android
MAKE_SYSTEM_PROP(SATELLITE_TYPE, MKMapTypeSatellite);
MAKE_SYSTEM_PROP(HYBRID_TYPE, MKMapTypeHybrid);
MAKE_SYSTEM_PROP(HYBRID_FLYOVER_TYPE, MKMapTypeHybridFlyover);
MAKE_SYSTEM_PROP(SATELLITE_FLYOVER_TYPE, MKMapTypeSatelliteFlyover);
MAKE_SYSTEM_PROP(MUTED_STANDARD_TYPE, MKMapTypeMutedStandard);
MAKE_SYSTEM_PROP(ANNOTATION_RED, TiMapAnnotationPinColorRed);
MAKE_SYSTEM_PROP(ANNOTATION_GREEN, TiMapAnnotationPinColorGreen);
MAKE_SYSTEM_PROP(ANNOTATION_PURPLE, TiMapAnnotationPinColorPurple);
MAKE_SYSTEM_PROP(ANNOTATION_AZURE, TiMapAnnotationPinColorAzure);
MAKE_SYSTEM_PROP(ANNOTATION_BLUE, TiMapAnnotationPinColorBlue);
MAKE_SYSTEM_PROP(ANNOTATION_CYAN, TiMapAnnotationPinColorCyan);
MAKE_SYSTEM_PROP(ANNOTATION_MAGENTA, TiMapAnnotationPinColorMagenta);
MAKE_SYSTEM_PROP(ANNOTATION_ORANGE, TiMapAnnotationPinColorOrange);
MAKE_SYSTEM_PROP(ANNOTATION_ROSE, TiMapAnnotationPinColorRose);
MAKE_SYSTEM_PROP(ANNOTATION_VIOLET, TiMapAnnotationPinColorViolet);
MAKE_SYSTEM_PROP(ANNOTATION_YELLOW, TiMapAnnotationPinColorYellow);

MAKE_SYSTEM_PROP(ANNOTATION_DRAG_STATE_NONE, MKAnnotationViewDragStateNone);
MAKE_SYSTEM_PROP(ANNOTATION_DRAG_STATE_START, MKAnnotationViewDragStateStarting);
MAKE_SYSTEM_PROP(ANNOTATION_DRAG_STATE_DRAG, MKAnnotationViewDragStateDragging);
MAKE_SYSTEM_PROP(ANNOTATION_DRAG_STATE_CANCEL, MKAnnotationViewDragStateCanceling);
MAKE_SYSTEM_PROP(ANNOTATION_DRAG_STATE_END, MKAnnotationViewDragStateEnding);

MAKE_SYSTEM_PROP(OVERLAY_LEVEL_ABOVE_LABELS, MKOverlayLevelAboveLabels);
MAKE_SYSTEM_PROP(OVERLAY_LEVEL_ABOVE_ROADS, MKOverlayLevelAboveRoads);

MAKE_SYSTEM_PROP(POLYLINE_PATTERN_DASHED, TiMapOverlyPatternTypeDashed);
MAKE_SYSTEM_PROP(POLYLINE_PATTERN_DOTTED, TiMapOverlyPatternTypeDotted);

MAKE_SYSTEM_PROP(FEATURE_VISIBILITY_ADAPTIVE, MKFeatureVisibilityAdaptive);
MAKE_SYSTEM_PROP(FEATURE_VISIBILITY_HIDDEN, MKFeatureVisibilityHidden);
MAKE_SYSTEM_PROP(FEATURE_VISIBILITY_VISIBLE, MKFeatureVisibilityVisible);

MAKE_SYSTEM_PROP(ANNOTATION_VIEW_COLLISION_MODE_RECTANGLE, MKAnnotationViewCollisionModeRectangle);
MAKE_SYSTEM_PROP(ANNOTATION_VIEW_COLLISION_MODE_CIRCLE, MKAnnotationViewCollisionModeCircle);

MAKE_SYSTEM_PROP_DBL(FEATURE_DISPLAY_PRIORITY_REQUIRED, MKFeatureDisplayPriorityRequired);
MAKE_SYSTEM_PROP_DBL(FEATURE_DISPLAY_PRIORITY_DEFAULT_HIGH, MKFeatureDisplayPriorityDefaultHigh);
MAKE_SYSTEM_PROP_DBL(FEATURE_DISPLAY_PRIORITY_DEFAULT_LOW, MKFeatureDisplayPriorityDefaultLow);

#if IS_SDK_IOS_16
MAKE_SYSTEM_PROP(FEATURE_TERRITORIES, MKMapFeatureOptionTerritories);
MAKE_SYSTEM_PROP(FEATURE_PHYSICAL_FEATURES, MKMapFeatureOptionPhysicalFeatures);
// MAKE_SYSTEM_PROP(FEATURE_TYPE_POINT_OF_INTEREST, MKMapFeatureOptionPointsOfInterest);
MAKE_SYSTEM_PROP_DEPRECATED_REPLACED(FEATURE_TYPE_POINT_OF_INTEREST, MKMapFeatureOptionPointsOfInterest, @"Map.FEATURE_TYPE_POINT_OF_INTEREST", @"12.3.0", @"Map.FEATURE_POINT_OF_INTEREST");
MAKE_SYSTEM_PROP(FEATURE_POINT_OF_INTEREST, MKMapFeatureOptionPointsOfInterest);
MAKE_SYSTEM_PROP(LOOK_AROUND_BADGE_POSITION_TOP_LEADING, MKLookAroundBadgePositionTopLeading);
MAKE_SYSTEM_PROP(LOOK_AROUND_BADGE_POSITION_TOP_TRAILING, MKLookAroundBadgePositionTopTrailing);
MAKE_SYSTEM_PROP(LOOK_AROUND_BADGE_POSITION_BOTTOM_TRAILING, MKLookAroundBadgePositionBottomTrailing);
#endif

MAKE_SYSTEM_PROP(SEARCH_RESULT_TYPE_ADDRESS, MKLocalSearchCompleterResultTypeAddress); // SEARCH
MAKE_SYSTEM_PROP(SEARCH_RESULT_TYPE_POINT_OF_INTEREST, MKLocalSearchCompleterResultTypePointOfInterest); // SEARCH
MAKE_SYSTEM_PROP(SEARCH_RESULT_TYPE_QUERY, MKLocalSearchCompleterResultTypeQuery); // SEARCH

@end
