exports.title = 'Look Around';

exports.run = function (UI, Map) {
	var win = UI.createWindow('Look Around');
	var coordinate = {
		latitude: 37.7955,
		longitude: -122.3937
	};

	var map = Map.createView({
		region: {
			latitude: coordinate.latitude,
			longitude: coordinate.longitude,
			latitudeDelta: 0.02,
			longitudeDelta: 0.02
		}
	});

	var preview = Map.createLookAroundView({
		left: 16,
		bottom: 24,
		width: 190,
		height: 125,
		borderRadius: 12,
		opacity: 0,
		coordinate: coordinate,
		navigationEnabled: true,
		showsRoadLabels: true,
		badgePosition: Map.LOOK_AROUND_BADGE_POSITION_TOP_LEADING
	});

	preview.addEventListener('lookaroundloadstart', function () {
		preview.opacity = 0;
	});

	preview.addEventListener('lookaroundload', function () {
		preview.animate({ opacity: 1, duration: 180 });
	});

	preview.addEventListener('lookaroundunavailable', function () {
		preview.opacity = 0;
		Ti.API.info('Look Around is unavailable at this coordinate.');
	});

	preview.addEventListener('lookarounderror', function (event) {
		preview.opacity = 0;
		Ti.API.error(event.error);
	});

	win.add(map);
	win.add(preview);
};
