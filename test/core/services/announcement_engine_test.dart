import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/announcement_engine.dart';
import 'package:tankstellen/core/services/voice_announcement_service.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../fixtures/stations.dart';

// ---------------------------------------------------------------------------
// Fake TTS service for unit tests
// ---------------------------------------------------------------------------

class _FakeVoiceAnnouncementService implements VoiceAnnouncementService {
  final List<AnnouncementCandidate> announced = [];
  bool initialized = false;
  bool stopped = false;
  bool disposed = false;
  String? language;
  bool shouldThrow = false;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<void> announce(AnnouncementCandidate candidate) async {
    if (shouldThrow) throw Exception('TTS engine unavailable');
    announced.add(candidate);
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> dispose() async => disposed = true;

  @override
  Future<void> setLanguage(String languageCode) async =>
      language = languageCode;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Extract diesel price from station, defaulting to 0 for missing prices.
double _dieselPrice(Station s) => s.diesel ?? 0;

/// Use the `dist` field as km distance.
double _distKm(Station s) => s.dist;

void main() {
  late _FakeVoiceAnnouncementService fakeTts;
  late AnnouncementEngine engine;

  /// A fixed clock that can be advanced for cooldown tests.
  DateTime fakeNow = DateTime(2026, 4, 8, 12, 0);

  setUp(() {
    fakeTts = _FakeVoiceAnnouncementService();
    fakeNow = DateTime(2026, 4, 8, 12, 0);
    engine = AnnouncementEngine(
      ttsService: fakeTts,
      config: const AnnouncementConfig(
        enabled: true,
        proximityRadiusKm: 2.0,
        cooldown: Duration(minutes: 30),
      ),
      clock: () => fakeNow,
    );
  });

  group('AnnouncementEngine', () {
    test('announces closest station within radius', () async {
      final results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      expect(results, hasLength(1));
      // station-cheap is 0.8 km (closest within 2 km radius)
      expect(results.first.station.id, 'station-cheap');
      expect(results.first.fuelType, 'Diesel');
      expect(results.first.price, 1.599);
      expect(results.first.distanceKm, 0.8);
      expect(fakeTts.announced, hasLength(1));
    });

    test('does not announce when disabled', () async {
      engine.updateConfig(const AnnouncementConfig(enabled: false));

      final results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      expect(results, isEmpty);
      expect(fakeTts.announced, isEmpty);
    });

    test('filters stations outside radius', () async {
      // Only station-cheap (0.8 km) is within 1 km
      engine.updateConfig(const AnnouncementConfig(
        enabled: true,
        proximityRadiusKm: 1.0,
      ));

      final results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      expect(results, hasLength(1));
      expect(results.first.station.id, 'station-cheap');
    });

    test('filters stations above price threshold', () async {
      engine.updateConfig(const AnnouncementConfig(
        enabled: true,
        proximityRadiusKm: 5.0,
        priceThreshold: 1.60,
      ));

      final results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      // station-cheap has diesel 1.599 (below 1.60)
      // station-mid has diesel 1.659 (above 1.60)
      expect(results, hasLength(1));
      expect(results.first.station.id, 'station-cheap');
    });

    test('respects cooldown for same station', () async {
      // First announcement succeeds
      await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );
      expect(fakeTts.announced, hasLength(1));

      // Advance time by 10 minutes (within 30-min cooldown)
      fakeNow = fakeNow.add(const Duration(minutes: 10));

      final results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      // station-cheap is on cooldown; station-mid at 2.3 km is just over 2.0 radius
      // so nothing gets announced
      expect(results, isEmpty);
      expect(fakeTts.announced, hasLength(1)); // still only the first
    });

    test('announces again after cooldown expires', () async {
      await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      // Advance past cooldown
      fakeNow = fakeNow.add(const Duration(minutes: 31));

      final results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      expect(results, hasLength(1));
      expect(results.first.station.id, 'station-cheap');
      expect(fakeTts.announced, hasLength(2));
    });

    test('clearCooldowns allows immediate re-announcement', () async {
      await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      engine.clearCooldowns();
      expect(engine.cooldownCount, 0);

      final results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      expect(results, hasLength(1));
      expect(fakeTts.announced, hasLength(2));
    });

    test('skips stations with zero or null price', () async {
      final stationsWithNullPrice = [
        const Station(
          id: 'no-price',
          name: 'No Price Station',
          brand: 'TEST',
          street: 'Teststr.',
          postCode: '10115',
          place: 'Berlin',
          lat: 52.52,
          lng: 13.40,
          dist: 0.5,
          diesel: null,
          isOpen: true,
        ),
      ];

      final results = await engine.evaluateAndAnnounce(
        nearbyStations: stationsWithNullPrice,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      expect(results, isEmpty);
    });

    test('handles TTS error gracefully', () async {
      fakeTts.shouldThrow = true;

      final results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );

      // Returns empty because announce threw, but no exception propagates
      expect(results, isEmpty);
    });

    test('purges expired cooldowns automatically', () async {
      await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );
      expect(engine.cooldownCount, 1);

      // Advance past cooldown
      fakeNow = fakeNow.add(const Duration(minutes: 31));

      // Trigger purge via another evaluate call
      await engine.evaluateAndAnnounce(
        nearbyStations: [],
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );
      expect(engine.cooldownCount, 0);
    });

    test('updateConfig changes behavior at runtime', () async {
      // Start disabled
      engine.updateConfig(const AnnouncementConfig(enabled: false));
      var results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );
      expect(results, isEmpty);

      // Enable at runtime
      engine.updateConfig(const AnnouncementConfig(enabled: true));
      results = await engine.evaluateAndAnnounce(
        nearbyStations: testStationList,
        fuelType: 'Diesel',
        priceExtractor: _dieselPrice,
        distanceExtractor: _distKm,
      );
      expect(results, hasLength(1));
    });
  });

  group('AnnouncementConfig', () {
    test('default values', () {
      const config = AnnouncementConfig();
      expect(config.enabled, false);
      expect(config.proximityRadiusKm, 2.0);
      expect(config.cooldown, const Duration(minutes: 30));
      expect(config.priceThreshold, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const config = AnnouncementConfig(
        enabled: true,
        proximityRadiusKm: 3.0,
        priceThreshold: 1.50,
      );

      final updated = config.copyWith(proximityRadiusKm: 5.0);
      expect(updated.enabled, true);
      expect(updated.proximityRadiusKm, 5.0);
      expect(updated.priceThreshold, 1.50);
      expect(updated.cooldown, const Duration(minutes: 30));
    });
  });

  group('AnnouncementCandidate', () {
    test('stores all fields', () {
      const candidate = AnnouncementCandidate(
        station: testStation,
        fuelType: 'Diesel',
        price: 1.659,
        distanceKm: 1.5,
      );

      expect(candidate.station.id, testStation.id);
      expect(candidate.fuelType, 'Diesel');
      expect(candidate.price, 1.659);
      expect(candidate.distanceKm, 1.5);
    });
  });
}
