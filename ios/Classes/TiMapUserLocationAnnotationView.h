/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <MapKit/MapKit.h>
#import <TitaniumKit/ImageLoader.h>
#import <TitaniumKit/TiBase.h>

@class TiProxy;

API_AVAILABLE(ios(14.0))
@interface TiMapUserLocationAnnotationView : MKUserLocationView <ImageLoaderDelegate> {
  @private
  UIImageView *selectedImageView;
  ImageLoaderRequest *imageRequest;
}

- (void)setSelectedImageSource:(id)imageSource proxy:(TiProxy *)proxy;

@end
