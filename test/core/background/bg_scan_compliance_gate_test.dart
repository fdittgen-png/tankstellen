// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_price_source.dart';
import 'package:tankstellen/core/background/provider_request_budget.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/diagnostics/data_access_event.dart';
import 'package:tankstellen/core/services/diagnostics/data_access_recorder.dart';
import 'package:tankstellen/core/services/diagnostics/data_access_trace.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../fakes/fake_storage_repository.dart';
import '../../helpers/silence_error_logger.dart';

/// EXIT GATE (Epic #2860, child #2866).
///
/// A simulated multi-country background scan drives the real BG path
/// (`BackgroundPriceSource` → per-country `StationServiceChain`) with the #2824
/// [DataAccessRecorder] attached, then asserts the rate-limit / ToS compliance
/// contract the epic gates the DE-only-gate removal on:
///
///  - each provider gets **≤ one network round per country per scan** (the
///    once-per-country-per-scan grouping),
///  - the recorder **notes every provider's configured minInterval**, and
///  - under the **twice-daily cadence** every provider's observed interval is
///    ≥ its minInterval, so `DataAccessTrace.aggregates()` reports
///    `compliant == true` for EVERY provider — no provider is ever
///    `compliant == false`.
///
/// Plus the shared per-provider [ProviderRequestBudget] blocks a too-soon
/// background request after a foreground hit.
void main() {
  silenceErrorLoggerSpool();

  // A real [StationServiceChain] wrapping a counting fake primary for [code],
  // carrying the country's real registry policy (so the recorder notes the
  // right minInterval) + the shared recorder + budget. This is the exact chain
  // the BG isolate builds, minus the network — the counting primary stands in
  // for the upstream so the chain still records a `networkApi` event.
  StationServiceChain chainFor(
    String code,
    DataAccessRecorder recorder,
    Map<String, int> priceCalls, {
    ProviderRequestBudget? budget,
  }) {
    return StationServiceChain(
      _CountingPrimary(code, priceCalls),
      CacheManager(FakeStorageRepository()),
      countryCode: code,
      policy: CountryServiceRegistry.policyFor(code),
      recorder: recorder,
      budget: budget,
    );
  }

  group('multi-country scan compliance (#2866 EXIT GATE)', () {
    const polled = ['DE', 'AT', 'PT', 'KR', 'MX'];

    test('each polled provider is hit ≤ ONCE per scan + the recorder notes '
        'every minInterval; NO provider is compliant=false', () async {
      final recorder = DataAccessRecorder();
      final priceCalls = <String, int>{};
      final chains = {
        for (final c in polled) c: chainFor(c, recorder, priceCalls),
      };

      final source = BackgroundPriceSource(
        storage: FakeStorageRepository(),
        recorder: recorder,
        serviceBuilder: (code, {String? apiKey}) => chains[code],
      );

      // A mixed-country alert set with MANY stations per country — the grouping
      // must still collapse to one provider round per country per scan. Ids
      // carry the lowercase country prefix the registry derives country from.
      await source.fetchPricesGrouped(stationIds: [
        for (final c in polled)
          for (var i = 1; i <= 3; i++) '${c.toLowerCase()}-$i',
      ]);

      // ≤ 1 network round per country per scan.
      for (final c in polled) {
        expect(priceCalls[c], 1,
            reason: '$c provider hit exactly once for the whole scan');
      }

      // The recorder noted every provider's configured minInterval.
      for (final c in polled) {
        expect(recorder.configuredMinIntervalSec.containsKey(c), isTrue,
            reason: '$c minInterval must be noted for the compliance check');
      }

      // No provider is judged non-compliant (one round/scan → compliant is
      // null, which is the "nothing to fault" state; never false).
      final trace = recorder.build();
      for (final agg in trace.aggregates()) {
        expect(agg.compliant, isNot(false),
            reason: '${agg.country}|${agg.source} must not be non-compliant');
        expect(agg.networkCount, lessThanOrEqualTo(1),
            reason: '${agg.country} ≤ one network round per scan');
      }
    });

    test('under the twice-daily cadence EVERY provider is compliant=true — '
        'two scans 12h apart space each provider ≥ its minInterval', () {
      // Two scans at the twice-daily cadence: re-stamp the recorded per-country
      // network events 12h apart. 12h ≥ every provider minInterval (DE 1m, AT
      // 1h, PT 1h, KR 1m, MX 4h), so each observed interval clears its budget.
      const twiceDailySec = 12 * 3600.0;
      final events = <DataAccessEvent>[];
      final configured = <String, double>{};
      for (var scan = 0; scan < 2; scan++) {
        for (final c in polled) {
          final minInterval = CountryServiceRegistry.policyFor(c)!.minInterval;
          configured[c] = minInterval.inMicroseconds / 1e6;
          events.add(DataAccessEvent(
            at: DateTime.utc(2026, 1, 1).add(Duration(hours: 12 * scan)),
            monotonicMicros: (scan * twiceDailySec * 1e6).round(),
            country: c,
            source: ServiceSource.tankerkoenigApi.name,
            endpoint: DataAccessEndpoint.batchPrices,
            hit: DataAccessHit.networkApi,
          ));
        }
      }

      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 2),
        events: events,
        configuredMinIntervalSec: configured,
      );

      final aggs = trace.aggregates();
      expect(aggs.length, polled.length);
      for (final agg in aggs) {
        expect(agg.networkCount, 2, reason: '${agg.country}: two scans');
        expect(agg.compliant, isTrue,
            reason: '${agg.country} observed interval ≥ minInterval under '
                'the twice-daily cadence');
      }
    });
  });

  group('shared per-provider budget blocks a too-soon BG poll (#2866)', () {
    test('a foreground hit within minInterval makes the BG scan skip that '
        'provider — no network round; cache answers from the last fetch',
        () async {
      // Shared storage = ONE budget across foreground + background.
      final storage = FakeStorageRepository();
      final budget = ProviderRequestBudget(storage);
      final recorder = DataAccessRecorder();
      final priceCalls = <String, int>{};

      // DE minInterval is 1 minute. Foreground just hit DE 1 second ago.
      await budget.recordRequestAwait('DE',
          now: DateTime.now().subtract(const Duration(seconds: 1)));

      final chains = {
        'DE': chainFor('DE', recorder, priceCalls, budget: budget),
      };
      final source = BackgroundPriceSource(
        storage: storage,
        recorder: recorder,
        budget: budget,
        serviceBuilder: (code, {String? apiKey}) => chains[code],
      );

      final prices = await source.fetchPricesGrouped(stationIds: ['de-1']);

      // The BG scan must NOT fire — the foreground hit is within minInterval.
      expect(priceCalls['DE'] ?? 0, 0,
          reason: 'a too-soon BG poll is skipped by the shared budget');
      expect(prices, isEmpty,
          reason: 'no fresh prices this round — the foreground fetch holds');
    });

    test('a foreground hit OLDER than minInterval lets the BG scan fire',
        () async {
      final storage = FakeStorageRepository();
      final budget = ProviderRequestBudget(storage);
      final recorder = DataAccessRecorder();
      final priceCalls = <String, int>{};

      // DE last hit 2 minutes ago (> the 1-minute minInterval) → allowed.
      await budget.recordRequestAwait('DE',
          now: DateTime.now().subtract(const Duration(minutes: 2)));

      final chains = {
        'DE': chainFor('DE', recorder, priceCalls, budget: budget),
      };
      final source = BackgroundPriceSource(
        storage: storage,
        recorder: recorder,
        budget: budget,
        serviceBuilder: (code, {String? apiKey}) => chains[code],
      );

      await source.fetchPricesGrouped(stationIds: ['de-1']);
      expect(priceCalls['DE'], 1,
          reason: 'a stale-enough budget allows the BG poll');
    });
  });

  group('ProviderRequestBudget', () {
    test('canFire is true with no prior stamp, false within minInterval, '
        'true once minInterval has elapsed', () {
      final budget = ProviderRequestBudget(FakeStorageRepository());
      const min = Duration(minutes: 1);
      final now = DateTime.utc(2026, 1, 1, 12);

      expect(budget.canFire('DE', min, now: now), isTrue,
          reason: 'no stamp → always allowed');

      budget.recordRequest('DE', now: now);
      expect(budget.canFire('DE', min, now: now.add(const Duration(seconds: 30))),
          isFalse,
          reason: '30s < 1m → blocked');
      expect(budget.canFire('DE', min, now: now.add(const Duration(minutes: 2))),
          isTrue,
          reason: '2m ≥ 1m → allowed');
    });

    test('a null / zero minInterval is never throttled', () {
      final budget = ProviderRequestBudget(FakeStorageRepository());
      budget.recordRequest('DE');
      expect(budget.canFire('DE', null), isTrue);
      expect(budget.canFire('DE', Duration.zero), isTrue);
    });
  });
}

/// Counting fake primary: records how many `getPrices` rounds it served per
/// country and returns canned prices so the wrapping [StationServiceChain]
/// records a `networkApi` event the recorder can aggregate.
class _CountingPrimary implements StationService {
  _CountingPrimary(this.code, this.priceCalls);

  final String code;
  final Map<String, int> priceCalls;

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
      List<String> ids) async {
    priceCalls[code] = (priceCalls[code] ?? 0) + 1;
    return ServiceResult(
      data: {
        for (final id in ids)
          id: const StationPrices(e5: 1.5, e10: 1.4, diesel: 1.6, status: 'open'),
      },
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime(2026),
    );
  }

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async =>
      ServiceResult(
        data: const [],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime(2026),
      );

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();
}
