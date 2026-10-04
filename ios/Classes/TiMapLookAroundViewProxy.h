/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <TitaniumKit/TiViewProxy.h>

@interface TiMapLookAroundViewProxy : TiViewProxy

@property (nonatomic, readonly) NSNumber *available;
@property (nonatomic, readonly) NSNumber *loading;

- (void)reload:(id)unused;
- (void)cancel:(id)unused;
- (void)takeSnapshot:(id)args;

@end
