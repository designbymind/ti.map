/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiMapFeaturedAnnotationView.h"
#import "TiMapAnnotationProxy.h"
#import <QuartzCore/QuartzCore.h>
#import <TitaniumKit/TiUtils.h>

static const CGFloat kNormalMarkerDiameter = 44.0;
static const CGFloat kAnnotationViewHeight = 50.0;
static const CGFloat kNormalImageInset = 2.0;
static const CGFloat kSelectedMarkerWidth = 78.0;
static const CGFloat kSelectedMarkerHeight = 94.0;
static const CGFloat kSelectedImageInset = 5.0;
static const CGFloat kSelectedMarkerCollapsedScale = 0.48;
static const CGFloat kMaximumShadowRadius = 24.0;
static const CGFloat kLabelTopSpacing = 4.0;
static const CGFloat kLabelHorizontalPadding = 5.0;
static const CGFloat kTitleLabelHeight = 17.0;
static const CGFloat kSubtitleLabelHeight = 15.0;
static const CGFloat kMaximumLabelWidth = 180.0;

static CGFloat TiMapClampedShadowOpacity(CGFloat value)
{
  return MIN(MAX(value, 0.0), 1.0);
}

static CGFloat TiMapClampedShadowRadius(CGFloat value)
{
  return MIN(MAX(value, 0.0), kMaximumShadowRadius);
}

@interface TiMapFeaturedAnnotationView ()

- (void)applyImage:(UIImage *)image animated:(BOOL)animated;
- (void)applySelectionState:(BOOL)selected;
- (void)updateLabelAppearance;
- (void)layoutLabels;
- (void)updateLabelVisibilityAnimated:(BOOL)animated;
- (void)applyShadowConfiguration:(id)configuration
                         toLayer:(CALayer *)layer
                    defaultColor:(UIColor *)defaultColor
                  defaultOpacity:(CGFloat)defaultOpacity
                   defaultRadius:(CGFloat)defaultRadius
                   defaultOffset:(CGSize)defaultOffset
                      shadowPath:(CGPathRef)shadowPath;
- (void)cancelPendingImageLoad;

@end

@implementation TiMapFeaturedAnnotationView

+ (CGPoint)defaultCenterOffset
{
  return CGPointMake(0.0, -(kAnnotationViewHeight / 2.0));
}

- (CGPoint)defaultCenterOffset
{
  return [[self class] defaultCenterOffset];
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier map:(TiMapView *)map_
{
  if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
    self.backgroundColor = [UIColor clearColor];
    self.bounds = CGRectMake(0.0, 0.0, kNormalMarkerDiameter, kAnnotationViewHeight);
    self.clipsToBounds = NO;

    normalMarkerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, kNormalMarkerDiameter, kNormalMarkerDiameter)];
    normalMarkerView.backgroundColor = [UIColor clearColor];
    normalMarkerView.userInteractionEnabled = NO;
    normalMarkerView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    normalMarkerView.layer.position = CGPointMake(CGRectGetMidX(self.bounds), kAnnotationViewHeight);
    [self addSubview:normalMarkerView];

    UIBezierPath *normalPath = [UIBezierPath bezierPathWithOvalInRect:normalMarkerView.bounds];
    normalBackgroundLayer = [CAShapeLayer layer];
    normalBackgroundLayer.frame = normalMarkerView.bounds;
    normalBackgroundLayer.path = normalPath.CGPath;
    normalBackgroundLayer.fillColor = UIColor.whiteColor.CGColor;
    [normalMarkerView.layer addSublayer:normalBackgroundLayer];

    CGFloat normalImageDiameter = kNormalMarkerDiameter - (kNormalImageInset * 2.0);
    normalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kNormalImageInset, kNormalImageInset, normalImageDiameter, normalImageDiameter)];
    normalImageView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    normalImageView.contentMode = UIViewContentModeScaleAspectFill;
    normalImageView.clipsToBounds = YES;
    normalImageView.layer.cornerRadius = normalImageDiameter / 2.0;
    normalImageView.userInteractionEnabled = NO;
    [normalMarkerView addSubview:normalImageView];

    selectedMarkerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, kSelectedMarkerWidth, kSelectedMarkerHeight)];
    selectedMarkerView.backgroundColor = [UIColor clearColor];
    selectedMarkerView.userInteractionEnabled = NO;
    selectedMarkerView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    selectedMarkerView.layer.position = CGPointMake(CGRectGetMidX(self.bounds), kAnnotationViewHeight);
    [self addSubview:selectedMarkerView];

    UIBezierPath *selectedPath = [UIBezierPath bezierPath];
    [selectedPath moveToPoint:CGPointMake(39.0, 1.0)];
    [selectedPath addCurveToPoint:CGPointMake(77.0, 39.0)
                    controlPoint1:CGPointMake(60.0, 1.0)
                    controlPoint2:CGPointMake(77.0, 18.0)];
    [selectedPath addCurveToPoint:CGPointMake(53.5, 72.0)
                    controlPoint1:CGPointMake(77.0, 54.8)
                    controlPoint2:CGPointMake(67.5, 68.2)];
    [selectedPath addCurveToPoint:CGPointMake(45.0, 79.0)
                    controlPoint1:CGPointMake(50.2, 73.8)
                    controlPoint2:CGPointMake(47.2, 76.4)];
    [selectedPath addCurveToPoint:CGPointMake(39.0, 85.0)
                    controlPoint1:CGPointMake(43.0, 81.5)
                    controlPoint2:CGPointMake(42.0, 85.0)];
    [selectedPath addCurveToPoint:CGPointMake(33.0, 79.0)
                    controlPoint1:CGPointMake(36.0, 85.0)
                    controlPoint2:CGPointMake(35.0, 81.5)];
    [selectedPath addCurveToPoint:CGPointMake(24.5, 72.0)
                    controlPoint1:CGPointMake(30.8, 76.4)
                    controlPoint2:CGPointMake(27.8, 73.8)];
    [selectedPath addCurveToPoint:CGPointMake(1.0, 39.0)
                    controlPoint1:CGPointMake(10.5, 68.2)
                    controlPoint2:CGPointMake(1.0, 54.5)];
    [selectedPath addCurveToPoint:CGPointMake(39.0, 1.0)
                    controlPoint1:CGPointMake(1.0, 18.0)
                    controlPoint2:CGPointMake(18.0, 1.0)];
    [selectedPath closePath];

    selectedBackgroundLayer = [CAShapeLayer layer];
    selectedBackgroundLayer.frame = selectedMarkerView.bounds;
    selectedBackgroundLayer.path = selectedPath.CGPath;
    selectedBackgroundLayer.fillColor = UIColor.whiteColor.CGColor;
    [selectedMarkerView.layer addSublayer:selectedBackgroundLayer];

    CGFloat selectedImageDiameter = kSelectedMarkerWidth - (kSelectedImageInset * 2.0);
    selectedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kSelectedImageInset, kSelectedImageInset, selectedImageDiameter, selectedImageDiameter)];
    selectedImageView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    selectedImageView.contentMode = UIViewContentModeScaleAspectFill;
    selectedImageView.clipsToBounds = YES;
    selectedImageView.layer.cornerRadius = selectedImageDiameter / 2.0;
    selectedImageView.userInteractionEnabled = NO;
    [selectedMarkerView addSubview:selectedImageView];

    // Keep the circular rim above the image so the photo can never visually
    // bleed into the balloon's lower shoulder or tail.
    CAShapeLayer *selectedRimLayer = [CAShapeLayer layer];
    selectedRimLayer.frame = selectedMarkerView.bounds;
    selectedRimLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(2.5, 2.5, 73.0, 73.0)].CGPath;
    selectedRimLayer.fillColor = UIColor.clearColor.CGColor;
    selectedRimLayer.strokeColor = UIColor.whiteColor.CGColor;
    selectedRimLayer.lineWidth = 3.0;
    [selectedMarkerView.layer addSublayer:selectedRimLayer];

    anchorDotLayer = [CALayer layer];
    anchorDotLayer.frame = CGRectMake(36.75, 89.0, 4.5, 4.5);
    anchorDotLayer.backgroundColor = UIColor.whiteColor.CGColor;
    anchorDotLayer.cornerRadius = 2.25;
    [selectedMarkerView.layer addSublayer:anchorDotLayer];

    labelContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    labelContainerView.backgroundColor = UIColor.clearColor;
    labelContainerView.userInteractionEnabled = NO;
    [self addSubview:labelContainerView];

    titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = 0.8;
    titleLabel.userInteractionEnabled = NO;
    [labelContainerView addSubview:titleLabel];

    subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.backgroundColor = UIColor.clearColor;
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightBold];
    subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    subtitleLabel.adjustsFontSizeToFitWidth = YES;
    subtitleLabel.minimumScaleFactor = 0.8;
    subtitleLabel.userInteractionEnabled = NO;
    [labelContainerView addSubview:subtitleLabel];

    titleVisibility = MKFeatureVisibilityAdaptive;
    subtitleVisibility = MKFeatureVisibilityAdaptive;
    [self updateLabelAppearance];
    [self layoutLabels];

    [self setMarkerShadow:nil selectedMarkerShadow:nil];
    [self applySelectionState:NO];

    if (@available(iOS 14.0, *)) {
      self.selectedZPriority = MKAnnotationViewZPriorityMax;
    }
  }
  return self;
}

- (void)dealloc
{
  [self cancelPendingImageLoad];
  RELEASE_TO_NIL(lastHitName);
  RELEASE_TO_NIL(normalImageView);
  RELEASE_TO_NIL(selectedImageView);
  RELEASE_TO_NIL(titleLabel);
  RELEASE_TO_NIL(subtitleLabel);
  RELEASE_TO_NIL(labelContainerView);
  RELEASE_TO_NIL(normalMarkerView);
  RELEASE_TO_NIL(selectedMarkerView);
  [super dealloc];
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  [self cancelPendingImageLoad];
  normalImageView.image = nil;
  selectedImageView.image = nil;
  normalImageView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
  selectedImageView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
  [self setTitle:nil
                subtitle:nil
         titleVisibility:MKFeatureVisibilityAdaptive
      subtitleVisibility:MKFeatureVisibilityAdaptive];
  [self setMarkerShadow:nil selectedMarkerShadow:nil];
  [self setSelected:NO animated:NO];
}

- (void)setTitle:(NSString *)title
              subtitle:(NSString *)subtitle
       titleVisibility:(MKFeatureVisibility)newTitleVisibility
    subtitleVisibility:(MKFeatureVisibility)newSubtitleVisibility
{
  titleLabel.text = title;
  subtitleLabel.text = subtitle;
  titleVisibility = newTitleVisibility;
  subtitleVisibility = newSubtitleVisibility;
  [self updateLabelAppearance];
  [self layoutLabels];
  [self updateLabelVisibilityAnimated:NO];
}

- (void)updateLabelAppearance
{
  BOOL darkAppearance = NO;
  if (@available(iOS 13.0, *)) {
    darkAppearance = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
  }

  UIColor *textColor = darkAppearance ? UIColor.whiteColor : [UIColor colorWithWhite:0.08 alpha:1.0];
  UIColor *shadowColor = darkAppearance ? [UIColor colorWithWhite:0.0 alpha:0.86] : [UIColor colorWithWhite:1.0 alpha:0.92];

  for (UILabel *label in @[ titleLabel, subtitleLabel ]) {
    label.textColor = textColor;
    label.layer.shadowColor = shadowColor.CGColor;
    label.layer.shadowOpacity = 1.0;
    label.layer.shadowRadius = 1.5;
    label.layer.shadowOffset = CGSizeMake(0.0, 1.0);
  }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];
  [self updateLabelAppearance];
}

- (void)layoutLabels
{
  BOOL hasTitle = titleLabel.text.length > 0 && titleVisibility != MKFeatureVisibilityHidden;
  BOOL hasSubtitle = subtitleLabel.text.length > 0 && subtitleVisibility != MKFeatureVisibilityHidden;

  // Keep the annotation view itself compact. MapKit uses these bounds for
  // selection and collision before UIKit asks pointInside:withEvent:, so
  // widening the root view to fit labels also widens its effective tap area.
  self.bounds = CGRectMake(0.0, 0.0, kNormalMarkerDiameter, kAnnotationViewHeight);
  normalMarkerView.layer.position = CGPointMake(CGRectGetMidX(self.bounds), kAnnotationViewHeight);
  selectedMarkerView.layer.position = CGPointMake(CGRectGetMidX(self.bounds), kAnnotationViewHeight);

  if (!hasTitle && !hasSubtitle) {
    labelContainerView.frame = CGRectZero;
    labelContainerView.hidden = YES;
    return;
  }

  CGFloat measuredWidth = 0.0;
  if (hasTitle) {
    measuredWidth = MAX(measuredWidth, ceil([titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : titleLabel.font }].width));
  }
  if (hasSubtitle) {
    measuredWidth = MAX(measuredWidth, ceil([subtitleLabel.text sizeWithAttributes:@{ NSFontAttributeName : subtitleLabel.font }].width));
  }

  CGFloat labelWidth = MIN(kMaximumLabelWidth, MAX(kNormalMarkerDiameter, measuredWidth + (kLabelHorizontalPadding * 2.0)));
  CGFloat labelHeight = (hasTitle ? kTitleLabelHeight : 0.0) + (hasSubtitle ? kSubtitleLabelHeight : 0.0);

  labelContainerView.hidden = NO;
  labelContainerView.frame = CGRectMake((kNormalMarkerDiameter - labelWidth) / 2.0,
      kAnnotationViewHeight + kLabelTopSpacing,
      labelWidth,
      labelHeight);
  CGFloat labelY = 0.0;
  titleLabel.frame = hasTitle ? CGRectMake(kLabelHorizontalPadding, labelY, labelWidth - (kLabelHorizontalPadding * 2.0), kTitleLabelHeight) : CGRectZero;
  if (hasTitle) {
    labelY += kTitleLabelHeight;
  }
  subtitleLabel.frame = hasSubtitle ? CGRectMake(kLabelHorizontalPadding, labelY, labelWidth - (kLabelHorizontalPadding * 2.0), kSubtitleLabelHeight) : CGRectZero;
}

- (void)updateLabelVisibilityAnimated:(BOOL)animated
{
  BOOL hasTitle = titleLabel.text.length > 0 && titleVisibility != MKFeatureVisibilityHidden;
  BOOL hasSubtitle = subtitleLabel.text.length > 0 && subtitleVisibility != MKFeatureVisibilityHidden;
  BOOL showingCallout = self.selected && self.canShowCallout;
  BOOL showTitle = hasTitle && (titleVisibility == MKFeatureVisibilityVisible || !showingCallout);
  BOOL showSubtitle = hasSubtitle && (subtitleVisibility == MKFeatureVisibilityVisible || (self.selected && !showingCallout));

  void (^updates)(void) = ^{
    self->titleLabel.alpha = showTitle ? 1.0 : 0.0;
    self->subtitleLabel.alpha = showSubtitle ? 1.0 : 0.0;
  };

  if (animated) {
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:updates
                     completion:nil];
  } else {
    [titleLabel.layer removeAllAnimations];
    [subtitleLabel.layer removeAllAnimations];
    updates();
  }
}

- (void)applyShadowConfiguration:(id)configuration
                         toLayer:(CALayer *)layer
                    defaultColor:(UIColor *)defaultColor
                  defaultOpacity:(CGFloat)defaultOpacity
                   defaultRadius:(CGFloat)defaultRadius
                   defaultOffset:(CGSize)defaultOffset
                      shadowPath:(CGPathRef)shadowPath
{
  NSDictionary *properties = [configuration isKindOfClass:[NSDictionary class]] ? configuration : @{};
  BOOL enabled = [TiUtils boolValue:@"enabled" properties:properties def:YES];
  CGFloat opacity = TiMapClampedShadowOpacity([TiUtils floatValue:@"opacity" properties:properties def:defaultOpacity]);

  if (!enabled || opacity == 0.0) {
    layer.shadowColor = nil;
    layer.shadowOpacity = 0.0;
    layer.shadowRadius = 0.0;
    layer.shadowOffset = CGSizeZero;
    layer.shadowPath = nil;
    return;
  }

  UIColor *color = [TiUtils colorValue:@"color" properties:properties def:[TiColor colorNamed:@"black"]].color;
  CGPoint offset = [TiUtils pointValue:@"offset"
                            properties:properties
                                   def:CGPointMake(defaultOffset.width, defaultOffset.height)];

  layer.shadowColor = (color ?: defaultColor).CGColor;
  layer.shadowOpacity = opacity;
  layer.shadowRadius = TiMapClampedShadowRadius([TiUtils floatValue:@"radius" properties:properties def:defaultRadius]);
  layer.shadowOffset = CGSizeMake(offset.x, offset.y);
  layer.shadowPath = shadowPath;
}

- (void)setMarkerShadow:(id)markerShadow selectedMarkerShadow:(id)selectedMarkerShadow
{
  [self applyShadowConfiguration:markerShadow
                         toLayer:normalBackgroundLayer
                    defaultColor:UIColor.blackColor
                  defaultOpacity:0.18
                   defaultRadius:2.5
                   defaultOffset:CGSizeMake(0.0, 1.0)
                      shadowPath:normalBackgroundLayer.path];

  [self applyShadowConfiguration:selectedMarkerShadow
                         toLayer:selectedBackgroundLayer
                    defaultColor:UIColor.blackColor
                  defaultOpacity:0.32
                   defaultRadius:6.0
                   defaultOffset:CGSizeMake(0.0, 3.0)
                      shadowPath:selectedBackgroundLayer.path];

  NSDictionary *selectedProperties = [selectedMarkerShadow isKindOfClass:[NSDictionary class]] ? selectedMarkerShadow : @{};
  BOOL selectedShadowEnabled = [TiUtils boolValue:@"enabled" properties:selectedProperties def:YES];
  CGFloat selectedOpacity = TiMapClampedShadowOpacity([TiUtils floatValue:@"opacity" properties:selectedProperties def:0.32]);
  if (!selectedShadowEnabled || selectedOpacity == 0.0) {
    [self applyShadowConfiguration:@{ @"enabled" : @NO }
                           toLayer:anchorDotLayer
                      defaultColor:UIColor.blackColor
                    defaultOpacity:0.18
                     defaultRadius:1.5
                     defaultOffset:CGSizeMake(0.0, 1.0)
                        shadowPath:nil];
  } else {
    UIColor *selectedColor = [TiUtils colorValue:@"color" properties:selectedProperties def:[TiColor colorNamed:@"black"]].color;
    anchorDotLayer.shadowColor = (selectedColor ?: UIColor.blackColor).CGColor;
    anchorDotLayer.shadowOpacity = TiMapClampedShadowOpacity(selectedOpacity * (0.18 / 0.32));
    anchorDotLayer.shadowRadius = TiMapClampedShadowRadius([TiUtils floatValue:@"radius" properties:selectedProperties def:6.0] * 0.25);
    CGPoint selectedOffset = [TiUtils pointValue:@"offset" properties:selectedProperties def:CGPointMake(0.0, 3.0)];
    anchorDotLayer.shadowOffset = CGSizeMake(selectedOffset.x / 3.0, selectedOffset.y / 3.0);
    anchorDotLayer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:anchorDotLayer.bounds].CGPath;
  }
}

- (void)cancelPendingImageLoad
{
  if (imageRequest != nil) {
    [imageRequest cancel];
    RELEASE_TO_NIL(imageRequest);
  }
}

- (void)setImageSource:(id)imageSource proxy:(TiMapAnnotationProxy *)proxy
{
  [self cancelPendingImageLoad];
  normalImageView.image = nil;
  selectedImageView.image = nil;
  normalImageView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
  selectedImageView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];

  if (imageSource == nil || imageSource == [NSNull null]) {
    return;
  }

  UIImage *image = nil;
  if ([imageSource isKindOfClass:[NSString class]]) {
    NSURL *imageURL = [TiUtils toURL:(NSString *)imageSource proxy:proxy];
    if (imageURL == nil) {
      return;
    }

    if ([imageURL isFileURL]) {
      image = [TiUtils image:imageSource proxy:proxy];
      if (image == nil) {
        image = [UIImage imageWithContentsOfFile:imageURL.path];
      }
    } else {
      image = [[ImageLoader sharedLoader] loadImmediateImage:imageURL];
      if (image == nil) {
        imageRequest = [[[ImageLoader sharedLoader] loadImage:imageURL delegate:self userInfo:nil] retain];
      }
    }
  } else {
    image = [TiUtils image:imageSource proxy:proxy];
  }

  if (image != nil) {
    [self applyImage:image animated:NO];
  }
}

- (void)applyImage:(UIImage *)image animated:(BOOL)animated
{
  void (^updates)(void) = ^{
    self->normalImageView.image = image;
    self->selectedImageView.image = image;
    self->normalImageView.backgroundColor = [UIColor clearColor];
    self->selectedImageView.backgroundColor = [UIColor clearColor];
  };

  if (animated) {
    [UIView transitionWithView:self
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                    animations:updates
                    completion:nil];
  } else {
    updates();
  }
}

- (void)imageLoadSuccess:(ImageLoaderRequest *)request image:(UIImage *)image
{
  if (request != imageRequest) {
    return;
  }

  TiThreadPerformOnMainThread(
      ^{
        if (request == self->imageRequest) {
          [self applyImage:image animated:YES];
          RELEASE_TO_NIL(self->imageRequest);
        }
      },
      NO);
}

- (void)imageLoadFailed:(ImageLoaderRequest *)request error:(NSError *)error
{
  if (request != imageRequest) {
    return;
  }

  TiThreadPerformOnMainThread(
      ^{
        if (request == self->imageRequest) {
          NSLog(@"[WARN] Unable to load featured annotation image from %@: %@", request.url, error.localizedDescription);
          RELEASE_TO_NIL(self->imageRequest);
        }
      },
      NO);
}

- (void)imageLoadCancelled:(ImageLoaderRequest *)request
{
}

- (void)applySelectionState:(BOOL)selected
{
  [normalMarkerView.layer removeAllAnimations];
  [selectedMarkerView.layer removeAllAnimations];

  normalMarkerView.alpha = selected ? 0.0 : 1.0;
  normalMarkerView.transform = selected ? CGAffineTransformMakeScale(0.82, 0.82) : CGAffineTransformIdentity;
  selectedMarkerView.alpha = selected ? 1.0 : 0.0;
  selectedMarkerView.transform = selected ? CGAffineTransformIdentity : CGAffineTransformMakeScale(kSelectedMarkerCollapsedScale, kSelectedMarkerCollapsedScale);
  self.calloutOffset = selected ? CGPointMake(0.0, -(kSelectedMarkerHeight - kAnnotationViewHeight)) : CGPointZero;
  [self updateLabelVisibilityAnimated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  BOOL selectionChanged = self.selected != selected;
  [super setSelected:selected animated:animated];

  if (!animated || !selectionChanged) {
    [self applySelectionState:selected];
    return;
  }

  [normalMarkerView.layer removeAllAnimations];
  [selectedMarkerView.layer removeAllAnimations];
  self.calloutOffset = selected ? CGPointMake(0.0, -(kSelectedMarkerHeight - kAnnotationViewHeight)) : CGPointZero;
  [self updateLabelVisibilityAnimated:YES];

  if (selected) {
    selectedMarkerView.alpha = 0.0;
    selectedMarkerView.transform = CGAffineTransformMakeScale(kSelectedMarkerCollapsedScale, kSelectedMarkerCollapsedScale);

    [UIView animateWithDuration:0.14
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn
                     animations:^{
                       self->normalMarkerView.alpha = 0.0;
                       self->normalMarkerView.transform = CGAffineTransformMakeScale(0.78, 0.78);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.58
                          delay:0.02
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.18
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self->selectedMarkerView.alpha = 1.0;
                       self->selectedMarkerView.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
  } else {
    normalMarkerView.alpha = 0.0;
    normalMarkerView.transform = CGAffineTransformMakeScale(0.72, 0.72);

    [UIView animateWithDuration:0.36
                          delay:0.0
         usingSpringWithDamping:0.62
          initialSpringVelocity:0.18
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self->selectedMarkerView.alpha = 0.0;
                       self->selectedMarkerView.transform = CGAffineTransformMakeScale(kSelectedMarkerCollapsedScale, kSelectedMarkerCollapsedScale);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.48
                          delay:0.04
         usingSpringWithDamping:0.54
          initialSpringVelocity:0.22
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self->normalMarkerView.alpha = 1.0;
                       self->normalMarkerView.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
  }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
  CGPoint normalPoint = [self convertPoint:point toView:normalMarkerView];
  CGPoint selectedPoint = [self convertPoint:point toView:selectedMarkerView];
  BOOL insideNormalMarker = normalMarkerView.alpha > 0.01 && normalBackgroundLayer.path != nil && CGPathContainsPoint(normalBackgroundLayer.path, NULL, normalPoint, NO);
  BOOL insideSelectedBalloon = selectedBackgroundLayer.path != nil && CGPathContainsPoint(selectedBackgroundLayer.path, NULL, selectedPoint, NO);
  BOOL insideSelectedAnchorDot = CGRectContainsPoint(anchorDotLayer.frame, selectedPoint);
  BOOL insideSelectedMarker = selectedMarkerView.alpha > 0.01 && (insideSelectedBalloon || insideSelectedAnchorDot);
  return insideNormalMarker || insideSelectedMarker;
}

- (NSString *)lastHitName
{
  NSString *result = lastHitName;
  [lastHitName autorelease];
  lastHitName = nil;
  return result;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  UIView *result = [super hitTest:point withEvent:event];

  if (result == nil) {
    for (UIView *ourSubView in self.subviews) {
      CGPoint subPoint = [self convertPoint:point toView:ourSubView];
      for (UIView *ourSubSubView in ourSubView.subviews) {
        if (CGRectContainsPoint(ourSubSubView.frame, subPoint) && [ourSubSubView isKindOfClass:[UILabel class]]) {
          NSString *labelText = [(UILabel *)ourSubSubView text];
          TiMapAnnotationProxy *ourProxy = (TiMapAnnotationProxy *)self.annotation;
          RELEASE_TO_NIL(lastHitName);
          if ([labelText isEqualToString:ourProxy.title]) {
            lastHitName = [@"title" retain];
          } else if ([labelText isEqualToString:ourProxy.subtitle]) {
            lastHitName = [@"subtitle" retain];
          }
          return nil;
        }
      }
      if (CGRectContainsPoint(ourSubView.bounds, subPoint)) {
        RELEASE_TO_NIL(lastHitName);
        lastHitName = [@"annotation" retain];
        return nil;
      }
    }
  }

  RELEASE_TO_NIL(lastHitName);
  return result;
}

@end
