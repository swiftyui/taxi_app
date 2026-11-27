import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/services/destination_query.dart';
import 'package:TaxiApp/src/core/services/destination_search_history.dart';
import 'package:TaxiApp/src/core/services/destination_search_service.dart';
import 'package:TaxiApp/src/core/services/osm_geocoding_service.dart';
import 'package:TaxiApp/src/core/services/photon_place_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _menlyn = DestinationSearchResult(
  label: 'Menlyn Park Shopping Centre',
  subtitle: 'Pretoria',
  position: LatLng(-25.783, 28.277),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('matches swapped letters, partial words, and accents', () {
    expect(
      DestinationQuery('mabopnae stat').score('Mabopane Station'),
      isNotNull,
    );
    expect(DestinationQuery('Mnel').score(_menlyn.label), isNotNull);
    expect(
      DestinationQuery('menlyn pretoria').score('Pretória, Menlyn'),
      isNotNull,
    );
    expect(DestinationQuery('menlyn durban').score('Menlyn Pretoria'), isNull);
    expect(DestinationQuery('124 Church').score('125 Church Street'), isNull);
  });

  test(
    'ranks an exact spelling ahead of a fuzzy match and merges nearby duplicates',
    () {
      final geocoding = _GeocodingStub();
      final service = DestinationSearchService(geocoding: geocoding);
      final matches = service.suggestions(
        query: 'Menlyn',
        taxiRoutes: [
          _route('Menlym Taxi Rank'),
          _route('Menlyn Taxi Rank'),
          _route('Menlyn Taxi Rank', longitude: 28.2771),
        ],
        recentSearches: const [
          RecentDestinationSearch('the mall', destination: _menlyn),
        ],
      );
      expect(matches.map((result) => result.label), [
        _menlyn.label,
        'Menlyn Taxi Rank',
        'Menlym Taxi Rank',
      ]);
      expect(
        service.suggestions(
          query: 'teh mlal',
          taxiRoutes: [],
          recentSearches: const [
            RecentDestinationSearch('the mall', destination: _menlyn),
          ],
        ),
        [_menlyn],
      );
      expect(geocoding.calls, 0);
    },
  );

  test(
    'keeps local matches available when lookup fails and reuses online results',
    () async {
      final geocoding = _GeocodingStub()..isOffline = true;
      final service = DestinationSearchService(geocoding: geocoding);
      expect(await service.search(query: 'Menlyn', localResults: [_menlyn]), [
        _menlyn,
      ]);

      geocoding.isOffline = false;
      final matches = await service.search(
        query: 'Menlyn',
        localResults: [_menlyn],
      );
      expect(matches, [_menlyn]);
      expect(
        (await service.search(query: 'menlyn')).single.label,
        _menlyn.label,
      );
      expect(geocoding.calls, 2);
    },
  );

  test('looks up an unfamiliar typo on Photon and caches the result', () async {
    final geocoding = _GeocodingStub();
    var requests = 0;
    final photon = PhotonPlaceSearch(
      client: MockClient((request) async {
        requests++;
        expect(request.url.host, 'photon.komoot.io');
        expect(request.url.queryParameters, {
          'q': 'Pretroia Zoo',
          'countrycode': 'ZA',
          'limit': '6',
        });
        return http.Response('''
            {"features": [
              {"properties": {"name": "Pretoria Zoo", "housenumber": 232,
                "street": "Boom Street", "city": "Pretoria", "countrycode": "ZA"},
                "geometry": {"type": "Point", "coordinates": [28.189, -25.738]}},
              {"properties": {"name": "Other zoo", "countrycode": "US"},
                "geometry": {"type": "Point", "coordinates": [-71, 42]}},
              {"properties": {"name": "Invalid location"},
                "geometry": {"type": "Point", "coordinates": ["?", 42]}}
            ]}
          ''', 200);
      }),
    );
    final service = DestinationSearchService(
      geocoding: geocoding,
      photon: photon,
    );

    expect(await service.liveSuggestions('Pr'), isEmpty);
    final suggestions = await service.liveSuggestions('Pretroia Zoo');
    expect(suggestions.single.label, 'Pretoria Zoo');
    expect(suggestions.single.subtitle, '232 Boom Street, Pretoria');
    expect(suggestions.single.position, const LatLng(-25.738, 28.189));
    expect(await service.liveSuggestions('pretroia zoo '), same(suggestions));
    expect(requests, 1);
    expect(geocoding.calls, 0);
  });

  test(
    'can retry a failed live lookup without losing local suggestions',
    () async {
      var requests = 0;
      final service = DestinationSearchService(
        photon: PhotonPlaceSearch(
          client: MockClient((_) async {
            requests++;
            return requests == 1
                ? http.Response('', 429)
                : http.Response('{"features":[]}', 200);
          }),
        ),
      );

      await expectLater(
        service.liveSuggestions('Menlyn'),
        throwsA(isA<http.ClientException>()),
      );
      expect(
        service.mergeSuggestions(query: 'Menlyn', local: [_menlyn], online: []),
        [_menlyn],
      );
      expect(await service.liveSuggestions('Menlyn'), isEmpty);
      expect(requests, 2);
    },
  );

  test(
    'ranks nearby fuzzy matches first and keeps a clearly named distant place',
    () {
      const near = LatLng(-25.7932, 28.30945);
      const nearby = DestinationSearchResult(
        label: 'Central Taxi Rank',
        subtitle: 'Pretoria',
        position: LatLng(-25.8, 28.3),
      );
      const distant = DestinationSearchResult(
        label: 'Central Taxi Rank',
        subtitle: 'Cape Town',
        position: LatLng(-33.9, 18.4),
      );
      final service = DestinationSearchService();
      expect(
        service.mergeSuggestions(
          query: 'Cnetral Taxi',
          local: [distant],
          online: [nearby],
          near: near,
        ),
        [nearby, distant],
      );
      expect(
        service
            .mergeSuggestions(
              query: 'Central Taxi Rank Cape Town',
              local: [nearby],
              online: [distant],
              near: near,
            )
            .first,
        distant,
      );
      expect(
        service.suggestions(
          query: 'Cnetral Taxi',
          taxiRoutes: [],
          savedPlaces: [distant, nearby],
          near: near,
        ),
        [nearby, distant],
      );
    },
  );

  test(
    'shares only an approximate area and keeps live caches separate by region',
    () async {
      final requests = <Map<String, String>>[];
      final service = DestinationSearchService(
        photon: PhotonPlaceSearch(
          client: MockClient((request) async {
            requests.add(request.url.queryParameters);
            return http.Response('{"features":[]}', 200);
          }),
        ),
      );

      await service.liveSuggestions(
        'Taxi rank',
        near: const LatLng(-25.7932, 28.30945),
      );
      await service.liveSuggestions(
        'taxi rank',
        near: const LatLng(-25.814, 28.323),
      );
      await service.liveSuggestions(
        'Taxi rank',
        near: const LatLng(-33.9249, 18.4241),
      );
      expect(requests, [
        {
          'q': 'Taxi rank',
          'countrycode': 'ZA',
          'limit': '6',
          'lat': '-25.8',
          'lon': '28.3',
          'location_bias_scale': '0.15',
        },
        {
          'q': 'Taxi rank',
          'countrycode': 'ZA',
          'limit': '6',
          'lat': '-33.9',
          'lon': '18.4',
          'location_bias_scale': '0.15',
        },
      ]);
    },
  );

  test(
    'persists previous terms and selected destinations with MRU ordering',
    () async {
      SharedPreferences.setMockInitialValues({
        'recentSearches': ['Mabopane Station', '{invalid'],
      });
      final history = DestinationSearchHistory();
      await Future.wait([
        history.record('Menlyn Park'),
        history.record('Menlyn Park', destination: _menlyn),
      ]);
      await history.record('Pretoria Zoo');
      await history.record('menlyn park');

      final stored = await DestinationSearchHistory().load();
      expect(stored.map((item) => item.query), [
        'menlyn park',
        'Pretoria Zoo',
        'Mabopane Station',
      ]);
      expect(stored.first.destination?.position, _menlyn.position);
      expect(stored[1].destination, isNull);
      expect(await history.clear(), isEmpty);
      expect(await DestinationSearchHistory().load(), isEmpty);
    },
  );
}

class _GeocodingStub extends OsmGeocodingService {
  int calls = 0;
  bool isOffline = false;

  @override
  Future<List<OsmPlace>> search(
    String query, {
    String country = 'South Africa',
  }) async {
    calls++;
    if (isOffline) {
      throw const HttpException('Offline');
    }
    return [
      OsmPlace(
        label: _menlyn.label,
        subtitle: _menlyn.subtitle,
        position: _menlyn.position,
      ),
    ];
  }
}

TaxiRouteModel _route(String destination, {double longitude = 28.277}) =>
    TaxiRouteModel.fromDriverRoute(
      DriverRoute(
        id: destination,
        driverId: 'test',
        originName: 'Start rank',
        destinationName: destination,
        origin: const GeoPoint(-25.7, 28.1),
        destination: GeoPoint(-25.783, longitude),
        fare: 12,
        serviceDays: const ['Monday'],
        departureTime: '08:00',
        notes: '',
        associationName: 'Test',
        seatCapacity: 10,
        createdAt: null,
      ),
    );
