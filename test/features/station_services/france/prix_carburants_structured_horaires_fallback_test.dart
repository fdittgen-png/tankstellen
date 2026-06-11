// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/france/france_opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/opening_hours/opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_flux_parser.dart'
    as flux;
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart'
    as parser;
import 'package:tankstellen/features/station_services/france/prix_carburants_station_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3219 — field report: FR station detail showed opening hours ONLY for
/// 24/7 stations; per-day / non-24h schedules vanished on both platforms.
///
/// Root cause (NOT the suspected #3152 isolate copy — that path is flagged
/// off via `BulkMigrationFlags.frFluxBulk == false` and was exonerated with a
/// boundary pin below): the v2 JSON path read the schedule EXCLUSIVELY from
/// the DERIVED flattened `horaires_jour` column and ignored the canonical
/// structured `horaires` column the upstream actually maintains (the JSON
/// rendition of the flux XML tree the flux path already parses). In the
/// recorded real Paris corpus 27 of 50 records carry a null `horaires_jour`;
/// when the upstream's flattening lags/drops that derived column for records
/// that DO have a schedule, every downstream consumer goes hours-less. Only
/// the orthogonal `horaires_automate_24_24` flag survives (a separate
/// always-present column), which the legacy bridge renders as "Open 24
/// hours" — hence "only 24/7 renders". Compounding it, the adapter DISCARDED
/// that automate flag when `horaires_jour` was null (it only honoured it for
/// an EMPTY string), and FR was the one adapter #3148 left release-silent,
/// so the degradation produced zero field signal.
///
/// Fixtures: the records below are byte-identical RECORDED rows from
/// `prix_carburants_paris_geo_ordered.json` (live data.economie.gouv.fr
/// captures, #2966) with ONLY the derived `horaires_jour` column nulled —
/// exactly the shape 27 of the 50 recorded rows already exhibit — so the
/// test drives the REAL degraded payload shape through the REAL service →
/// chain → cache-codec path, per the #2776 lesson (no request-echoing fakes,
/// no adapter-only unit false-greens).
class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.body);
  final Object body;
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? rs,
      Future<void>? cf) async {
    fetchCount++;
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Hive-faithful cache: stored payloads come back the way a REAL Hive box
/// read returns them (every nested Map as `Map<dynamic, dynamic>`), then run
/// through the same [HiveBoxes.toStringDynamicMap] conversion
/// `CacheHiveStore.getCachedData` applies — so the chain's serialize →
/// persist → deserialize round-trip is exercised with production-shaped
/// payloads, not the in-memory originals.
class _HiveFaithfulCache implements CacheStrategy {
  final _box = <String, dynamic>{};
  final _meta = <String, (DateTime, ServiceSource, Duration)>{};

  dynamic _hiveShape(dynamic v) {
    if (v is Map) {
      final m = <dynamic, dynamic>{};
      v.forEach((k, val) => m[k] = _hiveShape(val));
      return m;
    }
    if (v is List) return v.map(_hiveShape).toList();
    return v;
  }

  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _box[key] = _hiveShape(data);
    _meta[key] = (DateTime.now(), source, ttl);
  }

  @override
  CacheEntry? get(String key) {
    final raw = _box[key];
    if (raw == null) return null;
    final payload = HiveBoxes.toStringDynamicMap(raw);
    if (payload == null) return null;
    final meta = _meta[key]!;
    return CacheEntry(
      payload: payload,
      storedAt: meta.$1,
      originalSource: meta.$2,
      ttl: meta.$3,
    );
  }

  @override
  CacheEntry? getFresh(String key) {
    final e = get(key);
    if (e == null || e.isExpired) return null;
    return e;
  }
}

/// Captures errorLogger traffic for the #3148-parity assertions.
class _CapturingRecorder implements TraceRecorder {
  final captured = <ContextualError>[];

  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {
    captured.add(error as ContextualError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Garbage that passes the adapter's `is Map` narrowing and throws on the
/// first key access — the same in-`try` provider-shape fault the #3148 suite
/// injects into the other five adapters.
class _ThrowingMap extends MapBase<dynamic, dynamic> {
  @override
  dynamic operator [](Object? key) =>
      throw StateError('simulated provider-shape fault');
  @override
  void operator []=(dynamic key, dynamic value) {}
  @override
  void clear() {}
  @override
  Iterable<dynamic> get keys =>
      throw StateError('simulated provider-shape fault');
  @override
  dynamic remove(Object? key) => null;
}

void main() {
  silenceErrorLoggerSpool();

  late Map<String, dynamic> recorded;

  /// The recorded row for [id], with the derived `horaires_jour` column
  /// nulled — the upstream's flattening-lag shape (27/50 recorded rows
  /// already carry exactly this null), every other byte as captured live.
  Map<String, dynamic> degradedRecord(int id) {
    final row = (recorded['results'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((r) => r['id'] == id);
    return Map<String, dynamic>.of(row)..['horaires_jour'] = null;
  }

  setUpAll(() {
    recorded = jsonDecode(
      File('test/fixtures/prix_carburants_paris_geo_ordered.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  (PrixCarburantsStationService, _FixtureAdapter) serviceFor(Object body) {
    final adapter = _FixtureAdapter(body);
    final dio = Dio(BaseOptions(baseUrl: 'https://data.economie.gouv.fr'))
      ..httpClientAdapter = adapter;
    return (PrixCarburantsStationService(dio: dio, enricher: null), adapter);
  }

  List<TimeRange> rangesFor(WeeklyOpeningHours? oh, OpeningDay day) =>
      oh?.dayFor(day)?.ranges ?? const [];

  group('FR structured-horaires fallback (#3219)', () {
    test(
        'a recorded staffed record whose derived horaires_jour column is null '
        'still carries the per-day schedule from the structured horaires '
        'column — through the REAL service → chain → Hive-codec round-trip',
        () async {
      // Recorded Total Energies 75008010 — real split-shift week, present in
      // BOTH columns in the capture; the derived one nulled (the lag shape).
      final body = {
        'total_count': 1,
        'results': [degradedRecord(75008010)],
      };
      final cache = _HiveFaithfulCache();
      final (service, httpAdapter) = serviceFor(body);
      final chain = StationServiceChain(
        service,
        cache,
        errorSource: ServiceSource.prixCarburantsApi,
        countryCode: 'FR',
      );
      const params = SearchParams(lat: 48.8566, lng: 2.3522, radiusKm: 10.0);

      // Fresh-API pass.
      final fresh = await chain.searchStations(params);
      expect(fresh.data, hasLength(1));
      final s = fresh.data.single;

      final monday = rangesFor(s.openingHours, OpeningDay.mon);
      expect(monday, hasLength(2),
          reason: 'the recorded split shift (06:30–14:00 + 14:00–21:30) must '
              'survive a null derived column via the structured horaires '
              'fallback — on the #3219 master it was lost entirely');
      expect(monday.first.startMinutes, 6 * 60 + 30);
      expect(monday.first.endMinutes, 14 * 60);
      expect(monday.last.endMinutes, 21 * 60 + 30);
      // Thursday differs (10:00–14:00 + 14:00–17:00) — pins per-day fidelity,
      // not a copied whole-week range.
      expect(rangesFor(s.openingHours, OpeningDay.thu).first.startMinutes,
          10 * 60);

      // The legacy text fallback (bridge/back-compat surface) follows too.
      expect(s.openingHoursText, isNotNull);
      expect(s.openingHoursText, contains('06:30-14:00'));

      // NOT collapsed to a fake 24/7 week.
      expect(s.is24h, isFalse);
      expect(s.openingHours!.automate24h, isFalse);

      // Cache-hit pass: the SAME schedule must survive the chain's
      // serialize → Hive-shaped persist → deserialize codec (#2776 class).
      final cached = await chain.searchStations(params);
      expect(httpAdapter.fetchCount, 1,
          reason: 'second identical search within TTL must be a cache hit '
              '(rehydrated through the codec), not a second upstream fetch');
      final rehydrated = cached.data.single;
      expect(rangesFor(rehydrated.openingHours, OpeningDay.mon), hasLength(2),
          reason: 'per-day hours must survive the Hive cache round-trip');
      expect(rehydrated.openingHoursText, contains('06:30-14:00'));
    });

    test(
        'a recorded 24/7-automate record with a null derived column resolves '
        'to allWeek24h via the structured @automate-24-24 attribute — not '
        'notAvailable (the flag used to be discarded for null input)', () {
      // Recorded automate site 75013025 (`"@automate-24-24": "1"`).
      final degraded = degradedRecord(75013025)
        // Also null the flattened flag column so ONLY the structured
        // attribute carries the 24/7 signal (full flattening-lag shape).
        ..['horaires_automate_24_24'] = null;
      final s = parser.parsePrixCarburantsStation(degraded, 48.8566, 2.3522)!;

      expect(s.is24h, isTrue,
          reason: 'the structured @automate-24-24 attribute must feed is24h');
      final oh = s.openingHours!;
      expect(oh.automate24h, isTrue);
      // The structured column ALSO carries the staffed 06:00–22:00 week —
      // it must be parsed, not collapsed to a bare 24/7 (#2742 contract).
      expect(rangesFor(oh, OpeningDay.mon).single.startMinutes, 6 * 60);
      expect(rangesFor(oh, OpeningDay.mon).single.endMinutes, 22 * 60);
    });

    test(
        'adapter: a pure automate flag with a NULL horaires_jour means '
        'pump-open-24/7 — same as the empty-string case (#2742/#3219)', () {
      const adapter = FranceOpeningHoursAdapter();
      final oh = adapter.parse(<String, dynamic>{
        'horaires_jour': null,
        'horaires_automate_24_24': 'Oui',
      });
      expect(oh.automate24h, isTrue,
          reason: 'null schedule text must not discard the automate flag');
      expect(
          kRegularWeekdays
              .every((d) => oh.dayFor(d)?.state == DayState.open24h),
          isTrue);
    });

    test('recorded schedule-less stub records still resolve to no-data — the '
        'fallback never fabricates a closed week from day stubs', () {
      // Recorded 75012023-class shape: structured day stubs with NO horaire
      // children and horaires_jour null → genuinely no schedule upstream.
      final stub = (recorded['results'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((r) =>
              r['horaires_jour'] == null &&
              r['horaires'] != null &&
              !(r['horaires'] as String).contains('@ouverture'));
      final s = parser.parsePrixCarburantsStation(stub, 48.8566, 2.3522)!;
      expect(s.openingHours, WeeklyOpeningHours.notAvailable);
      expect(s.openingHoursText, isNull);
    });
  });

  group('#3152 exoneration — flux isolate/persistence boundary keeps hours',
      () {
    test(
        'parseFluxZip → in-radius copyWith → the toJson/fromJson transfer '
        'shape (PersistentDataset serialize/deserialize and any isolate '
        'hand-off) preserves the structured per-day schedule', () {
      // The documented flux schema, as in prix_carburants_flux_test.dart —
      // staffed week + automate attribute.
      const xml = '<?xml version="1.0" encoding="UTF-8"?><pdv_liste>'
          '<pdv id="34120008" latitude="4346070" longitude="342030" '
          'cp="34120" pop="R"><adresse>ROUTE DE MONTPELLIER</adresse>'
          '<ville>PEZENAS</ville>'
          '<horaires automate-24-24="1">'
          '<jour nom="Lundi"><horaire ouverture="07.00" fermeture="18.30"/></jour>'
          '<jour nom="Samedi"><horaire ouverture="08.00" fermeture="14.00"/></jour>'
          '</horaires>'
          '<prix nom="Gazole" valeur="1.799" maj="2026-06-10T08:00:00+00:00"/>'
          '</pdv></pdv_liste>';
      final archive = Archive()
        ..addFile(ArchiveFile('PrixCarburants_instantane.xml',
            utf8.encode(xml).length, utf8.encode(xml)));
      final zip = Uint8List.fromList(ZipEncoder().encode(archive));

      final parsed = flux.parseFluxZip(zip);
      expect(parsed, hasLength(1));

      // #3152's in-radius survivor copy.
      final survivor = parsed.single.copyWith(dist: 0.5);
      // The transfer shape every boundary uses: the model JSON codec.
      final rehydrated = Station.fromJson(
          jsonDecode(jsonEncode(survivor.toJson())) as Map<String, dynamic>);

      final oh = rehydrated.openingHours;
      expect(oh, isNotNull,
          reason: '#2777 — the codec must carry structured hours');
      expect(oh!.automate24h, isTrue);
      expect(rangesFor(oh, OpeningDay.mon).single.startMinutes, 7 * 60);
      expect(rangesFor(oh, OpeningDay.sat).single.endMinutes, 14 * 60);
      expect(rehydrated.openingHoursText, contains('Lundi 07:00-18:30'));
      expect(rehydrated.is24h, isTrue);
    });
  });

  group('FR parse failures are release-visible (#3148 parity)', () {
    late _CapturingRecorder recorder;

    setUp(() {
      recorder = _CapturingRecorder();
      errorLogger.testRecorderOverride = recorder;
      BreadcrumbCollector.clear();
      OpeningHoursAdapter.resetParseFailureReportsForTest();
    });

    tearDown(() {
      errorLogger.resetForTest();
      BreadcrumbCollector.clear();
      OpeningHoursAdapter.resetParseFailureReportsForTest();
    });

    test('garbage input degrades to notAvailable AND fires the oh-parse-failed '
        'breadcrumb + one errorLogger ERROR (FR was the adapter #3148 missed)',
        () {
      const adapter = FranceOpeningHoursAdapter();
      final garbage = _ThrowingMap();

      expect(adapter.parse(garbage), WeeklyOpeningHours.notAvailable);
      expect(adapter.parse(garbage), WeeklyOpeningHours.notAvailable);

      final crumbs = BreadcrumbCollector.snapshot()
          .where((b) => b.action == 'oh-parse-failed')
          .toList();
      expect(crumbs, hasLength(1),
          reason: 'throttled to first occurrence per session');
      expect(crumbs.single.detail, startsWith('FR'));

      expect(recorder.captured, hasLength(1));
      expect(recorder.captured.single.context?['country'], 'FR');
    });
  });
}
