/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiMapLookAroundViewProxy.h"
#import "TiMapLookAroundView.h"

@implementation TiMapLookAroundViewProxy

- (NSString *)apiName
{
  return @"Ti.Map.LookAroundView";
}

- (NSArray *)keySequence
{
  return @[
    @"navigationEnabled",
    @"showsRoadLabels",
    @"pointOfInterestFilter",
    @"badgePosition",
    @"snapshotSize",
    @"snapshotScale",
    @"snapshotInterfaceStyle",
    @"snapshotPointOfInterestFilter",
    @"coordinate",
    @"latitude",
    @"longitude"
  ];
}

- (NSNumber *)available
{
  if (![self viewAttached]) {
    return @(NO);
  }
  __block BOOL result = NO;
  TiThreadPerformOnMainThread(
      ^{
        result = [(TiMapLookAroundView *)self.view isLookAroundAvailable];
      },
      YES);
  return @(result);
}

- (NSNumber *)loading
{
  if (![self viewAttached]) {
    return @(NO);
  }
  __block BOOL result = NO;
  TiThreadPerformOnMainThread(
      ^{
        result = [(TiMapLookAroundView *)self.view isLookAroundLoading];
      },
      YES);
  return @(result);
}

- (void)reload:(id)unused
{
  ENSURE_UI_THREAD_0_ARGS;
  [(TiMapLookAroundView *)self.view reloadScene];
}

- (void)cancel:(id)unused
{
  if (![self viewAttached]) {
    return;
  }
  [(TiMapLookAroundView *)self.view cancelRequests];
}

- (void)takeSnapshot:(id)args
{
  ENSURE_UI_THREAD(takeSnapshot, args);
  [(TiMapLookAroundView *)self.view takeSnapshot:args];
}

@end
