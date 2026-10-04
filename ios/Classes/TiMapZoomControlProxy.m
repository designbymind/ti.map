/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 */

#import "TiMapZoomControlProxy.h"
#import "TiMapZoomControl.h"

@implementation TiMapZoomControlProxy

- (NSString *)apiName
{
  return @"Ti.Map.ZoomControl";
}

- (NSArray *)keySequence
{
  return @[
    @"mapView",
    @"minimumDistance",
    @"maximumDistance",
    @"relativeZoomEnabled",
    @"zoomRange",
    @"activationDelay",
    @"hitWidth",
    @"thumbStyle",
    @"thumbWidth",
    @"thumbCornerRadius",
    @"animationDuration",
    @"trackColor",
    @"thumbColor",
    @"trackWidth",
    @"thumbSize",
    @"trackOpacity",
    @"activeTrackOpacity",
    @"thumbOpacity",
    @"activeThumbOpacity",
    @"idleDelay",
    @"hapticsEnabled",
    @"hapticInterval",
    @"levelIndicators"
  ];
}

- (NSNumber *)progress
{
  if (![self viewAttached]) {
    return @(0);
  }
  __block CGFloat result = 0;
  TiThreadPerformOnMainThread(
      ^{
        result = [(TiMapZoomControl *)self.view zoomProgress];
      },
      YES);
  return @(result);
}

- (NSNumber *)distance
{
  if (![self viewAttached]) {
    return @(0);
  }
  __block CLLocationDistance result = 0;
  TiThreadPerformOnMainThread(
      ^{
        result = [(TiMapZoomControl *)self.view zoomDistance];
      },
      YES);
  return @(result);
}

- (void)setProgress:(id)args
{
  ENSURE_SINGLE_ARG(args, NSDictionary);
  ENSURE_UI_THREAD(setProgress, args);
  CGFloat value = [TiUtils floatValue:@"progress" properties:args def:0];
  BOOL animated = [TiUtils boolValue:@"animated" properties:args def:YES];
  NSTimeInterval duration = [TiUtils doubleValue:@"duration" properties:args def:240];
  [(TiMapZoomControl *)self.view setProgressAnimated:value animated:animated duration:duration];
}

- (void)sync:(id)unused
{
  ENSURE_UI_THREAD_0_ARGS;
  [(TiMapZoomControl *)self.view syncWithMap];
}

@end
