/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 */

#import <TitaniumKit/TiViewProxy.h>

@interface TiMapZoomControlProxy : TiViewProxy

@property (nonatomic, readonly) NSNumber *progress;
@property (nonatomic, readonly) NSNumber *distance;

- (void)setProgress:(id)args;
- (void)sync:(id)unused;

@end
