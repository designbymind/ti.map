// Standalone regression checks: clang test/unit/zoom-control-math.c -o /tmp/ti-map-zoom-math && /tmp/ti-map-zoom-math
#include "../../ios/Classes/TiMapZoomControlMath.h"
#include <assert.h>
#include <stdio.h>

static void equalDistance(double actual, double expected)
{
  double tolerance = fmax(1e-12, fabs(expected) * 1e-10);
  assert(fabs(actual - expected) < tolerance);
}

int main(void)
{
  const double initial = 4096;
  // Touch-down anywhere, including both endpoints, preserves the current distance.
  for (int i = 0; i <= 10; i++) {
    double origin = i / 10.0;
    equalDistance(TiMapRelativeZoomDistance(initial, origin, origin, 10, 1, 10000000), initial);
  }
  // Midpoint: five levels in either direction, each level a factor of two.
  equalDistance(TiMapRelativeZoomDistance(initial, 0.5, 1, 10, 1, 10000000), 128);
  equalDistance(TiMapRelativeZoomDistance(initial, 0.5, 0, 10, 1, 10000000), 131072);
  // Bottom: ten levels in; top: ten levels out.
  equalDistance(TiMapRelativeZoomDistance(initial, 0, 1, 10, 1, 10000000), 4);
  equalDistance(TiMapRelativeZoomDistance(initial, 1, 0, 10, 1, 10000000), 4194304);
  // Return to the origin after dragging, independent of intermediate camera updates.
  equalDistance(TiMapRelativeZoomDistance(initial, 0.2, 0.3, 10, 1, 10000000), 2048);
  equalDistance(TiMapRelativeZoomDistance(initial, 0.2, 0.2, 10, 1, 10000000), initial);
  // Hard limits, and an initially out-of-range camera accommodated for that drag.
  equalDistance(TiMapRelativeZoomDistance(initial, 0, 1, 10, 40, 1000000), 40);
  equalDistance(TiMapRelativeZoomDistance(initial, 1, 0, 10, 40, 1000000), 1000000);
  equalDistance(TiMapRelativeZoomDistance(20, 0.5, 0.5, 10, 20, 1000000), 20);
  equalDistance(TiMapRelativeZoomDistance(20, 0.5, 0.6, 10, 20, 1000000), 20);
  // A new gesture uses the new distance, without inheriting the previous origin.
  equalDistance(TiMapRelativeZoomDistance(2048, 0.7, 0.8, 10, 1, 10000000), 1024);

  // Activation delay is measured from hardware touch-down, not delayed UIKit delivery.
  equalDistance(TiMapZoomActivationRemainingDelay(0.05, 100, 100.02), 0.03);
  equalDistance(TiMapZoomActivationRemainingDelay(0.05, 100, 100.05), 0);
  equalDistance(TiMapZoomActivationRemainingDelay(0.05, 100, 100.2), 0);
  // Guard against a timestamp clock skew without extending the configured delay.
  equalDistance(TiMapZoomActivationRemainingDelay(0.05, 100.01, 100), 0.05);
  puts("Relative zoom regression checks passed.");
  return 0;
}
