exports.title = 'Look Around in a table sheet';
exports.run = function (UI, Map) {
	const root = UI.createWindow('Look Around table test');
	function log(value) {
		Ti.API.info('LOOKAROUND_TEST ' + value);
	}
	const open = Ti.UI.createButton({ title: 'Open table sheet', height: 60 });
	root.add(open);
	function showSheet() {
		const win = Ti.UI.createWindow({ title: 'Look Around table', backgroundColor: 'white' });
		const nav = Ti.UI.createNavigationWindow({ window: win });
		const rows = [];
		const row = Ti.UI.createTableViewRow({ height: 270 });
		const container = Ti.UI.createView({ height: 250, left: 10, right: 10 });
		container.add(Map.createView({ region: { latitude: 37.7955, longitude: -122.3937, latitudeDelta: 0.01, longitudeDelta: 0.01 } }));
		const preview = Map.createLookAroundView({ left: 12, bottom: 12, width: 190, height: 125, borderRadius: 12 });
		['lookaroundloadstart', 'lookaroundload', 'lookaroundunavailable', 'lookarounderror', 'lookaroundopen', 'lookaroundclose'].forEach(function (eventName) {
			preview.addEventListener(eventName, function (e) {
				log(eventName + ' ' + (e.error || ''));
				if (eventName === 'lookaroundload') {
					preview.takeSnapshot({ size: { width: 192, height: 128 }, callback: function (result) { log('snapshot=' + result.success); } });
				}
			});
		});
		preview.coordinate = { latitude: 37.7955, longitude: -122.3937 };
		container.add(preview);
		row.add(container);
		rows.push(row);
		for (let i = 0; i < 30; i++) { rows.push(Ti.UI.createTableViewRow({ title: 'Scroll test ' + i, height: 65 })); }
		const table = Ti.UI.createTableView({ data: rows });
		win.add(table);
		const close = Ti.UI.createButton({ title: 'Close' });
		close.addEventListener('click', function () { nav.close(); });
		win.rightNavButton = close;
		const cycle = Ti.UI.createButton({ title: 'Cycle row' });
		let cycleTimer;
		cycle.addEventListener('click', function () {
			if (cycleTimer) { return; }
			log('remove preview');
			container.remove(preview);
			cycleTimer = setTimeout(function () {
				cycleTimer = null;
				container.add(preview);
				log('reattach preview');
			}, 500);
		});
		win.leftNavButton = cycle;
		nav.addEventListener('open', function () { log('sheet open'); });
		nav.addEventListener('close', function () {
			clearTimeout(cycleTimer);
			preview.cancel();
			log('sheet close');
		});
		nav.open({ modal: true, modalStyle: Ti.UI.iOS.MODAL_PRESENTATION_PAGESHEET });
	}
	open.addEventListener('click', showSheet);
};
