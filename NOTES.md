# Notes

## Code Updates
* These local additions are preserved in the 7.5.0 fork reconciliation.

* 1. Added ability to get Place (MKMapItem) details from an autocomplete string's index.
    * See `ios/Classes/TiMapModule.m`, `searchForCompletionResult`.
* 2. Added GeoJSON Overlay support
* 3. Added additional place details (subthroughfare, etc) to the "poiclick" event.
* 4. Added iOS 18+ `regionPriority` support to `search()` so `required` searches exclude completions outside the supplied region.
* 5. Added an opt-in Apple Maps-style featured annotation marker with local, blob, and remote image support plus spring selection animations.
* 6. Documented the runtime-updatable `selectableMapFeatures` property for changing selectable Apple Maps feature types.

* 7. Added Look Around views and utilities, native zoom controls, and user-location styling.
* 8. Added resolved local search with request-scoped callbacks and cancellation.

## Legal

Copyright (c) 2025 DesignByMind LLC.
