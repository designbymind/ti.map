# ti.map Module

## Description

The Map module allows you to access Apple's MapKit APIs

## Accessing the map Module

To access this module from JavaScript, you would do the following:

	var Map = require("ti.map");

The `Map` variable is a reference to the Module object.	

## Getting Started

View the [Using Titanium Modules](http://docs.appcelerator.com/platform/latest/#!/guide/Using_Titanium_Modules) document for instructions on getting
started with using this module in your application.

## Requirements

Must be run using a Titanium SDK that has had Maps removed. Running against a version of the SDK that still has the Maps module will result in a build failure.

Applications using this module must be built using Xcode 5 or later.

## Usage

See documentation

## Resolved local search (iOS 7.5.0)

`Map.search(query, options)` keeps its existing autocomplete behavior by default.
Use `mode: 'resolved'` to receive actual places, including Apple Place IDs when
available, in a per-request callback:

```javascript
var requestId = 'places-screen';
Map.search('coffee', {
    mode: 'resolved',
    requestId: requestId,
    region: { latitude: 33.6846, longitude: -117.8265, latitudeDelta: 0.1, longitudeDelta: 0.1 },
    regionPriority: 'required',
    resultTypes: [Map.SEARCH_RESULT_TYPE_POINT_OF_INTEREST],
    callback: function (e) {
        if (!e.success) {
            Ti.API.warn(e.error);
            return;
        }
        e.results.forEach(function (place) {
            Ti.API.info(place.name + ': ' + place.identifier);
            Ti.API.info(place.alternateIdentifiers);
        });
    }
});
// When clearing the query or closing its screen:
Map.cancelSearch({ requestId: requestId });
```

Debounce typed input before calling search. Reusing a request ID cancels that ID's
previous request. Cancellation suppresses late callbacks, and other request IDs
and existing autocomplete searches remain independent. Resolved searches do not
emit `didUpdateResults`. Invalid options throw; network/search failures reach the
callback with `success: false`, `requestId`, `error`, `code`, and `results: []`.

Each result includes `name`, `title`, `subtitle`, `address`, `place`, `latitude`,
`longitude`, `identifier`, `alternateIdentifiers`, `pointOfInterestCategory`,
`phoneNumber`, `timeZone`, and `url`. Full mailing addresses are preserved, and
`place.postalAddress.street` preserves Apple's house number and unit/suite text.
Place IDs and alternate IDs require iOS 18; identifiers can still be null and
alternate IDs are not exhaustive. `regionPriority: 'required'` also requires
iOS 18; earlier versions use MapKit's usual region bias. Only ADDRESS and
POINT_OF_INTEREST result types apply to resolved searches.

See `example/tests/resolved-search.js` in the example menu for an interactive
search, result details, cancellation, and close cleanup.

## Documentation
* [Map Module API Reference Documentation](http://docs.appcelerator.com/platform/latest/#!/api/Modules.Map)

## Author

Jeff Haynie & Jon Alter

## Module History

View the [change log](changelog.html) for this module.

## Feedback and Support

Please direct all questions, feedback, and concerns to [info@appcelerator.com](mailto:info@appcelerator.com?subject=iOS%20Map%20Module).

## License

Copyright(c) 2013 by Appcelerator, Inc. All Rights Reserved. Please see the LICENSE file included in the distribution for further details.
