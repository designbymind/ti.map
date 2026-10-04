/**
 * Ti.Map 7.4.14 iOS feature showcase
 *
 * This is a self-contained Classic Titanium app.js intended for device testing
 * and sharing with other Titanium developers.
 *
 * For the user-location tests, add this to tiapp.xml:
 *
 * <ios>
 *   <plist>
 *     <dict>
 *       <key>NSLocationWhenInUseUsageDescription</key>
 *       <string>Your location is shown on the map.</string>
 *     </dict>
 *   </plist>
 * </ios>
 *
 * Run on iOS 18 or later to exercise every feature, including
 * search({ regionPriority: 'required' }). Look Around requires iOS 16+.
 */

var Map = require('ti.map');

var IOS_MAJOR_VERSION = parseInt(Ti.Platform.version.split('.')[0], 10);
var MAP_CENTER = {
	latitude: 33.6846,
	longitude: -117.8265
};
var REMOTE_MARKER_IMAGE = 'https://picsum.photos/id/1025/300/300';
var REMOTE_USER_IMAGE_A = 'https://picsum.photos/id/1027/300/300';
var REMOTE_USER_IMAGE_B = 'https://picsum.photos/id/64/300/300';

var activeCoordinate = MAP_CENTER;
var paddingExpanded = false;
var compassMoved = false;
var selectableFeaturesEnabled = false;
var statusTimer;

function normalShadow() {
	return {
		enabled: true,
		color: '#000000',
		opacity: 0.18,
		radius: 2.5,
		offset: { x: 0, y: 1 }
	};
}

function selectedShadow() {
	return {
		enabled: true,
		color: '#000000',
		opacity: 0.32,
		radius: 6,
		offset: { x: 0, y: 3 }
	};
}

var cityGeoJSON = {
	jsonContent: {
		type: 'FeatureCollection',
		features: [
			{
				type: 'Feature',
				properties: {
					title: 'Sample city polygon',
					subtitle: 'GeoJSON Polygon'
				},
				geometry: {
					type: 'Polygon',
					coordinates: [[
						[-117.8665, 33.7150],
						[-117.7865, 33.7150],
						[-117.7865, 33.6550],
						[-117.8665, 33.6550],
						[-117.8665, 33.7150]
					]]
				}
			},
			{
				type: 'Feature',
				properties: {
					title: 'Sample districts',
					subtitle: 'GeoJSON MultiPolygon'
				},
				geometry: {
					type: 'MultiPolygon',
					coordinates: [
						[[
							[-117.8560, 33.7070],
							[-117.8390, 33.7070],
							[-117.8390, 33.6940],
							[-117.8560, 33.6940],
							[-117.8560, 33.7070]
						]],
						[[
							[-117.8130, 33.6770],
							[-117.7960, 33.6770],
							[-117.7960, 33.6640],
							[-117.8130, 33.6640],
							[-117.8130, 33.6770]
						]]
					]
				}
			}
		]
	},
	strokeColorPolygon: '#5b2cff',
	fillColorPolygon: '#665b2cff',
	lineWidthPolygon: 2,
	alphaValuePolygon: 0.65,
	strokeColorPolyLine: '#ff2d55',
	lineWidthPolyLine: 3,
	alphaValuePolyLine: 0.9
};

var featuredAnnotation = Map.createAnnotation({
	latitude: MAP_CENTER.latitude,
	longitude: MAP_CENTER.longitude,
	title: 'Remote featured marker',
	subtitle: 'Tap to test the spring selection animation',
	image: REMOTE_MARKER_IMAGE,
	showAsFeaturedMarker: true,
	markerTitleVisibility: Map.FEATURE_VISIBILITY_VISIBLE,
	markerSubtitleVisibility: Map.FEATURE_VISIBILITY_ADAPTIVE,
	featuredMarkerShadow: normalShadow(),
	featuredMarkerSelectedShadow: selectedShadow(),
	canShowCallout: false
});

var win = Ti.UI.createWindow({
	title: 'Ti.Map 7.4.14 Showcase',
	backgroundColor: '#f2f2f7'
});

var navigationWindow = Ti.UI.iOS.createNavigationWindow({
	window: win
});

var mapView = Map.createView({
	mapType: Map.NORMAL_TYPE,
	region: {
		latitude: MAP_CENTER.latitude,
		longitude: MAP_CENTER.longitude,
		latitudeDelta: 0.09,
		longitudeDelta: 0.09
	},
	annotations: [featuredAnnotation],
	geoJSON: cityGeoJSON,
	userLocation: false,
	userLocationSelectedImage: REMOTE_USER_IMAGE_A,
	compassEnabled: true,
	compassPosition: { top: 14, right: 14 },
	padding: {
		top: 0,
		left: 0,
		bottom: 0,
		right: 0
	}
});

var statusLabel = Ti.UI.createLabel({
	text: 'Loading map…',
	left: 78,
	right: 78,
	bottom: 16,
	height: 42,
	borderRadius: 12,
	backgroundColor: '#dd000000',
	color: '#ffffff',
	font: { fontSize: 11, fontWeight: 'semibold' },
	textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
	verticalAlign: Ti.UI.TEXT_VERTICAL_ALIGNMENT_CENTER,
	zIndex: 20
});

function showStatus(message) {
	clearTimeout(statusTimer);
	statusLabel.text = message;
	statusLabel.opacity = 1;
	Ti.API.info('[TI_MAP_SHOWCASE] ' + message);
	statusTimer = setTimeout(function () {
		statusLabel.animate({ opacity: 0.35, duration: 200 });
	}, 2200);
}

var zoomControl = Map.createZoomControl({
	mapView: mapView,
	right: 0,
	top: 100,
	bottom: 100,
	width: 120,
	relativeZoomEnabled: true,
	zoomRange: 10,
	activationDelay: 120,
	hitWidth: 20,
	thumbStyle: 'bar',
	thumbWidth: 110,
	thumbCornerRadius: 4,
	animationDuration: 220,
	minimumDistance: 40,
	maximumDistance: 4000000,
	trackColor: '#ffffff',
	thumbColor: '#ffffff',
	trackWidth: 2,
	thumbSize: 32,
	trackOpacity: 0,
	activeTrackOpacity: 0.55,
	thumbOpacity: 0,
	activeThumbOpacity: 1,
	idleDelay: 650,
	hapticsEnabled: true,
	hapticInterval: 0.1,
	levelIndicators: [
		{ progress: 0.05, title: '🌎' },
		{ progress: 0.30, title: '✈️' },
		{ progress: 0.55, title: '🚗' },
		{ progress: 0.78, title: '🏘️' },
		{ progress: 0.95, title: '🏠' }
	],
	zIndex: 15
});

['zoomstart', 'zoomchange', 'zoomend'].forEach(function (eventName) {
	zoomControl.addEventListener(eventName, function (event) {
		if (eventName !== 'zoomchange') {
			showStatus('Slider ' + eventName + ' • ' + Math.round(event.distance) + ' m');
		}
	});
});

['zoomstart', 'zoomend'].forEach(function (eventName) {
	mapView.addEventListener(eventName, function (event) {
		showStatus('Map ' + eventName + ' • interactive=' + event.interactive);
	});
});

mapView.addEventListener('complete', function () {
	zoomControl.sync();
	showStatus('Map ready • cameraDistance=' + Math.round(mapView.cameraDistance) + ' m');
});

mapView.addEventListener('click', function (event) {
	if (event.annotation === featuredAnnotation) {
		showStatus('Featured remote-image marker tapped');
	}
});

mapView.addEventListener('poiclick', function (event) {
	var name = event.name || event.title || 'Apple Maps POI';
	showStatus('POI selected: ' + name);
});

mapView.addEventListener('poideselect', function () {
	showStatus('Apple Maps POI deselected');
});

mapView.addEventListener('userlocationannotationselected', function (event) {
	showStatus('User location selected: ' + event.latitude.toFixed(5) + ', ' + event.longitude.toFixed(5));
});

mapView.addEventListener('userlocationannotationdeselected', function (event) {
	showStatus('User location deselected: ' + event.latitude.toFixed(5) + ', ' + event.longitude.toFixed(5));
});

function createRoundButton(title) {
	return Ti.UI.createButton({
		title: title,
		width: 54,
		height: 54,
		borderRadius: 14,
		backgroundColor: '#eeffffff',
		color: '#111111',
		font: { fontSize: 28, fontWeight: 'bold' }
	});
}

var zoomButtons = Ti.UI.createView({
	left: 14,
	bottom: 14,
	width: 54,
	height: 110,
	layout: 'vertical',
	zIndex: 15
});
var zoomInButton = createRoundButton('+');
var zoomOutButton = createRoundButton('−');

zoomInButton.addEventListener('click', function () {
	mapView.zoomBy({
		level: 1,
		duration: 240,
		minimumDistance: 40,
		maximumDistance: 4000000
	});
});

zoomOutButton.addEventListener('click', function () {
	mapView.zoomBy({
		level: -1,
		duration: 240,
		minimumDistance: 40,
		maximumDistance: 4000000
	});
});

zoomButtons.add(zoomInButton);
zoomButtons.add(zoomOutButton);

function createToolbarButton(title) {
	return Ti.UI.createButton({
		title: title,
		width: '32%',
		height: 40,
		backgroundColor: '#eeffffff',
		color: '#111111',
		borderRadius: 11,
		font: { fontSize: 13, fontWeight: 'semibold' }
	});
}

var toolbar = Ti.UI.createView({
	left: 10,
	right: 78,
	top: 10,
	height: 40,
	layout: 'horizontal',
	horizontalWrap: false,
	zIndex: 15
});
var searchButton = createToolbarButton('Search');
var lookAroundButton = createToolbarButton('Look Around');
var toolsButton = createToolbarButton('Tools');
toolbar.add(searchButton);
toolbar.add(lookAroundButton);
toolbar.add(toolsButton);

function enableUserLocation() {
	var permission = Ti.Geolocation.AUTHORIZATION_WHEN_IN_USE;

	try {
		if (Ti.Geolocation.hasLocationPermissions(permission)) {
			mapView.userLocation = true;
			showStatus('User location enabled');
			return;
		}

		Ti.Geolocation.requestLocationPermissions(permission, function (event) {
			if (event.success) {
				mapView.userLocation = true;
				showStatus('User location permission granted');
			} else {
				showStatus('User location unavailable: ' + (event.error || 'permission denied'));
			}
		});
	} catch (error) {
		showStatus('Add NSLocationWhenInUseUsageDescription to tiapp.xml');
	}
}

function createSearchResultRow(result) {
	var row = Ti.UI.createTableViewRow({
		height: 64,
		backgroundColor: '#ffffff'
	});
	row.add(Ti.UI.createLabel({
		text: result.title,
		left: 16,
		right: 16,
		top: 9,
		height: 22,
		color: '#111111',
		font: { fontSize: 16, fontWeight: 'semibold' }
	}));
	row.add(Ti.UI.createLabel({
		text: result.subtitle || '',
		left: 16,
		right: 16,
		top: 32,
		height: 20,
		color: '#666666',
		font: { fontSize: 13 }
	}));
	return row;
}

function openSearchWindow() {
	var searchWin = Ti.UI.createWindow({
		title: 'Region-prioritized search',
		backgroundColor: '#f2f2f7'
	});
	var searchField = Ti.UI.createTextField({
		top: 10,
		left: 12,
		right: 12,
		height: 44,
		borderStyle: Ti.UI.INPUT_BORDERSTYLE_ROUNDED,
		hintText: 'Try “coffee” or “Apple Store”',
		clearButtonMode: Ti.UI.INPUT_BUTTONMODE_ONFOCUS,
		returnKeyType: Ti.UI.RETURNKEY_SEARCH
	});
	var searchInfo = Ti.UI.createLabel({
		text: IOS_MAJOR_VERSION >= 18
			? 'regionPriority: required (iOS 18+)'
			: 'iOS < 18: MapKit uses its default region bias',
		top: 59,
		left: 16,
		right: 16,
		height: 28,
		color: '#666666',
		font: { fontSize: 12 }
	});
	var resultsTable = Ti.UI.createTableView({
		top: 88,
		bottom: 0
	});
	var completionResults = [];
	var debounceTimer;

	function didUpdateResults(event) {
		completionResults = event.results || [];
		resultsTable.setData(completionResults.map(createSearchResultRow));
		if (event.error) {
			showStatus('Search error: ' + event.error);
		}
	}

	Map.addEventListener('didUpdateResults', didUpdateResults);

	searchField.addEventListener('change', function (event) {
		clearTimeout(debounceTimer);
		var query = (event.value || '').trim();
		if (query.length < 2) {
			completionResults = [];
			resultsTable.setData([]);
			return;
		}

		debounceTimer = setTimeout(function () {
			Map.search(query, {
				region: {
					latitude: MAP_CENTER.latitude,
					longitude: MAP_CENTER.longitude,
					latitudeDelta: 0.35,
					longitudeDelta: 0.35
				},
				regionPriority: 'required',
				resultTypes: [
					Map.SEARCH_RESULT_TYPE_ADDRESS,
					Map.SEARCH_RESULT_TYPE_POINT_OF_INTEREST
				]
			});
		}, 250);
	});

	resultsTable.addEventListener('click', function (event) {
		var selectedIndex = event.index;
		if (!completionResults[selectedIndex]) {
			return;
		}

		if (typeof Map.searchForCompletionResult !== 'function') {
			showStatus('searchForCompletionResult() is unavailable');
			return;
		}

		Map.searchForCompletionResult({
			index: selectedIndex,
			callback: function (result) {
				if (!result.success) {
					showStatus('Place resolution failed: ' + result.error);
					return;
				}

				activeCoordinate = {
					latitude: result.latitude,
					longitude: result.longitude
				};
				var resultAnnotation = Map.createAnnotation({
					latitude: result.latitude,
					longitude: result.longitude,
					title: result.name || completionResults[selectedIndex].title,
					subtitle: result.identifier || result.pointOfInterestCategory || '',
					image: REMOTE_MARKER_IMAGE,
					showAsFeaturedMarker: true,
					featuredMarkerShadow: normalShadow(),
					featuredMarkerSelectedShadow: selectedShadow(),
					canShowCallout: false
				});
				mapView.addAnnotation(resultAnnotation);
				mapView.setLocation({
					latitude: result.latitude,
					longitude: result.longitude,
					latitudeDelta: 0.025,
					longitudeDelta: 0.025,
					animate: true
				});
				showStatus('Resolved place: ' + (result.name || 'Unnamed place'));
				navigationWindow.closeWindow(searchWin);
			}
		});
	});

	searchWin.addEventListener('close', function () {
		clearTimeout(debounceTimer);
		Map.removeEventListener('didUpdateResults', didUpdateResults);
	});

	searchWin.add(searchField);
	searchWin.add(searchInfo);
	searchWin.add(resultsTable);
	navigationWindow.openWindow(searchWin);
	searchWin.addEventListener('open', function () {
		searchField.focus();
	});
}

function openLookAroundWindow() {
	if (IOS_MAJOR_VERSION < 16) {
		alert('Look Around requires iOS 16 or later.');
		return;
	}

	var lookWin = Ti.UI.createWindow({
		title: 'Look Around',
		backgroundColor: '#f2f2f7'
	});
	var scrollView = Ti.UI.createScrollView({
		layout: 'vertical',
		contentHeight: Ti.UI.SIZE
	});
	var preview = Map.createLookAroundView({
		left: 16,
		right: 16,
		top: 16,
		height: 240,
		borderRadius: 16,
		opacity: 0,
		coordinate: activeCoordinate,
		navigationEnabled: true,
		showsRoadLabels: true,
		pointOfInterestFilter: true,
		badgePosition: Map.LOOK_AROUND_BADGE_POSITION_BOTTOM_TRAILING,
		snapshotSize: { width: 640, height: 400 },
		snapshotScale: 2,
		snapshotInterfaceStyle: 'system',
		snapshotPointOfInterestFilter: { mode: 'all' }
	});
	var lookStatus = Ti.UI.createLabel({
		text: 'Requesting Look Around…',
		left: 16,
		right: 16,
		top: 10,
		height: Ti.UI.SIZE,
		color: '#555555'
	});
	var snapshotImage = Ti.UI.createImageView({
		left: 16,
		right: 16,
		top: 10,
		height: 190,
		borderRadius: 14,
		backgroundColor: '#d1d1d6',
		contentMode: Ti.UI.CONTENT_MODE_ASPECT_FILL
	});
	var badgeIndex = 2;

	function addLookButton(title, handler) {
		var button = Ti.UI.createButton({
			title: title,
			left: 16,
			right: 16,
			top: 8,
			height: 44
		});
		button.addEventListener('click', handler);
		scrollView.add(button);
	}

	preview.addEventListener('lookaroundload', function () {
		lookStatus.text = 'Loaded. Drag inside the preview or tap to expand.';
		preview.animate({ opacity: 1, duration: 180 });
	});
	preview.addEventListener('lookaroundunavailable', function () {
		lookStatus.text = 'Look Around is unavailable at this coordinate.';
	});
	preview.addEventListener('lookarounderror', function (event) {
		lookStatus.text = event.error;
	});
	['lookaroundwillopen', 'lookaroundopen', 'lookaroundwillclose', 'lookaroundclose'].forEach(function (eventName) {
		preview.addEventListener(eventName, function () {
			lookStatus.text = eventName;
		});
	});

	scrollView.add(preview);
	scrollView.add(lookStatus);

	addLookButton('Cycle Apple badge position', function () {
		var positions = [
			Map.LOOK_AROUND_BADGE_POSITION_TOP_LEADING,
			Map.LOOK_AROUND_BADGE_POSITION_TOP_TRAILING,
			Map.LOOK_AROUND_BADGE_POSITION_BOTTOM_TRAILING
		];
		badgeIndex = (badgeIndex + 1) % positions.length;
		preview.badgePosition = positions[badgeIndex];
		lookStatus.text = 'Badge position index: ' + badgeIndex;
	});

	addLookButton('Take snapshot from loaded scene', function () {
		preview.takeSnapshot({
			size: { width: 640, height: 400 },
			scale: 2,
			interfaceStyle: 'dark',
			pointOfInterestFilter: { mode: 'all' },
			success: function (result) {
				snapshotImage.image = result.image;
				lookStatus.text = 'Snapshot created';
			},
			error: function (result) {
				lookStatus.text = result.error;
			}
		});
	});

	addLookButton('Check Look Around availability', function () {
		Map.isLookAroundAvailable({
			coordinate: activeCoordinate,
			callback: function (result) {
				lookStatus.text = 'Availability: success=' + result.success + ', available=' + result.available;
			}
		});
	});

	addLookButton('Get module-level Look Around image', function () {
		Map.getLookAroundImage({
			coordinate: activeCoordinate,
			size: { width: 640, height: 400 },
			scale: 2,
			interfaceStyle: 'light',
			pointOfInterestFilter: { mode: 'all' },
			callback: function (result) {
				if (result.success) {
					snapshotImage.image = result.image;
				}
				lookStatus.text = 'Static image: success=' + result.success + ', available=' + result.available;
			}
		});
	});

	addLookButton('Open standalone Look Around dialog', function () {
		Map.openLookAroundDialog({
			coordinate: activeCoordinate,
			navigationEnabled: true,
			showsRoadLabels: true,
			pointOfInterestFilter: true,
			badgePosition: Map.LOOK_AROUND_BADGE_POSITION_TOP_LEADING,
			animated: true,
			callback: function (result) {
				lookStatus.text = 'Dialog success=' + result.success + ', available=' + result.available;
			}
		});
	});

	scrollView.add(snapshotImage);
	scrollView.add(Ti.UI.createView({ height: 32 }));
	lookWin.add(scrollView);
	lookWin.addEventListener('close', function () {
		preview.cancel();
	});
	navigationWindow.openWindow(lookWin);
}

function createToolRow(title, handler) {
	var row = Ti.UI.createTableViewRow({
		title: title,
		height: 52,
		hasChild: true
	});
	return {
		row: row,
		handler: handler
	};
}

function openToolsWindow() {
	var toolsWin = Ti.UI.createWindow({
		title: 'Runtime feature tests',
		backgroundColor: '#f2f2f7'
	});
	var rows = [
		createToolRow('Select featured marker', function () {
			mapView.selectAnnotation(featuredAnnotation);
		}),
		createToolRow('Deselect featured marker', function () {
			mapView.deselectAnnotation(featuredAnnotation);
		}),
		createToolRow('Disable featured-marker shadows', function () {
			featuredAnnotation.featuredMarkerShadow = { enabled: false };
			featuredAnnotation.featuredMarkerSelectedShadow = { enabled: false };
		}),
		createToolRow('Restore featured-marker shadows', function () {
			featuredAnnotation.featuredMarkerShadow = normalShadow();
			featuredAnnotation.featuredMarkerSelectedShadow = selectedShadow();
		}),
		createToolRow('Select user-location annotation', function () {
			mapView.selectUserLocationAnnotation(true);
		}),
		createToolRow('Deselect user-location annotation', function () {
			mapView.deselectUserLocationAnnotation(true);
		}),
		createToolRow('Use remote user image A', function () {
			mapView.userLocationSelectedImage = REMOTE_USER_IMAGE_A;
		}),
		createToolRow('Use remote user image B at runtime', function () {
			mapView.userLocationSelectedImage = REMOTE_USER_IMAGE_B;
		}),
		createToolRow('Restore native user silhouette', function () {
			mapView.userLocationSelectedImage = null;
		}),
		createToolRow('Animate map padding', function () {
			paddingExpanded = !paddingExpanded;
			mapView.padding = {
				top: paddingExpanded ? 110 : 0,
				left: paddingExpanded ? 42 : 0,
				bottom: paddingExpanded ? 90 : 0,
				right: paddingExpanded ? 42 : 0,
				animated: true,
				duration: 600
			};
		}),
		createToolRow('Move native compass', function () {
			compassMoved = !compassMoved;
			mapView.compassPosition = compassMoved
				? { left: 16, bottom: 150 }
				: { top: 14, right: 14 };
		}),
		createToolRow('Restore automatic compass placement', function () {
			mapView.compassPosition = null;
		}),
		createToolRow('zoomTo() 2,000 meters', function () {
			mapView.zoomTo({
				distance: 2000,
				animated: true,
				duration: 500,
				minimumDistance: 40,
				maximumDistance: 4000000
			});
		}),
		createToolRow('Set zoom slider to 80%', function () {
			zoomControl.setProgress({
				progress: 0.8,
				animated: true,
				duration: 500
			});
		}),
		createToolRow('Sync slider with map camera', function () {
			zoomControl.sync();
			showStatus('progress=' + zoomControl.progress.toFixed(3) + ', distance=' + Math.round(zoomControl.distance) + ' m');
		}),
		createToolRow('Toggle selectable map features', function () {
			selectableFeaturesEnabled = !selectableFeaturesEnabled;
			mapView.selectableMapFeatures = selectableFeaturesEnabled ? [
				Map.FEATURE_POINT_OF_INTEREST,
				Map.FEATURE_PHYSICAL_FEATURES,
				Map.FEATURE_TERRITORIES
			] : [];
		}),
		createToolRow('Reset map region', function () {
			activeCoordinate = MAP_CENTER;
			mapView.setLocation({
				latitude: MAP_CENTER.latitude,
				longitude: MAP_CENTER.longitude,
				latitudeDelta: 0.09,
				longitudeDelta: 0.09,
				animate: true
			});
		})
	];
	var table = Ti.UI.createTableView({
		data: rows.map(function (item) {
			return item.row;
		})
	});
	table.addEventListener('click', function (event) {
		var item = rows[event.index];
		if (item && typeof item.handler === 'function') {
			item.handler();
			showStatus(item.row.title);
		}
	});
	toolsWin.add(table);
	navigationWindow.openWindow(toolsWin);
}

searchButton.addEventListener('click', openSearchWindow);
lookAroundButton.addEventListener('click', openLookAroundWindow);
toolsButton.addEventListener('click', openToolsWindow);

win.add(mapView);
win.add(zoomControl);
win.add(zoomButtons);
win.add(toolbar);
win.add(statusLabel);

win.addEventListener('open', function () {
	enableUserLocation();
	setTimeout(function () {
		zoomControl.sync();
	}, 500);
});

win.addEventListener('close', function () {
	clearTimeout(statusTimer);
});

navigationWindow.open();
