exports.title = 'Resolved local search';

exports.run = function (UI, Map) {
	var win = UI.createWindow('Resolved local search');
	var requestId = 'resolved-search-example-' + Date.now();
	var searchBar = Ti.UI.createSearchBar({ top: 0, hintText: 'Find places near Irvine' });
	var status = Ti.UI.createLabel({ top: 60, height: 40, left: 12, right: 12, text: 'Enter at least 2 characters.' });
	var table = Ti.UI.createTableView({ top: 100 });
	var debounceTimer;
	var generation = 0;
	var closed = false;

	function cancel() {
		generation++;
		clearTimeout(debounceTimer);
		Map.cancelSearch({ requestId: requestId });
	}

	searchBar.addEventListener('change', function (e) {
		cancel();
		var query = e.value.trim();
		var currentGeneration = generation;
		table.data = [];
		if (query.length < 2) {
			status.text = 'Enter at least 2 characters.';
			return;
		}
		status.text = 'Searching…';
		debounceTimer = setTimeout(function () {
			Map.search(query, {
				mode: 'resolved',
				requestId: requestId,
				region: { latitude: 33.6846, longitude: -117.8265, latitudeDelta: 0.2, longitudeDelta: 0.2 },
				regionPriority: 'required',
				resultTypes: [Map.SEARCH_RESULT_TYPE_POINT_OF_INTEREST],
				callback: function (response) {
					if (closed || currentGeneration !== generation) {
						return;
					}
					status.text = response.success ? response.results.length + ' places. Tap for IDs and details.' : response.error;
					table.data = response.results.map(function (place) {
						return Ti.UI.createTableViewRow({ title: place.name + '\n' + place.address.replace(/\n/g, ', '), mapItem: place, height: 80 });
					});
				}
			});
		}, 350);
	});
	table.addEventListener('click', function (e) {
		if (e.rowData.mapItem) {
			alert(JSON.stringify(e.rowData.mapItem, null, 2));
		}
	});
	win.addEventListener('close', function () {
		closed = true;
		cancel();
	});
	win.add(searchBar);
	win.add(status);
	win.add(table);
};
