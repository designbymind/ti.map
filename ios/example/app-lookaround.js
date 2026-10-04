/**
 * Ti.Map Look Around device test app
 *
 * Tests every LookAroundView-specific property, method, and event, plus the
 * module-level availability, image, and dialog APIs. Requires iOS 16 or later.
 */

var Map = require('ti.map');

var coordinates = {
	sanFrancisco: {
		latitude: 37.7955,
		longitude: -122.3937
	},
	newYork: {
		latitude: 40.7580,
		longitude: -73.9855
	}
};

var activeCoordinate = coordinates.sanFrancisco;
var activeBadgePosition = Map.LOOK_AROUND_BADGE_POSITION_TOP_LEADING;
var activePointOfInterestFilter = true;
var logLines = [];

var win = Ti.UI.createWindow({
	title: 'Look Around API Test',
	backgroundColor: '#f2f2f7'
});

var navigationWindow = Ti.UI.iOS.createNavigationWindow({
	window: win
});

var content = Ti.UI.createScrollView({
	layout: 'vertical',
	contentHeight: Ti.UI.SIZE,
	showVerticalScrollIndicator: true
});

var statusLabel = Ti.UI.createLabel({
	text: 'Waiting for Look Around…',
	color: '#222222',
	font: { fontSize: 12 },
	left: 16,
	right: 16,
	top: 12,
	height: Ti.UI.SIZE
});

function log(message) {
	var timestamp = new Date().toLocaleTimeString();
	logLines.unshift(timestamp + '  ' + message);
	logLines = logLines.slice(0, 7);
	statusLabel.text = logLines.join('\n');
	Ti.API.info('[LOOK_AROUND_TEST] ' + message);
}

function addHeading(text) {
	content.add(Ti.UI.createLabel({
		text: text,
		color: '#555555',
		font: { fontSize: 13, fontWeight: 'semibold' },
		left: 16,
		right: 16,
		top: 18,
		bottom: 6,
		height: Ti.UI.SIZE
	}));
}

function addButton(title, callback) {
	var button = Ti.UI.createButton({
		title: title,
		left: 16,
		right: 16,
		top: 6,
		height: 44
	});
	button.addEventListener('click', callback);
	content.add(button);
	return button;
}

function addSwitch(title, initialValue, callback) {
	var row = Ti.UI.createView({
		left: 16,
		right: 16,
		top: 6,
		height: 44,
		backgroundColor: '#ffffff',
		borderRadius: 10
	});
	var label = Ti.UI.createLabel({
		text: title,
		color: '#222222',
		left: 12,
		width: Ti.UI.SIZE,
		height: Ti.UI.SIZE
	});
	var toggle = Ti.UI.createSwitch({
		value: initialValue,
		right: 12
	});
	toggle.addEventListener('change', function (event) {
		callback(event.value);
	});
	row.add(label);
	row.add(toggle);
	content.add(row);
	return toggle;
}

function addTabbedBar(labels, initialIndex, callback) {
	var tabbedBar = Ti.UI.iOS.createTabbedBar({
		labels: labels,
		index: initialIndex,
		left: 16,
		right: 16,
		top: 6,
		height: 38
	});
	tabbedBar.addEventListener('click', function (event) {
		callback(event.index);
	});
	content.add(tabbedBar);
	return tabbedBar;
}

// All writable LookAroundView-specific properties are supplied here.
var preview = Map.createLookAroundView({
	// Inherited Titanium.UI.View layout and appearance properties.
	left: 16,
	right: 16,
	top: 16,
	height: 225,
	borderRadius: 16,
	backgroundColor: '#d1d1d6',
	opacity: 0,

	// LookAroundView properties.
	coordinate: activeCoordinate,
	navigationEnabled: true,
	showsRoadLabels: true,
	pointOfInterestFilter: activePointOfInterestFilter,
	badgePosition: activeBadgePosition,
	snapshotSize: {
		width: 640,
		height: 400
	},
	snapshotScale: 2,
	snapshotInterfaceStyle: 'system',
	snapshotPointOfInterestFilter: {
		mode: 'all'
	}
});

var eventNames = [
	'lookaroundloadstart',
	'lookaroundload',
	'lookaroundunavailable',
	'lookarounderror',
	'lookaroundwillupdatescene',
	'lookaroundsceneupdated',
	'lookaroundwillopen',
	'lookaroundopen',
	'lookaroundwillclose',
	'lookaroundclose'
];

eventNames.forEach(function (eventName) {
	preview.addEventListener(eventName, function (event) {
		var detail = event.error ? ': ' + event.error : '';
		log(eventName + detail);

		if (eventName === 'lookaroundloadstart') {
			preview.opacity = 0;
		} else if (eventName === 'lookaroundload') {
			preview.animate({ opacity: 1, duration: 180 });
		} else if (eventName === 'lookaroundunavailable' || eventName === 'lookarounderror') {
			preview.opacity = 0;
		}
	});
});

content.add(preview);
content.add(statusLabel);

addHeading('Read-only state and scene methods');

addButton('Read available and loading', function () {
	log('available=' + preview.available + ', loading=' + preview.loading);
});

addButton('Reload current coordinate', function () {
	preview.reload();
	log('reload() called');
});

addButton('Cancel active requests', function () {
	preview.cancel();
	log('cancel() called');
});

addHeading('Coordinates');

addButton('San Francisco using coordinate', function () {
	activeCoordinate = coordinates.sanFrancisco;
	preview.coordinate = activeCoordinate;
	log('coordinate property set to San Francisco');
});

addButton('New York using latitude and longitude', function () {
	activeCoordinate = coordinates.newYork;
	preview.coordinate = null;
	preview.latitude = activeCoordinate.latitude;
	preview.longitude = activeCoordinate.longitude;
	log('latitude and longitude properties set to New York');
});

addHeading('Interactive viewer options');

addSwitch('Navigation enabled', true, function (value) {
	preview.navigationEnabled = value;
	log('navigationEnabled=' + value);
});

addSwitch('Show road labels', true, function (value) {
	preview.showsRoadLabels = value;
	log('showsRoadLabels=' + value);
});

addHeading('Apple badge position');

addTabbedBar(['Top leading', 'Top trailing', 'Bottom trailing'], 0, function (index) {
	var positions = [
		Map.LOOK_AROUND_BADGE_POSITION_TOP_LEADING,
		Map.LOOK_AROUND_BADGE_POSITION_TOP_TRAILING,
		Map.LOOK_AROUND_BADGE_POSITION_BOTTOM_TRAILING
	];
	activeBadgePosition = positions[index];
	preview.badgePosition = activeBadgePosition;
	log('badgePosition=' + index);
});

addHeading('Interactive POI filter');

addTabbedBar(['All', 'None', 'Food'], 0, function (index) {
	if (index === 0) {
		activePointOfInterestFilter = true;
	} else if (index === 1) {
		activePointOfInterestFilter = false;
	} else {
		activePointOfInterestFilter = {
			includedCategories: [
				'MKPOICategoryRestaurant',
				'MKPOICategoryCafe',
				'MKPOICategoryBakery'
			]
		};
	}
	preview.pointOfInterestFilter = activePointOfInterestFilter;
	log('pointOfInterestFilter mode=' + ['all', 'none', 'food'][index]);
});

addHeading('Snapshot defaults');

addTabbedBar(['System', 'Light', 'Dark'], 0, function (index) {
	var styles = ['system', 'light', 'dark'];
	preview.snapshotInterfaceStyle = styles[index];
	log('snapshotInterfaceStyle=' + styles[index]);
});

addButton('Use 640×400 snapshots at 2×', function () {
	preview.snapshotSize = { width: 640, height: 400 };
	preview.snapshotScale = 2;
	log('snapshotSize=640×400, snapshotScale=2');
});

addButton('Snapshot POIs: exclude parking', function () {
	preview.snapshotPointOfInterestFilter = {
		excludedCategories: ['MKPOICategoryParking']
	};
	log('snapshotPointOfInterestFilter excludes parking');
});

var snapshotImage = Ti.UI.createImageView({
	left: 16,
	right: 16,
	top: 10,
	height: 190,
	borderRadius: 12,
	backgroundColor: '#d1d1d6',
	contentMode: Ti.UI.CONTENT_MODE_ASPECT_FILL
});

addButton('takeSnapshot() using defaults', function () {
	preview.takeSnapshot({
		success: function (result) {
			snapshotImage.image = result.image;
			log('takeSnapshot default success');
		},
		error: function (result) {
			log('takeSnapshot error: ' + result.error);
		}
	});
});

addButton('takeSnapshot() with every override', function () {
	preview.takeSnapshot({
		size: { width: 480, height: 300 },
		scale: 3,
		interfaceStyle: 'dark',
		pointOfInterestFilter: { mode: 'none' },
		callback: function (result) {
			if (result.success) {
				snapshotImage.image = result.image;
			}
			log('override callback success=' + result.success);
		},
		success: function () {
			log('override success callback');
		},
		error: function (result) {
			log('override error callback: ' + result.error);
		}
	});
});

content.add(snapshotImage);

addHeading('Module-level Look Around APIs');

addButton('Check availability', function () {
	Map.isLookAroundAvailable({
		coordinate: activeCoordinate,
		callback: function (result) {
			log('isLookAroundAvailable: success=' + result.success + ', available=' + result.available);
		}
	});
});

addButton('Get static Look Around image', function () {
	Map.getLookAroundImage({
		coordinate: activeCoordinate,
		size: { width: 480, height: 300 },
		scale: 2,
		interfaceStyle: 'light',
		pointOfInterestFilter: activePointOfInterestFilter,
		callback: function (result) {
			if (result.success) {
				snapshotImage.image = result.image;
			}
			log('getLookAroundImage: success=' + result.success + ', available=' + result.available);
		}
	});
});

addButton('Open Look Around dialog', function () {
	Map.openLookAroundDialog({
		coordinate: activeCoordinate,
		navigationEnabled: true,
		showsRoadLabels: true,
		pointOfInterestFilter: activePointOfInterestFilter,
		badgePosition: activeBadgePosition,
		animated: true,
		callback: function (result) {
			log('openLookAroundDialog: success=' + result.success + ', available=' + result.available);
		}
	});
});

content.add(Ti.UI.createView({ height: 36 }));
win.add(content);

win.addEventListener('close', function () {
	preview.cancel();
});

navigationWindow.open();
