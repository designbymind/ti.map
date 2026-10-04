/**
 * Original Ti.Map example launcher.
 *
 * Rename this file to app.js to restore the full example menu.
 */

var IOS = Ti.Platform.osname === 'iphone' || Ti.Platform.osname === 'ipad';
var IOS11 = IOS && parseInt(Ti.Platform.version.split('.')[0], 10) >= 11;
var ANDROID = Ti.Platform.osname === 'android';
var UI = require('ui');
var Map = require('ti.map');

var rows = [
	require('/tests/multiMap'),
	require('/tests/annotations'),
	require('/tests/routes'),
	require('/tests/drawing')
];

if (IOS) {
	rows.push(require('/tests/camera'));
	rows.push(require('/tests/properties'));
	rows.push(require('/tests/lookaround'));
	rows.push(require('/tests/lookaround-table'));
	rows.push(require('/tests/zoom-control'));
	rows.push(require('/tests/resolved-search'));

	if (IOS11) {
		rows.push(require('/tests/clustering'));
	}
}

if (ANDROID && Map.isGooglePlayServicesAvailable() !== Map.SUCCESS) {
	alert('Google Play Services is not installed/updated/available');
} else {
	UI.init(rows, function (event) {
		rows[event.index].run && rows[event.index].run(UI, Map);
	});
}
