/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 */

#import "TiMapView.h"
#import <TitaniumKit/TiUIView.h>

@class TiMapViewProxy;

@interface TiMapZoomControl : TiUIView <TiMapZoomObserver> {
  TiMapViewProxy *mapViewProxy;
  UIView *trackView;
  UIView *thumbView;
  UILabel *indicatorLabel;
  UISelectionFeedbackGenerator *feedbackGenerator;
  NSTimer *activationTimer;
  NSArray *levelIndicators;
  UIColor *trackColor;
  UIColor *thumbColor;
  CLLocationDistance minimumDistance;
  CLLocationDistance maximumDistance;
  CGFloat trackWidth;
  CGFloat thumbSize;
  CGFloat thumbWidth;
  CGFloat thumbCornerRadius;
  CGFloat zoomRange;
  CGFloat hitWidth;
  NSTimeInterval animationDuration;
  NSTimeInterval activationDelay;
  BOOL barThumb;
  BOOL relativeZoomEnabled;
  BOOL activationPending;
  BOOL gestureIsRelative;
  BOOL appearanceExpanded;
  BOOL holdingThumbPosition;
  CGFloat touchProgress;
  CGFloat startTouchProgress;
  CGFloat gestureZoomRange;
  CLLocationDistance startDistance;
  CLLocationDistance gestureMinimumDistance;
  CLLocationDistance gestureMaximumDistance;
  UITouch *trackingTouch;
  CGPoint activationStartPoint;
  CGFloat trackOpacity;
  CGFloat activeTrackOpacity;
  CGFloat thumbOpacity;
  CGFloat activeThumbOpacity;
  NSTimeInterval idleDelay;
  CGFloat hapticInterval;
  NSInteger lastHapticStep;
  CGFloat progress;
  CLLocationDistance distance;
  BOOL hapticsEnabled;
  BOOL interacting;
}

@property (nonatomic, readonly) CGFloat zoomProgress;
@property (nonatomic, readonly) CLLocationDistance zoomDistance;

- (void)setProgressAnimated:(CGFloat)newProgress animated:(BOOL)animated duration:(NSTimeInterval)duration;
- (void)syncWithMap;

@end
