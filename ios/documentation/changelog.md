# Change Log

## 7.5.0

- Added opt-in resolved local search with Place IDs, alternate IDs, full addresses, and coordinates for each result.
- Added request-scoped callbacks, cancellation, and stale-response protection without changing autocomplete behavior.
- Guarded completion-result Place IDs at iOS 18 and included alternate identifiers and full postal address details.
- Added an interactive resolved-search example and documented the search/cancellation API.

## 7.4.14

- Added native title and subtitle labels to featured marker annotations without changing the compact or selected balloon geometry.
- Added featured-marker support for `markerTitleVisibility` and `markerSubtitleVisibility`, including adaptive subtitle visibility during selection.
- Preserved the geographic coordinate anchor while rendering labels outside the annotation's compact layout and collision bounds.
- Added runtime refresh support for featured-marker title and subtitle changes.
- Styled featured-marker title and subtitle labels with bold native fonts and removed the outlined-text treatment.
- Added theme-aware label colors and soft drop shadows: dark text with a light shadow in light mode, and light text with a dark shadow in dark mode.
- Restored compact annotation bounds and restricted hit testing to the compact circle or selected balloon and anchor dot, excluding labels and empty layout space from MapKit's selectable range.

## 7.4.13

- Zoom-control drags now start at the current map camera distance without jumping to the touched position. `zoomRange` sets the levels across the track; `relativeZoomEnabled: false` restores absolute positioning.
- Added a configurable horizontal bar handle with spring expansion, contraction on release, and delayed fade. `thumbStyle: 'circle'` restores the original shape.
- Added `activationDelay` to require a short stationary hold and `hitWidth` to restrict touch interception to a narrow strip beside the track.
- Anchored `activationDelay` to the hardware touch timestamp so UIKit delivery latency on physical devices does not extend the configured hold.
- Prevented the relative thumb position from flashing at its absolute camera-progress position after an invisible-idle control is released.
- Kept finger position independent of camera-distance synchronization during a drag and added cleanup when the control leaves its window.

## 7.4.12

- Documented `Map.View.selectableMapFeatures` as runtime-updatable for changing interactive Apple Maps feature types.
- Fixed selectable-feature option-mask initialization when configuring the map during creation.

## 7.4.11

- Added `Map.createZoomControl()` for an invisible-when-idle, always-touchable native vertical zoom control.
- Added accumulated `Map.View.zoomBy()` and absolute `Map.View.zoomTo()` camera-distance APIs.
- Added `cameraDistance` and native zoom lifecycle events.

⚠️ Important note: This changelog has been replaced by the official Github [releases tab](https://github.com/appcelerator-modules/ti.map/releases). 

```
v2.12.0 Support peek-and-pop in annotations [TIMOB-24375]
v2.11.0 Support for overlay patterns [MOD-2346]
v2.10.0 Support "touchEnabled" for overlays, add "mapclick" event [MOD-2322], [MOD-2268]
v2.9.0  Support "opacity" for circles
v2.5.0  Add iOS 9 mapTypes 'HYBRID_FLYOVER_TYPE' and 'SATELLITE_FLYOVER_TYPE'. [MOD-2152]
v2.4.1  Fixed an issue where pins have not been draggable anymore. [MOD-2131]
v2.4.0  iOS 9: Upgrade map module to support bitcode. [TIMOB-19385]
v2.3.2  Fixed map crash with polygons when not setting mapType. [TIMOB-19102]
v2.3.1  Add drawing support. Includes polygons, polylines, and circles. [TIMOB-15410]
        Fixes longclick event on iOS. [Github #41]
v2.2.2  Fixed map annotations showing undeclared buttons in iOS7 [TIMOB-17953]

v2.2.1  Fixed map draggable map pins [TIMOB-18510]

v2.2.0  Updated to build for 64-bit [TIMOB-17928]
        Adding architectures to manifest [TIMOB-18065]

v2.0.6  Fixed map not responding to touch after animating camera [TIMOB-17749]

v2.0.5  Fixed exception when setting "centerCoordinate" on camera [TIMOB-17659]

v2.0.4  Fixed "userLocation" permissions for iOS 8 [TIMOB-17665]
        Bumping minsdk to 3.4.0 [MOD-1968]

v2.0.2  Fixed ignoring userLocation property during view creation [TIMOB-12733]

v2.0.1  Fixed annotation not showing leftButton rightButton [TC-3524]

v2.0.0  Fixed methods deprecated in iOS 7 [MOD-1521]
        Add Support for iOS7 MapCamera [MOD-1523]
        Expose new iOS7 properties and methods of MapView [MOD-1522]
        Fixed map view with percentage values become grayed when rotating the screen [MOD-1613]

v1.0.0  Moved out of the Titanium SDK to a standalone module [MOD-1514]
```
