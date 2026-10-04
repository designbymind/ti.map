/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiMapLookAroundView.h"

#if IS_SDK_IOS_16

#import "TiBlob.h"
#import "TiMapLookAroundUtils.h"
#import "TiMapLookAroundViewProxy.h"

@implementation TiMapLookAroundView

#pragma mark Internal

- (void)initializeState
{
  [super initializeState];
  coordinate = kCLLocationCoordinate2DInvalid;
  snapshotInterfaceStyle = UIUserInterfaceStyleUnspecified;
  self.backgroundColor = UIColor.clearColor;
  self.clipsToBounds = YES;
}

- (BOOL)interactionDefault
{
  return YES;
}

- (MKLookAroundViewController *)lookAroundViewController
{
  if (lookAroundViewController == nil) {
    lookAroundViewController = [[MKLookAroundViewController alloc] initWithNibName:nil bundle:nil];
    lookAroundViewController.delegate = self;
    lookAroundViewController.view.frame = self.bounds;
    lookAroundViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    lookAroundViewController.view.hidden = YES;
  }
  return lookAroundViewController;
}

- (void)attachLookAroundViewController
{
  // Scene requests can complete after a table row or its window is removed.
  // Only a view in a window has an owner to which we can attach the controller.
  if (self.window == nil) {
    return;
  }

  UIViewController *parentViewController = nil;
  for (UIResponder *responder = self.nextResponder; responder != nil; responder = responder.nextResponder) {
    if ([responder isKindOfClass:[UIViewController class]]) {
      parentViewController = (UIViewController *)responder;
      break;
    }
  }
  // Use the nearest owning controller, not the globally presented sheet or
  // navigation controller. UIKit requires both hierarchies to agree.
  if (parentViewController == nil || ![self isDescendantOfView:parentViewController.viewIfLoaded]) {
    return;
  }

  MKLookAroundViewController *controller = [self lookAroundViewController];
  if (controller.parentViewController == parentViewController) {
    return;
  }

  if (controller.parentViewController != nil) {
    [controller willMoveToParentViewController:nil];
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
  }

  [parentViewController addChildViewController:controller];
  controller.view.frame = self.bounds;
  [self addSubview:controller.view];
  [controller didMoveToParentViewController:parentViewController];
}

- (void)detachLookAroundViewController
{
  if (lookAroundViewController.parentViewController != nil) {
    [lookAroundViewController willMoveToParentViewController:nil];
    [lookAroundViewController.view removeFromSuperview];
    [lookAroundViewController removeFromParentViewController];
  }
}

- (void)didMoveToWindow
{
  [super didMoveToWindow];
  if (self.window != nil) {
    [self attachLookAroundViewController];
  } else {
    [self detachLookAroundViewController];
  }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
  // Remove the child while the old owner and view hierarchy still agree.
  if (newWindow != self.window) {
    [self detachLookAroundViewController];
  }
  [super willMoveToWindow:newWindow];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
  if (newSuperview != self.superview) {
    [self detachLookAroundViewController];
  }
  [super willMoveToSuperview:newSuperview];
}

- (void)didMoveToSuperview
{
  [super didMoveToSuperview];
  [self attachLookAroundViewController];
}

- (void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
  lookAroundViewController.view.frame = bounds;
  [super frameSizeChanged:frame bounds:bounds];
}

- (NSDictionary *)eventForSuccess:(BOOL)success available:(BOOL)isAvailable error:(NSError *)error fallbackMessage:(NSString *)fallbackMessage
{
  NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
    @"success" : @(success),
    @"available" : @(isAvailable)
  }];
  if (coordinateIsSet) {
    event[@"coordinate"] = TiMapLookAroundCoordinateDictionary(coordinate);
  }
  if (error != nil) {
    event[@"error"] = error.localizedDescription ?: @"Unable to load Look Around.";
    event[@"code"] = @(error.code);
  } else if (fallbackMessage != nil) {
    event[@"error"] = fallbackMessage;
  }
  return event;
}

- (void)fireLookAroundEvent:(NSString *)eventName object:(NSDictionary *)event
{
  TiMapLookAroundViewProxy *viewProxy = (TiMapLookAroundViewProxy *)self.proxy;
  if ([viewProxy _hasListeners:eventName]) {
    [viewProxy fireEvent:eventName withObject:event];
  }
}

- (void)clearScene
{
  available = NO;
  RELEASE_TO_NIL(scene);
  if (lookAroundViewController != nil) {
    lookAroundViewController.scene = nil;
    lookAroundViewController.view.hidden = YES;
  }
}

- (void)loadScene
{
  if (!coordinateIsSet) {
    return;
  }

  requestGeneration++;
  NSUInteger generation = requestGeneration;
  [sceneRequest cancel];
  RELEASE_TO_NIL(sceneRequest);
  [snapshotter cancel];
  RELEASE_TO_NIL(snapshotter);
  [self clearScene];

  if (![TiUtils isIOSVersionOrGreater:@"16.0"]) {
    loading = NO;
    [self fireLookAroundEvent:@"lookarounderror"
                       object:[self eventForSuccess:NO
                                          available:NO
                                              error:nil
                                    fallbackMessage:@"Look Around requires iOS 16 or later."]];
    return;
  }

  loading = YES;
  [self fireLookAroundEvent:@"lookaroundloadstart"
                     object:[self eventForSuccess:YES available:NO error:nil fallbackMessage:nil]];

  sceneRequest = [[MKLookAroundSceneRequest alloc] initWithCoordinate:coordinate];
  MKLookAroundSceneRequest *request = sceneRequest;
  [request getSceneWithCompletionHandler:^(MKLookAroundScene *_Nullable loadedScene, NSError *_Nullable error) {
    TiThreadPerformOnMainThread(
        ^{
          if (generation != requestGeneration || request != sceneRequest) {
            return;
          }

          loading = NO;
          RELEASE_TO_NIL(sceneRequest);

          if (error != nil) {
            [self clearScene];
            [self fireLookAroundEvent:@"lookarounderror"
                               object:[self eventForSuccess:NO available:NO error:error fallbackMessage:nil]];
            return;
          }

          if (loadedScene == nil) {
            [self clearScene];
            [self fireLookAroundEvent:@"lookaroundunavailable"
                               object:[self eventForSuccess:YES available:NO error:nil fallbackMessage:nil]];
            return;
          }

          RELEASE_TO_NIL(scene);
          scene = [loadedScene retain];
          available = YES;
          MKLookAroundViewController *controller = [self lookAroundViewController];
          controller.scene = scene;
          controller.view.hidden = NO;
          [self attachLookAroundViewController];
          [self fireLookAroundEvent:@"lookaroundload"
                             object:[self eventForSuccess:YES available:YES error:nil fallbackMessage:nil]];
        },
        NO);
  }];
}

- (void)reloadScene
{
  TiThreadPerformOnMainThread(
      ^{
        [self loadScene];
      },
      NO);
}

- (void)cancelRequests
{
  TiThreadPerformOnMainThread(
      ^{
        requestGeneration++;
        loading = NO;
        [sceneRequest cancel];
        RELEASE_TO_NIL(sceneRequest);
        [snapshotter cancel];
        RELEASE_TO_NIL(snapshotter);
      },
      NO);
}

- (BOOL)isLookAroundAvailable
{
  return available;
}

- (BOOL)isLookAroundLoading
{
  return loading;
}

#pragma mark Properties

- (void)setCoordinate_:(id)value
{
  if (value == nil || value == [NSNull null]) {
    coordinateIsSet = NO;
    latitudeIsSet = NO;
    longitudeIsSet = NO;
    coordinate = kCLLocationCoordinate2DInvalid;
    [self cancelRequests];
    [self clearScene];
    return;
  }

  CLLocationCoordinate2D newCoordinate;
  if (!TiMapLookAroundCoordinateFromProperties(@{ @"coordinate" : value }, &newCoordinate)) {
    [self fireLookAroundEvent:@"lookarounderror"
                       object:[self eventForSuccess:NO
                                          available:NO
                                              error:nil
                                    fallbackMessage:@"The Look Around coordinate is invalid."]];
    return;
  }

  coordinate = newCoordinate;
  coordinateIsSet = YES;
  latitudeIsSet = YES;
  longitudeIsSet = YES;
  [self loadScene];
}

- (void)setLatitude_:(id)value
{
  if (value == nil || value == [NSNull null]) {
    latitudeIsSet = NO;
    coordinateIsSet = NO;
    [self cancelRequests];
    [self clearScene];
    return;
  }

  coordinate.latitude = [TiUtils doubleValue:value];
  latitudeIsSet = YES;
  coordinateIsSet = latitudeIsSet && longitudeIsSet && CLLocationCoordinate2DIsValid(coordinate);
  if (coordinateIsSet) {
    [self loadScene];
  }
}

- (void)setLongitude_:(id)value
{
  if (value == nil || value == [NSNull null]) {
    longitudeIsSet = NO;
    coordinateIsSet = NO;
    [self cancelRequests];
    [self clearScene];
    return;
  }

  coordinate.longitude = [TiUtils doubleValue:value];
  longitudeIsSet = YES;
  coordinateIsSet = latitudeIsSet && longitudeIsSet && CLLocationCoordinate2DIsValid(coordinate);
  if (coordinateIsSet) {
    [self loadScene];
  }
}

- (void)setNavigationEnabled_:(id)value
{
  [self lookAroundViewController].navigationEnabled = [TiUtils boolValue:value def:YES];
}

- (void)setShowsRoadLabels_:(id)value
{
  [self lookAroundViewController].showsRoadLabels = [TiUtils boolValue:value def:YES];
}

- (void)setPointOfInterestFilter_:(id)value
{
  MKPointOfInterestFilter *newFilter = TiMapLookAroundPointOfInterestFilterFromValue(value);
  if (pointOfInterestFilter != newFilter) {
    RELEASE_TO_NIL(pointOfInterestFilter);
    pointOfInterestFilter = [newFilter retain];
  }
  [self lookAroundViewController].pointOfInterestFilter = pointOfInterestFilter;
}

- (void)setBadgePosition_:(id)value
{
  NSInteger position = [TiUtils intValue:value def:MKLookAroundBadgePositionTopLeading];
  if (position < MKLookAroundBadgePositionTopLeading || position > MKLookAroundBadgePositionBottomTrailing) {
    NSLog(@"[WARN] Ti.Map.LookAroundView badgePosition must be a LOOK_AROUND_BADGE_POSITION_* constant. Using top leading.");
    position = MKLookAroundBadgePositionTopLeading;
  }
  [self lookAroundViewController].badgePosition = (MKLookAroundBadgePosition)position;
}

- (void)setSnapshotSize_:(id)value
{
  if (value == nil || value == [NSNull null]) {
    snapshotSizeIsSet = NO;
    snapshotSize = CGSizeZero;
    return;
  }

  ENSURE_TYPE(value, NSDictionary);
  CGFloat width = [TiUtils floatValue:@"width" properties:value];
  CGFloat height = [TiUtils floatValue:@"height" properties:value];
  if (!isfinite(width) || !isfinite(height) || width <= 0 || height <= 0) {
    NSLog(@"[WARN] Ti.Map.LookAroundView snapshotSize requires positive width and height values.");
    return;
  }
  snapshotSize = CGSizeMake(MIN(width, 4096.0), MIN(height, 4096.0));
  snapshotSizeIsSet = YES;
}

- (void)setSnapshotScale_:(id)value
{
  if (value == nil || value == [NSNull null]) {
    snapshotScale = 0;
    return;
  }
  CGFloat newScale = [TiUtils floatValue:value];
  snapshotScale = isfinite(newScale) && newScale > 0 ? MIN(newScale, 4.0) : 0;
}

- (void)setSnapshotInterfaceStyle_:(id)value
{
  NSString *style = [[TiUtils stringValue:value] lowercaseString];
  if ([style isEqualToString:@"light"]) {
    snapshotInterfaceStyle = UIUserInterfaceStyleLight;
  } else if ([style isEqualToString:@"dark"]) {
    snapshotInterfaceStyle = UIUserInterfaceStyleDark;
  } else {
    snapshotInterfaceStyle = UIUserInterfaceStyleUnspecified;
  }
}

- (void)setSnapshotPointOfInterestFilter_:(id)value
{
  snapshotPointOfInterestFilterIsSet = value != nil && value != [NSNull null];
  MKPointOfInterestFilter *newFilter = TiMapLookAroundPointOfInterestFilterFromValue(value);
  if (snapshotPointOfInterestFilter != newFilter) {
    RELEASE_TO_NIL(snapshotPointOfInterestFilter);
    snapshotPointOfInterestFilter = [newFilter retain];
  }
}

#pragma mark Snapshot

- (void)callSnapshotCallback:(KrollCallback *)callback event:(NSDictionary *)event
{
  if ([callback isKindOfClass:[KrollCallback class]]) {
    [callback call:@[ event ] thisObject:self.proxy];
  }
}

- (void)takeSnapshot:(id)args
{
  NSDictionary *properties = nil;
  KrollCallback *callback = nil;
  KrollCallback *successCallback = nil;
  KrollCallback *errorCallback = nil;

  if ([args isKindOfClass:[NSArray class]]) {
    id firstArgument = [(NSArray *)args firstObject];
    if ([firstArgument isKindOfClass:[NSDictionary class]]) {
      properties = firstArgument;
    } else if ([firstArgument isKindOfClass:[KrollCallback class]]) {
      callback = firstArgument;
    }
  } else if ([args isKindOfClass:[NSDictionary class]]) {
    properties = args;
  } else if ([args isKindOfClass:[KrollCallback class]]) {
    callback = args;
  }

  properties = properties ?: @{};
  callback = callback ?: properties[@"callback"];
  successCallback = properties[@"success"];
  errorCallback = properties[@"error"];

  TiThreadPerformOnMainThread(
      ^{
        if (scene == nil || !available) {
          NSDictionary *event = [self eventForSuccess:NO
                                            available:NO
                                                error:nil
                                      fallbackMessage:@"No Look Around scene is currently available."];
          [self callSnapshotCallback:callback event:event];
          [self callSnapshotCallback:errorCallback event:event];
          return;
        }

        [snapshotter cancel];
        RELEASE_TO_NIL(snapshotter);

        CGSize defaultSize = snapshotSizeIsSet ? snapshotSize : self.bounds.size;
        if (defaultSize.width <= 0 || defaultSize.height <= 0) {
          defaultSize = CGSizeMake(256, 256);
        }
        CGFloat defaultScale = snapshotScale > 0 ? snapshotScale : UIScreen.mainScreen.scale;
        MKPointOfInterestFilter *defaultFilter = snapshotPointOfInterestFilterIsSet ? snapshotPointOfInterestFilter : pointOfInterestFilter;
        MKLookAroundSnapshotOptions *options = TiMapLookAroundSnapshotOptionsFromProperties(properties,
            defaultSize,
            defaultScale,
            snapshotInterfaceStyle,
            defaultFilter);

        snapshotter = [[MKLookAroundSnapshotter alloc] initWithScene:scene options:options];
        MKLookAroundSnapshotter *activeSnapshotter = snapshotter;
        [activeSnapshotter getSnapshotWithCompletionHandler:^(MKLookAroundSnapshot *_Nullable lookAroundSnapshot, NSError *_Nullable error) {
          TiThreadPerformOnMainThread(
              ^{
                if (activeSnapshotter != snapshotter) {
                  return;
                }
                RELEASE_TO_NIL(snapshotter);

                if (error != nil || lookAroundSnapshot == nil) {
                  NSDictionary *event = [self eventForSuccess:NO
                                                    available:YES
                                                        error:error
                                              fallbackMessage:@"Unable to create the Look Around snapshot."];
                  [self callSnapshotCallback:callback event:event];
                  [self callSnapshotCallback:errorCallback event:event];
                  return;
                }

                TiBlob *blob = [[[TiBlob alloc] initWithImage:lookAroundSnapshot.image] autorelease];
                [blob setMimeType:@"image/png" type:TiBlobTypeImage];
                NSDictionary *event = @{
                  @"success" : @(YES),
                  @"available" : @(YES),
                  @"image" : blob,
                  @"coordinate" : TiMapLookAroundCoordinateDictionary(coordinate)
                };
                [self callSnapshotCallback:callback event:event];
                [self callSnapshotCallback:successCallback event:event];
              },
              NO);
        }];
      },
      NO);
}

#pragma mark MKLookAroundViewControllerDelegate

- (void)lookAroundViewControllerWillUpdateScene:(MKLookAroundViewController *)viewController
{
  [self fireLookAroundEvent:@"lookaroundwillupdatescene"
                     object:[self eventForSuccess:YES available:available error:nil fallbackMessage:nil]];
}

- (void)lookAroundViewControllerDidUpdateScene:(MKLookAroundViewController *)viewController
{
  [self fireLookAroundEvent:@"lookaroundsceneupdated"
                     object:[self eventForSuccess:YES available:available error:nil fallbackMessage:nil]];
}

- (void)lookAroundViewControllerWillPresentFullScreen:(MKLookAroundViewController *)viewController
{
  [self fireLookAroundEvent:@"lookaroundwillopen"
                     object:[self eventForSuccess:YES available:available error:nil fallbackMessage:nil]];
}

- (void)lookAroundViewControllerDidPresentFullScreen:(MKLookAroundViewController *)viewController
{
  [self fireLookAroundEvent:@"lookaroundopen"
                     object:[self eventForSuccess:YES available:available error:nil fallbackMessage:nil]];
}

- (void)lookAroundViewControllerWillDismissFullScreen:(MKLookAroundViewController *)viewController
{
  [self fireLookAroundEvent:@"lookaroundwillclose"
                     object:[self eventForSuccess:YES available:available error:nil fallbackMessage:nil]];
}

- (void)lookAroundViewControllerDidDismissFullScreen:(MKLookAroundViewController *)viewController
{
  [self fireLookAroundEvent:@"lookaroundclose"
                     object:[self eventForSuccess:YES available:available error:nil fallbackMessage:nil]];
}

- (void)dealloc
{
  requestGeneration++;
  [sceneRequest cancel];
  [snapshotter cancel];
  [self detachLookAroundViewController];
  lookAroundViewController.delegate = nil;
  [lookAroundViewController.view removeFromSuperview];
  RELEASE_TO_NIL(sceneRequest);
  RELEASE_TO_NIL(snapshotter);
  RELEASE_TO_NIL(scene);
  RELEASE_TO_NIL(pointOfInterestFilter);
  RELEASE_TO_NIL(snapshotPointOfInterestFilter);
  RELEASE_TO_NIL(lookAroundViewController);
  [super dealloc];
}

@end

#else

@implementation TiMapLookAroundView
@end

#endif
