const Map = require('ti.map');
const IOS = (Ti.Platform.osname === 'iphone' || Ti.Platform.osname === 'ipad');

if (IOS) {
	describe('ti.map Look Around', () => {
		let preview;

		beforeAll(() => {
			preview = Map.createLookAroundView({
				coordinate: {
					latitude: 37.7955,
					longitude: -122.3937,
				},
				navigationEnabled: true,
				showsRoadLabels: true,
				badgePosition: Map.LOOK_AROUND_BADGE_POSITION_TOP_LEADING,
				snapshotSize: { width: 320, height: 180 },
				snapshotInterfaceStyle: 'system',
			});
		});

		it('exposes module-level Look Around APIs', () => {
			expect(Map.createLookAroundView).toEqual(jasmine.any(Function));
			expect(Map.isLookAroundAvailable).toEqual(jasmine.any(Function));
			expect(Map.getLookAroundImage).toEqual(jasmine.any(Function));
			expect(Map.openLookAroundDialog).toEqual(jasmine.any(Function));
		});

		it('exposes badge-position constants', () => {
			expect(Map.LOOK_AROUND_BADGE_POSITION_TOP_LEADING).toEqual(jasmine.any(Number));
			expect(Map.LOOK_AROUND_BADGE_POSITION_TOP_TRAILING).toEqual(jasmine.any(Number));
			expect(Map.LOOK_AROUND_BADGE_POSITION_BOTTOM_TRAILING).toEqual(jasmine.any(Number));
		});

		it('creates a LookAroundView proxy', () => {
			expect(preview.apiName).toEqual('Ti.Map.LookAroundView');
			expect(preview.reload).toEqual(jasmine.any(Function));
			expect(preview.cancel).toEqual(jasmine.any(Function));
			expect(preview.takeSnapshot).toEqual(jasmine.any(Function));
			expect(preview.available).toEqual(jasmine.any(Boolean));
			expect(preview.loading).toEqual(jasmine.any(Boolean));
		});
	});
}
