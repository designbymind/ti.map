/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 */

#import "TiMapZoomControl.h"
#import "TiMapViewProxy.h"
#import "TiMapZoomControlMath.h"
#import <TitaniumKit/TiColor.h>
#import <TitaniumKit/TiUtils.h>

@interface TiMapZoomControl ()
- (TiMapView *)targetMapView;
- (void)updateVisualPosition;
- (void)showActiveAppearance;
- (void)showIdleAppearance;
- (void)updateThumbGeometry;
- (void)activatePendingTouch:(NSTimer *)timer;
- (void)cancelPendingActivation;
- (void)finishTouches:(NSSet<UITouch *> *)touches;
@end

@implementation TiMapZoomControl

static const CGFloat TiMapZoomActivationMovementTolerance = 10;

- (id)init
{
  if (self = [super init]) {
    minimumDistance = 40;
    maximumDistance = 40000000;
    trackWidth = 2;
    thumbSize = 30;
    thumbWidth = 110;
    thumbCornerRadius = 4;
    zoomRange = 10;
    hitWidth = 0;
    animationDuration = 0.22;
    activationDelay = 0;
    barThumb = YES;
    relativeZoomEnabled = YES;
    trackOpacity = 0;
    activeTrackOpacity = 0.45;
    thumbOpacity = 0;
    activeThumbOpacity = 1;
    idleDelay = 0.5;
    hapticsEnabled = YES;
    hapticInterval = 0.1;
    trackColor = [UIColor.whiteColor retain];
    thumbColor = [UIColor.whiteColor retain];
    self.userInteractionEnabled = YES;

    trackView = [[UIView alloc] initWithFrame:CGRectZero];
    trackView.userInteractionEnabled = NO;
    trackView.backgroundColor = trackColor;
    trackView.alpha = trackOpacity;
    [self addSubview:trackView];

    thumbView = [[UIView alloc] initWithFrame:CGRectZero];
    thumbView.userInteractionEnabled = NO;
    thumbView.backgroundColor = thumbColor;
    thumbView.alpha = thumbOpacity;
    thumbView.layer.shadowColor = UIColor.blackColor.CGColor;
    thumbView.layer.shadowOpacity = 0.2;
    thumbView.layer.shadowRadius = 3;
    thumbView.layer.shadowOffset = CGSizeMake(0, 1);
    [self addSubview:thumbView];

    indicatorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    indicatorLabel.textAlignment = NSTextAlignmentCenter;
    indicatorLabel.adjustsFontSizeToFitWidth = YES;
    indicatorLabel.minimumScaleFactor = 0.5;
    indicatorLabel.userInteractionEnabled = NO;
    indicatorLabel.font = [UIFont systemFontOfSize:20];
    [thumbView addSubview:indicatorLabel];
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showIdleAppearance) object:nil];
  [activationTimer invalidate];
  RELEASE_TO_NIL(activationTimer);
  [[self targetMapView] removeZoomObserver:self];
  RELEASE_TO_NIL(mapViewProxy);
  RELEASE_TO_NIL(trackView);
  RELEASE_TO_NIL(thumbView);
  RELEASE_TO_NIL(indicatorLabel);
  RELEASE_TO_NIL(feedbackGenerator);
  RELEASE_TO_NIL(levelIndicators);
  RELEASE_TO_NIL(trackColor);
  RELEASE_TO_NIL(thumbColor);
  RELEASE_TO_NIL(trackingTouch);
  [super dealloc];
}

- (TiMapView *)targetMapView
{
  if (mapViewProxy == nil) {
    return nil;
  }
  return (TiMapView *)[mapViewProxy view];
}

- (void)setMapView_:(id)value
{
  ENSURE_TYPE_OR_NIL(value, TiMapViewProxy);
  if (mapViewProxy == value) {
    return;
  }
  [self finishTouches:nil];
  [[self targetMapView] removeZoomObserver:self];
  [mapViewProxy release];
  mapViewProxy = [value retain];
  [[self targetMapView] addZoomObserver:self];
}

- (void)setMinimumDistance_:(id)value
{
  minimumDistance = MAX(1, [TiUtils doubleValue:value def:40]);
  maximumDistance = MAX(minimumDistance, maximumDistance);
  [self syncWithMap];
}

- (void)setMaximumDistance_:(id)value
{
  maximumDistance = MAX(minimumDistance, [TiUtils doubleValue:value def:40000000]);
  [self syncWithMap];
}

- (void)setTrackColor_:(id)value
{
  RELEASE_TO_NIL(trackColor);
  trackColor = [[TiUtils colorValue:value].color retain];
  trackView.backgroundColor = trackColor;
}

- (void)setThumbColor_:(id)value
{
  RELEASE_TO_NIL(thumbColor);
  thumbColor = [[TiUtils colorValue:value].color retain];
  thumbView.backgroundColor = thumbColor;
}

- (void)setTrackWidth_:(id)value
{
  trackWidth = MAX(0.5, [TiUtils floatValue:value def:2]);
  [self frameSizeChanged:self.frame bounds:self.bounds];
}

- (void)setThumbSize_:(id)value
{
  thumbSize = MAX(1, [TiUtils floatValue:value def:30]);
  [self frameSizeChanged:self.frame bounds:self.bounds];
}

- (void)setRelativeZoomEnabled_:(id)value
{
  relativeZoomEnabled = [TiUtils boolValue:value def:YES];
}

- (void)setZoomRange_:(id)value
{
  CGFloat levels = [TiUtils floatValue:value def:10];
  zoomRange = isfinite(levels) ? MIN(30, MAX(0.1, levels)) : 10;
}

- (void)setThumbStyle_:(id)value
{
  barThumb = ![[TiUtils stringValue:value] isEqualToString:@"circle"];
  [self frameSizeChanged:self.frame bounds:self.bounds];
}

- (void)setThumbWidth_:(id)value
{
  CGFloat width = [TiUtils floatValue:value def:110];
  thumbWidth = isfinite(width) ? MAX(1, width) : 110;
  [self updateThumbGeometry];
}

- (void)setThumbCornerRadius_:(id)value
{
  thumbCornerRadius = MAX(0, [TiUtils floatValue:value def:4]);
  [self updateThumbGeometry];
}

- (void)setAnimationDuration_:(id)value
{
  animationDuration = MAX(0, [TiUtils doubleValue:value def:220]) / 1000.0;
}

- (void)setActivationDelay_:(id)value
{
  activationDelay = MAX(0, [TiUtils doubleValue:value def:0]) / 1000.0;
}

- (void)setHitWidth_:(id)value
{
  CGFloat width = [TiUtils floatValue:value def:0];
  hitWidth = isfinite(width) ? MAX(0, width) : 0;
}

- (void)setTrackOpacity_:(id)value
{
  trackOpacity = MIN(1, MAX(0, [TiUtils floatValue:value def:0]));
  if (!interacting) {
    trackView.alpha = trackOpacity;
  }
}

- (void)setActiveTrackOpacity_:(id)value
{
  activeTrackOpacity = MIN(1, MAX(0, [TiUtils floatValue:value def:0.45]));
}

- (void)setThumbOpacity_:(id)value
{
  thumbOpacity = MIN(1, MAX(0, [TiUtils floatValue:value def:0]));
  if (!interacting) {
    thumbView.alpha = thumbOpacity;
  }
}

- (void)setActiveThumbOpacity_:(id)value
{
  activeThumbOpacity = MIN(1, MAX(0, [TiUtils floatValue:value def:1]));
}

- (void)setIdleDelay_:(id)value
{
  idleDelay = MAX(0, [TiUtils doubleValue:value def:500] / 1000.0);
}

- (void)setHapticsEnabled_:(id)value
{
  hapticsEnabled = [TiUtils boolValue:value def:YES];
}

- (void)setHapticInterval_:(id)value
{
  hapticInterval = MIN(1, MAX(0.01, [TiUtils floatValue:value def:0.1]));
}

- (void)setLevelIndicators_:(id)value
{
  ENSURE_TYPE_OR_NIL(value, NSArray);
  RELEASE_TO_NIL(levelIndicators);
  levelIndicators = [value copy];
  [self updateVisualPosition];
}

- (CGFloat)zoomProgress
{
  return progress;
}

- (CLLocationDistance)zoomDistance
{
  return distance;
}

- (CLLocationDistance)distanceForProgress:(CGFloat)value
{
  value = MIN(1, MAX(0, value));
  if (maximumDistance <= minimumDistance) {
    return minimumDistance;
  }
  return exp(log(minimumDistance) + ((1.0 - value) * (log(maximumDistance) - log(minimumDistance))));
}

- (CGFloat)progressForDistance:(CLLocationDistance)value
{
  value = MIN(maximumDistance, MAX(minimumDistance, value));
  if (maximumDistance <= minimumDistance) {
    return 1;
  }
  return 1.0 - ((log(value) - log(minimumDistance)) / (log(maximumDistance) - log(minimumDistance)));
}

- (void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
  [super frameSizeChanged:frame bounds:bounds];
  trackView.bounds = CGRectMake(0, 0, trackWidth, MAX(0, bounds.size.height - thumbSize));
  CGFloat trackX = barThumb ? CGRectGetMaxX(bounds) - MAX(4, trackWidth / 2.0) : CGRectGetMidX(bounds);
  trackView.center = CGPointMake(trackX, CGRectGetMidY(bounds));
  trackView.layer.cornerRadius = trackWidth / 2.0;
  [self updateThumbGeometry];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
  if (![super pointInside:point withEvent:event]) {
    return NO;
  }
  CGFloat boundsWidth = CGRectGetWidth(self.bounds);
  if (hitWidth <= 0 || hitWidth >= boundsWidth) {
    return YES;
  }
  if (barThumb) {
    return point.x >= CGRectGetMaxX(self.bounds) - hitWidth;
  }
  return fabs(point.x - trackView.center.x) <= hitWidth / 2.0;
}

- (void)updateThumbGeometry
{
  CGFloat width = barThumb && appearanceExpanded ? MAX(thumbSize, thumbWidth) : thumbSize;
  // Keep the handle within the control's touch surface.
  if (barThumb) {
    width = MIN(width, MAX(1, trackView.center.x - CGRectGetMinX(self.bounds)));
  }
  thumbView.bounds = CGRectMake(0, 0, width, thumbSize);
  thumbView.layer.cornerRadius = barThumb ? MIN(thumbCornerRadius, MIN(width, thumbSize) / 2.0) : thumbSize / 2.0;
  indicatorLabel.frame = CGRectMake(0, 0, MIN(thumbSize, width), thumbSize);
  // An explicit shape avoids deriving shadow geometry from the label/subview tree.
  thumbView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:thumbView.bounds cornerRadius:thumbView.layer.cornerRadius].CGPath;
  [self updateVisualPosition];
}

- (void)updateVisualPosition
{
  CGFloat travel = MAX(0, self.bounds.size.height - thumbSize);
  CGFloat visualProgress = holdingThumbPosition ? touchProgress : progress;
  CGFloat x = barThumb ? trackView.center.x - thumbView.bounds.size.width / 2.0 : trackView.center.x;
  thumbView.center = CGPointMake(x, CGRectGetMinY(self.bounds) + (thumbSize / 2.0) + ((1.0 - visualProgress) * travel));
  NSDictionary *closest = nil;
  CGFloat closestDifference = CGFLOAT_MAX;
  for (NSDictionary *item in levelIndicators) {
    if (![item isKindOfClass:[NSDictionary class]]) {
      continue;
    }
    CGFloat itemProgress = MIN(1, MAX(0, [TiUtils floatValue:@"progress" properties:item def:0]));
    CGFloat difference = fabs(itemProgress - progress);
    if (difference < closestDifference) {
      closestDifference = difference;
      closest = item;
    }
  }
  indicatorLabel.text = closest != nil ? [TiUtils stringValue:@"title" properties:closest def:@""] : @"";
}

- (void)showActiveAppearance
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showIdleAppearance) object:nil];
  appearanceExpanded = YES;
  [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled() ? 0 : animationDuration
                        delay:0
       usingSpringWithDamping:0.8
        initialSpringVelocity:0
                      options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                   animations:^{
                     [self updateThumbGeometry];
                     self->trackView.alpha = self->activeTrackOpacity;
                     self->thumbView.alpha = self->activeThumbOpacity;
                   }
                   completion:nil];
}

- (void)showIdleAppearance
{
  if (interacting) {
    return;
  }
  [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled() ? 0 : animationDuration
      delay:0
      options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
      animations:^{
        self->trackView.alpha = self->trackOpacity;
        self->thumbView.alpha = self->thumbOpacity;
      }
      completion:^(BOOL finished) {
        if (finished && !self->interacting) {
          self->holdingThumbPosition = NO;
          if (self->thumbOpacity <= 0) {
            // The relative gesture position and absolute camera progress can be far
            // apart. Hide the fully transparent thumb while rebasing so Core Animation
            // cannot present one last visible frame at the new position.
            self->thumbView.hidden = YES;
            [UIView performWithoutAnimation:^{
              [self updateVisualPosition];
            }];
            self->thumbView.hidden = NO;
          } else {
            [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled() ? 0 : self->animationDuration
                             animations:^{
                               [self updateVisualPosition];
                             }];
          }
        }
      }];
}

- (CGFloat)progressForTouch:(UITouch *)touch
{
  CGFloat travel = MAX(1, self.bounds.size.height - thumbSize);
  CGFloat y = [touch locationInView:self].y - CGRectGetMinY(self.bounds);
  return MIN(1, MAX(0, 1.0 - ((y - (thumbSize / 2.0)) / travel)));
}

- (void)updateFromTouch:(UITouch *)touch
{
  CGFloat newProgress = [self progressForTouch:touch];
  if (newProgress == touchProgress) {
    return;
  }
  NSInteger hapticStep = lround((newProgress - startTouchProgress) / hapticInterval);
  if (hapticsEnabled && hapticStep != lastHapticStep) {
    [feedbackGenerator selectionChanged];
    [feedbackGenerator prepare];
    lastHapticStep = hapticStep;
  }
  touchProgress = newProgress;
  distance = gestureIsRelative
      ? TiMapRelativeZoomDistance(startDistance, startTouchProgress, touchProgress, gestureZoomRange, gestureMinimumDistance, gestureMaximumDistance)
      : [self distanceForProgress:touchProgress];
  progress = [self progressForDistance:distance];
  [self updateVisualPosition];
  [[self targetMapView] updateInteractiveZoomToDistance:distance];
  [self fireZoomEvent:@"zoomchange"];
}

- (void)cancelPendingActivation
{
  [activationTimer invalidate];
  RELEASE_TO_NIL(activationTimer);
  activationPending = NO;
  RELEASE_TO_NIL(trackingTouch);
}

- (void)activatePendingTouch:(NSTimer *)timer
{
  [activationTimer invalidate];
  RELEASE_TO_NIL(activationTimer);
  if (!activationPending || trackingTouch == nil || self.window == nil) {
    [self cancelPendingActivation];
    return;
  }

  TiMapView *mapView = [self targetMapView];
  if (mapView == nil || trackingTouch.phase == UITouchPhaseEnded || trackingTouch.phase == UITouchPhaseCancelled) {
    [self cancelPendingActivation];
    return;
  }

  activationPending = NO;
  startDistance = MAX(1, [mapView cameraDistance]);
  distance = startDistance;
  progress = [self progressForDistance:distance];
  startTouchProgress = [self progressForTouch:trackingTouch];
  touchProgress = startTouchProgress;
  gestureIsRelative = relativeZoomEnabled;
  gestureZoomRange = zoomRange;
  // If the map starts outside our configured range, don't snap it on activation.
  gestureMinimumDistance = gestureIsRelative ? MIN(minimumDistance, startDistance) : minimumDistance;
  gestureMaximumDistance = gestureIsRelative ? MAX(maximumDistance, startDistance) : maximumDistance;
  interacting = YES;
  holdingThumbPosition = YES;
  [self updateVisualPosition];
  [self showActiveAppearance];
  [mapView beginInteractiveZoomWithMinimumDistance:gestureMinimumDistance maximumDistance:gestureMaximumDistance];
  if (hapticsEnabled) {
    feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
    [feedbackGenerator prepare];
  }
  lastHapticStep = 0;
  [self fireZoomEvent:@"zoomstart"];
  if (!gestureIsRelative) {
    distance = [self distanceForProgress:touchProgress];
    progress = [self progressForDistance:distance];
    [mapView updateInteractiveZoomToDistance:distance];
    [self updateVisualPosition];
    [self fireZoomEvent:@"zoomchange"];
  }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  [super touchesBegan:touches withEvent:event];
  TiMapView *mapView = [self targetMapView];
  if (mapView == nil || interacting || activationPending) {
    return;
  }
  trackingTouch = [touches.anyObject retain];
  activationStartPoint = [trackingTouch locationInView:self];
  activationPending = YES;
  NSTimeInterval remainingDelay = TiMapZoomActivationRemainingDelay(
      activationDelay, trackingTouch.timestamp, NSProcessInfo.processInfo.systemUptime);
  if (remainingDelay <= 0) {
    [self activatePendingTouch:nil];
  } else {
    activationTimer = [[NSTimer timerWithTimeInterval:remainingDelay
                                               target:self
                                             selector:@selector(activatePendingTouch:)
                                             userInfo:nil
                                              repeats:NO] retain];
    [NSRunLoop.mainRunLoop addTimer:activationTimer forMode:NSRunLoopCommonModes];
  }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  [super touchesMoved:touches withEvent:event];
  if (activationPending && [touches containsObject:trackingTouch]) {
    CGPoint currentPoint = [trackingTouch locationInView:self];
    if (hypot(currentPoint.x - activationStartPoint.x, currentPoint.y - activationStartPoint.y) > TiMapZoomActivationMovementTolerance) {
      [self cancelPendingActivation];
    }
    return;
  }
  if (interacting && [touches containsObject:trackingTouch]) {
    [self updateFromTouch:trackingTouch];
  }
}

- (void)finishTouches:(NSSet<UITouch *> *)touches
{
  if (activationPending) {
    [self cancelPendingActivation];
    return;
  }
  if (!interacting) {
    RELEASE_TO_NIL(trackingTouch);
    return;
  }
  if ([touches containsObject:trackingTouch]) {
    [self updateFromTouch:trackingTouch];
  }
  [[self targetMapView] endInteractiveZoom];
  interacting = NO;
  RELEASE_TO_NIL(trackingTouch);
  RELEASE_TO_NIL(feedbackGenerator);
  [self fireZoomEvent:@"zoomend"];
  appearanceExpanded = NO;
  [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled() ? 0 : animationDuration
                        delay:0
       usingSpringWithDamping:0.85
        initialSpringVelocity:0
                      options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                   animations:^{
                     [self updateThumbGeometry];
                   }
                   completion:nil];
  [self performSelector:@selector(showIdleAppearance) withObject:nil afterDelay:idleDelay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  [super touchesEnded:touches withEvent:event];
  [self finishTouches:touches];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  [super touchesCancelled:touches withEvent:event];
  [self finishTouches:nil];
}

- (void)didMoveToWindow
{
  [super didMoveToWindow];
  if (self.window == nil) {
    [self finishTouches:nil];
  }
}

- (void)mapView:(TiMapView *)mapView zoomDistanceDidChange:(CLLocationDistance)newDistance
{
  distance = newDistance;
  progress = [self progressForDistance:distance];
  [self updateVisualPosition];
}

- (void)setProgressAnimated:(CGFloat)newProgress animated:(BOOL)animated duration:(NSTimeInterval)durationMilliseconds
{
  [self finishTouches:nil];
  holdingThumbPosition = NO;
  progress = MIN(1, MAX(0, newProgress));
  distance = [self distanceForProgress:progress];
  [self updateVisualPosition];
  [[self targetMapView] zoomTo:@{
    @"distance" : @(distance),
    @"animated" : @(animated),
    @"duration" : @(durationMilliseconds),
    @"minimumDistance" : @(minimumDistance),
    @"maximumDistance" : @(maximumDistance)
  }];
}

- (void)syncWithMap
{
  if (!interacting) {
    holdingThumbPosition = NO;
  }
  TiMapView *mapView = [self targetMapView];
  if (mapView != nil) {
    [self mapView:mapView zoomDistanceDidChange:[mapView cameraDistance]];
  }
}

- (void)fireZoomEvent:(NSString *)name
{
  if (![[self proxy] _hasListeners:name]) {
    return;
  }
  [[self proxy] fireEvent:name
               withObject:@{
                 @"progress" : @(progress),
                 @"distance" : @(distance),
                 @"interactive" : @(interacting)
               }];
}

@end
