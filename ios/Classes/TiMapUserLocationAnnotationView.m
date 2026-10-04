/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-Present by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiMapUserLocationAnnotationView.h"
#import <TitaniumKit/TiUtils.h>

// MapKit does not publish an avatar property for MKUserLocationView. Locate its
// selected portrait slot by geometry instead of referencing private classes or
// selectors. If MapKit changes that structure, the lookup safely fails and the
// native generic silhouette remains visible.
static UIView *TiMapFindSelectedImageHost(UIView *root, CGRect *imageFrame)
{
  for (UIView *candidate in root.subviews) {
    CGFloat width = CGRectGetWidth(candidate.bounds);
    CGFloat height = CGRectGetHeight(candidate.bounds);
    if (width >= 48.0 && width <= 80.0 && fabs(width - height) <= 2.0) {
      for (UIView *content in candidate.subviews.reverseObjectEnumerator) {
        CGFloat contentWidth = CGRectGetWidth(content.bounds);
        CGFloat contentHeight = CGRectGetHeight(content.bounds);
        if ([content isKindOfClass:[UIImageView class]] && contentWidth >= 42.0 && contentWidth < width && fabs(contentWidth - contentHeight) <= 2.0) {
          *imageFrame = content.frame;
          return candidate;
        }
      }
    }

    UIView *host = TiMapFindSelectedImageHost(candidate, imageFrame);
    if (host != nil) {
      return host;
    }
  }
  return nil;
}

@interface TiMapUserLocationAnnotationView ()

- (void)applyImage:(UIImage *)image animated:(BOOL)animated;
- (void)cancelPendingImageLoad;
- (void)createSelectedImageViewIfNeeded;
- (BOOL)installSelectedImageIfPossible;

@end

@implementation TiMapUserLocationAnnotationView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
  if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
    self.clipsToBounds = NO;
  }
  return self;
}

- (void)dealloc
{
  [self cancelPendingImageLoad];
  RELEASE_TO_NIL(selectedImageView);
  [super dealloc];
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  [self cancelPendingImageLoad];
  [selectedImageView removeFromSuperview];
  RELEASE_TO_NIL(selectedImageView);
}

- (void)createSelectedImageViewIfNeeded
{
  if (selectedImageView != nil) {
    return;
  }

  selectedImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  selectedImageView.backgroundColor = [UIColor clearColor];
  selectedImageView.contentMode = UIViewContentModeScaleAspectFill;
  selectedImageView.clipsToBounds = YES;
  selectedImageView.userInteractionEnabled = NO;
  selectedImageView.hidden = YES;
}

- (BOOL)installSelectedImageIfPossible
{
  if (!self.selected || selectedImageView.image == nil) {
    return NO;
  }

  CGRect nativeImageFrame = CGRectZero;
  UIView *host = TiMapFindSelectedImageHost(self, &nativeImageFrame);
  if (host == nil) {
    return NO;
  }

  if (selectedImageView.superview != host) {
    [selectedImageView removeFromSuperview];
    [host addSubview:selectedImageView];
  }
  selectedImageView.frame = nativeImageFrame;
  selectedImageView.layer.cornerRadius = CGRectGetWidth(nativeImageFrame) / 2.0;
  selectedImageView.hidden = NO;
  [host bringSubviewToFront:selectedImageView];
  return YES;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [self installSelectedImageIfPossible];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  BOOL selectionChanged = self.selected != selected;

  [super setSelected:selected animated:animated];
  [self setNeedsLayout];
  [self layoutIfNeeded];

  if (selected) {
    [self installSelectedImageIfPossible];
    if (selectionChanged) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.selected) {
          [self installSelectedImageIfPossible];
        }
      });
    }
  } else if (!animated) {
    [selectedImageView removeFromSuperview];
    selectedImageView.hidden = YES;
  } else if (selectionChanged) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      if (!self.selected) {
        [self->selectedImageView removeFromSuperview];
        self->selectedImageView.hidden = YES;
      }
    });
  }
}

- (void)cancelPendingImageLoad
{
  if (imageRequest != nil) {
    [imageRequest cancel];
    RELEASE_TO_NIL(imageRequest);
  }
}

- (void)setSelectedImageSource:(id)imageSource proxy:(TiProxy *)proxy
{
  [self cancelPendingImageLoad];

  if (imageSource == nil || imageSource == [NSNull null]) {
    [selectedImageView removeFromSuperview];
    RELEASE_TO_NIL(selectedImageView);
    return;
  }

  [self createSelectedImageViewIfNeeded];

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
  [self createSelectedImageViewIfNeeded];
  void (^updates)(void) = ^{
    self->selectedImageView.image = image;
    [self installSelectedImageIfPossible];
  };

  if (animated && self.selected) {
    [UIView transitionWithView:selectedImageView
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
          NSLog(@"[WARN] Unable to load selected user-location image from %@: %@", request.url, error.localizedDescription);
          RELEASE_TO_NIL(self->imageRequest);
        }
      },
      NO);
}

- (void)imageLoadCancelled:(ImageLoaderRequest *)request
{
}

@end
