/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiMapView.h"
#import <MapKit/MapKit.h>
#import <TitaniumKit/ImageLoader.h>
#import <TitaniumKit/TiBase.h>

@class TiMapAnnotationProxy;

@interface TiMapFeaturedAnnotationView : MKAnnotationView <TiMapAnnotation, ImageLoaderDelegate> {
  @private
  NSString *lastHitName;
  UIView *normalMarkerView;
  UIView *selectedMarkerView;
  UIImageView *normalImageView;
  UIImageView *selectedImageView;
  UIView *labelContainerView;
  UILabel *titleLabel;
  UILabel *subtitleLabel;
  CAShapeLayer *normalBackgroundLayer;
  CAShapeLayer *selectedBackgroundLayer;
  CALayer *anchorDotLayer;
  ImageLoaderRequest *imageRequest;
  MKFeatureVisibility titleVisibility;
  MKFeatureVisibility subtitleVisibility;
}

+ (CGPoint)defaultCenterOffset;

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier map:(TiMapView *)map;
- (CGPoint)defaultCenterOffset;
- (void)setImageSource:(id)imageSource proxy:(TiMapAnnotationProxy *)proxy;
- (void)setMarkerShadow:(id)markerShadow selectedMarkerShadow:(id)selectedMarkerShadow;
- (void)setTitle:(NSString *)title
              subtitle:(NSString *)subtitle
       titleVisibility:(MKFeatureVisibility)titleVisibility
    subtitleVisibility:(MKFeatureVisibility)subtitleVisibility;
- (NSString *)lastHitName;

@end
