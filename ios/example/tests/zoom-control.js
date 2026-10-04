exports.title = 'Native zoom control';

// Device checks for 7.4.13:
// 1. Touch and hold in the rightmost 20 points: zoomstart waits 120ms; no zoom until movement.
//    Touch farther left: the map remains directly touchable. Move >10 points during the wait: cancel.
// 2. Start in the middle: travel allows five levels up or down, subject to distance limits.
// 3. Start at the bottom: only upward movement zooms; returning restores the starting zoom.
// 4. Release: bar contracts, then fades. Immediately re-touch during the fade to re-activate.
// 5. Zoom with +/- or a pinch, then touch at a different height: use that new camera distance.
// Set relativeZoomEnabled:false / thumbStyle:'circle' to compare the original behavior/style.

exports.run = function (UI, Map) {
	const win = UI.createWindow('Native zoom control');
	const mapView = Map.createView({
		region: {
			latitude: 33.6846,
			longitude: -117.8265,
			latitudeDelta: 0.04,
			longitudeDelta: 0.04
		}
	});
	const zoomControl = Map.createZoomControl({
		mapView: mapView,
		right: 4,
		height: 360,
		width: 120,
		relativeZoomEnabled: true,
		zoomRange: 10,
		activationDelay: 120,
		hitWidth: 20,
		thumbStyle: 'bar',
		thumbWidth: 110,
		thumbCornerRadius: 4,
		animationDuration: 220,
		trackOpacity: 0,
		activeTrackOpacity: 0.5,
		thumbOpacity: 0,
		activeThumbOpacity: 1,
		idleDelay: 600,
		levelIndicators: [
			{ progress: 0.05, title: '🌎' },
			{ progress: 0.35, title: '✈️' },
			{ progress: 0.6, title: '🚗' },
			{ progress: 0.85, title: '🏠' }
		]
	});
	const buttons = Ti.UI.createView({ left: 16, bottom: 24, width: 56, height: 112, layout: 'vertical' });
	const zoomIn = Ti.UI.createButton({ title: '+', width: 56, height: 56 });
	const zoomOut = Ti.UI.createButton({ title: '−', width: 56, height: 56 });
	zoomIn.addEventListener('click', function () {
		mapView.zoomBy({ level: 1, duration: 240 });
	});
	zoomOut.addEventListener('click', function () {
		mapView.zoomBy({ level: -1, duration: 240 });
	});
	buttons.add(zoomIn);
	buttons.add(zoomOut);
	win.add(mapView);
	win.add(zoomControl);
	win.add(buttons);
};
