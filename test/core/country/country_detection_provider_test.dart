import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_detection_provider.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';

import '../../mocks/mocks.dart';

/// Hand-rolled fake of [GeocodingChain] that records every
/// `coordinatesToCountryCode` call and returns a script of values.
///
/// Using a fake (rather than a Mockito stub) lets us control timing
/// precisely — the re-entrancy guard test needs to hold one call open
/// while a second emission fires.
class _FakeGeocoding implements GeocodingChain {
  /// Country code returned by each successive call. Ignored when
  /// [pendingCompleter] is non-null for that call's index.
  final List<String?> codeScript;

  /// Optional completers; when set for index N, the Nth call awaits
  /// `completers[N].future` before resolving (so tests can hold a
  /// call mid-flight).
  final Map<int, Completer<String?>> pendingCompleters;

  final List<({double lat, double lng})> calls = [];

  _FakeGeocoding({
    required this.codeScript,
    this.pendingCompleters = const {},
  });

  @override
  Future<String?> coordinatesToCountryCode(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) async {
    final index = calls.length;
    calls.add((lat: lat, lng: lng));

    final pending = pendingCompleters[index];
    if (pending != null) {
      return pending.future;
    }
    if (index < codeScript.length) {
      return codeScript[index];
    }
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in tests: ${invocation.memberName}');
}

void main() {
  late MockHiveStorage mockStorage;
  final persisted = <String, dynamic>{};

  setUp(() {
    persisted.clear();
    mockStorage = MockHiveStorage();
    when(() => mockStorage.getSetting(any()))
        .thenAnswer((inv) => persisted[inv.positionalArguments.first]);
    when(() => mockStorage.putSetting(any(), any()))
        .thenAnswer((inv) async {
      final key = inv.positionalArguments.first as String;
      persisted[key] = inv.positionalArguments.last;
    });
  });

  ProviderContainer makeContainer(_FakeGeocoding geocoding) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
      geocodingChainProvider.overrideWithValue(geocoding),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('DetectedCountry.build()', () {
    test(
        'with no persisted position the state stays null and geocoding is '
        'never called', () async {
      final geocoding = _FakeGeocoding(codeScript: const []);
      final c = makeContainer(geocoding);

      // Subscribe to keep the keepAlive provider mounted while we let
      // any (non-existent) async work settle.
      final sub = c.listen(
        detectedCountryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Let any microtasks flush.
      await Future<void>.delayed(Duration.zero);

      expect(c.read(detectedCountryProvider), isNull);
      expect(geocoding.calls, isEmpty);
    });

    test(
        'when a position is persisted at build time the geocoder is '
        'called once and the state updates with the returned code',
        () async {
      persisted[StorageKeys.userPositionLat] = 48.85;
      persisted[StorageKeys.userPositionLng] = 2.35;
      persisted[StorageKeys.userPositionTimestamp] = 0;
      persisted[StorageKeys.userPositionSource] = 'GPS';

      final geocoding = _FakeGeocoding(codeScript: const ['FR']);
      final c = makeContainer(geocoding);

      final sub = c.listen(
        detectedCountryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Synchronous build returns null even though a position exists —
      // the detection runs as fire-and-forget.
      expect(c.read(detectedCountryProvider), isNull);

      // Drain the microtask queue: the async _detectCountry resolves
      // and the notifier sets state.
      await Future<void>.delayed(Duration.zero);

      expect(geocoding.calls, hasLength(1));
      expect(geocoding.calls.single.lat, 48.85);
      expect(geocoding.calls.single.lng, 2.35);
      expect(c.read(detectedCountryProvider), 'FR');
    });
  });

  group('DetectedCountry._detectCountry — branches', () {
    test(
        'geocoder returning null leaves state null even though it was '
        'called', () async {
      persisted[StorageKeys.userPositionLat] = 1.0;
      persisted[StorageKeys.userPositionLng] = 2.0;
      persisted[StorageKeys.userPositionTimestamp] = 0;

      final geocoding = _FakeGeocoding(codeScript: const [null]);
      final c = makeContainer(geocoding);

      final sub = c.listen(
        detectedCountryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);

      expect(geocoding.calls, hasLength(1));
      expect(c.read(detectedCountryProvider), isNull);
    });

    test(
        'when the geocoder returns the same code as the current state, '
        '_detectCountry takes the no-op branch (no double-set on state)',
        () async {
      persisted[StorageKeys.userPositionLat] = 1.0;
      persisted[StorageKeys.userPositionLng] = 2.0;
      persisted[StorageKeys.userPositionTimestamp] = 0;

      // First call yields 'DE'. Second position emission yields 'DE'
      // again — covers the `code != state` false-branch in
      // _detectCountry (line: `if (code != null && code != state)`).
      final geocoding = _FakeGeocoding(codeScript: const ['DE', 'DE']);
      final c = makeContainer(geocoding);

      // Track every distinct value the provider settled on. A position
      // change re-runs build() (emits null), then _detectCountry
      // resolves and either re-emits 'DE' or skips the assignment.
      // The distinct sequence we expect when the same-code branch is
      // working: null (initial) -> 'DE' -> null (rebuild) -> 'DE'.
      // What we MUST NOT see is a second 'DE' assignment after the
      // detect resolves on cycle 2 (i.e. no `null, 'DE', null, 'DE',
      // 'DE'`).
      final emissions = <String?>[];
      final sub = c.listen<String?>(
        detectedCountryProvider,
        (_, next) => emissions.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      expect(c.read(detectedCountryProvider), 'DE');

      c.read(userPositionProvider.notifier).setFromGps(3.0, 4.0);
      await Future<void>.delayed(Duration.zero);

      expect(geocoding.calls, hasLength(2));
      expect(c.read(detectedCountryProvider), 'DE');

      // Exactly one 'DE' per cycle, no duplicate 'DE' after the second
      // detect resolves — that would mean the same-code guard didn't
      // trip and `state = code` ran a second time.
      expect(emissions, [null, 'DE', null, 'DE']);
      expect(emissions.where((e) => e == 'DE').length, 2,
          reason: 'state == code guard must skip the redundant assignment');
    });

    test(
        'a position change re-runs detection with the new coordinates and '
        'updates state to the new code', () async {
      persisted[StorageKeys.userPositionLat] = 10.0;
      persisted[StorageKeys.userPositionLng] = 20.0;
      persisted[StorageKeys.userPositionTimestamp] = 0;

      final geocoding = _FakeGeocoding(codeScript: const ['DE', 'FR']);
      final c = makeContainer(geocoding);

      final sub = c.listen(
        detectedCountryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      expect(c.read(detectedCountryProvider), 'DE');

      c
          .read(userPositionProvider.notifier)
          .setFromGps(48.85, 2.35);
      await Future<void>.delayed(Duration.zero);

      expect(geocoding.calls, hasLength(2));
      expect(geocoding.calls[1].lat, 48.85);
      expect(geocoding.calls[1].lng, 2.35);
      expect(c.read(detectedCountryProvider), 'FR');
    });
  });

  group('DetectedCountry — re-entrancy guard', () {
    test(
        'a second position emission while the first geocode is still in '
        'flight does NOT fire a second concurrent geocode call', () async {
      persisted[StorageKeys.userPositionLat] = 1.0;
      persisted[StorageKeys.userPositionLng] = 2.0;
      persisted[StorageKeys.userPositionTimestamp] = 0;

      // Hold the first call open with a Completer; the second should
      // be blocked by the _detecting flag and never even reach the
      // fake.
      final firstCallGate = Completer<String?>();
      final geocoding = _FakeGeocoding(
        codeScript: const [null, 'FR'],
        pendingCompleters: {0: firstCallGate},
      );
      final c = makeContainer(geocoding);

      final sub = c.listen(
        detectedCountryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Let build run and start the first (held-open) detection.
      await Future<void>.delayed(Duration.zero);
      expect(geocoding.calls, hasLength(1));

      // Trigger a second position emission while the first call is
      // still pending — re-entrancy guard should bail out.
      c
          .read(userPositionProvider.notifier)
          .setFromGps(3.0, 4.0);
      await Future<void>.delayed(Duration.zero);

      // Still only one call recorded — the second emission was
      // swallowed by the `if (_detecting) return;` branch.
      expect(geocoding.calls, hasLength(1));

      // Resolve the first call; assert state stays null since the
      // first call's script value was null.
      firstCallGate.complete('DE');
      await Future<void>.delayed(Duration.zero);

      expect(c.read(detectedCountryProvider), 'DE');
    });

    test(
        'after a held-open call resolves, the guard releases and a '
        'subsequent position change triggers a fresh geocode', () async {
      persisted[StorageKeys.userPositionLat] = 1.0;
      persisted[StorageKeys.userPositionLng] = 2.0;
      persisted[StorageKeys.userPositionTimestamp] = 0;

      final firstCallGate = Completer<String?>();
      final geocoding = _FakeGeocoding(
        codeScript: const [null, 'IT'],
        pendingCompleters: {0: firstCallGate},
      );
      final c = makeContainer(geocoding);

      final sub = c.listen(
        detectedCountryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      expect(geocoding.calls, hasLength(1));

      // Resolve the first call (returns null → state stays null).
      firstCallGate.complete(null);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(detectedCountryProvider), isNull);

      // Now a fresh position emission should fire a brand-new call.
      c
          .read(userPositionProvider.notifier)
          .setFromGps(45.0, 9.0);
      await Future<void>.delayed(Duration.zero);

      expect(geocoding.calls, hasLength(2));
      expect(geocoding.calls[1].lat, 45.0);
      expect(geocoding.calls[1].lng, 9.0);
      expect(c.read(detectedCountryProvider), 'IT');
    });
  });
}
