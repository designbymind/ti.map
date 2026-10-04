# Notes

## Code Updates
* The following has not been pushed to GitHub repository.

* 1. Added ability to get Place (MKMapItem) details from an autocomplete string's index.
    * See: /ios/Classes/TiMapModule.m (lines 258-344)
* 2. Added GeoJSON Overlay support
* 3. Added additional place details (subthroughfare, etc) to the "poiclick" event.
* 4. Added iOS 18+ `regionPriority` support to `search()` so `required` searches exclude completions outside the supplied region.
* 5. Added an opt-in Apple Maps-style featured annotation marker with local, blob, and remote image support plus spring selection animations.
* 6. Documented the runtime-updatable `selectableMapFeatures` property for changing selectable Apple Maps feature types.

## Legal

Copyright (c) 2025 DesignByMind LLC.
