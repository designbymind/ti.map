#ifndef TI_MAP_ZOOM_CONTROL_MATH_H
#define TI_MAP_ZOOM_CONTROL_MATH_H

#include <math.h>

// One level halves camera distance. The gesture origin always keeps its initial distance.
static inline double TiMapRelativeZoomDistance(double initialDistance, double initialProgress,
    double touchProgress, double levels, double minimum, double maximum)
{
  double target = initialDistance * exp2((initialProgress - touchProgress) * levels);
  return fmin(maximum, fmax(minimum, target));
}

// UIKit can deliver touchesBegan after the hardware touch timestamp, especially while native
// gesture recognizers arbitrate on device. Count that elapsed time toward the requested hold.
static inline double TiMapZoomActivationRemainingDelay(double configuredDelay, double touchTimestamp, double systemUptime)
{
  double elapsed = fmax(0, systemUptime - touchTimestamp);
  return fmax(0, configuredDelay - elapsed);
}

#endif
