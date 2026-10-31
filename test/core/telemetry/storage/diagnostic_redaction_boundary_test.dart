// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/pii_scrubber.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/core/telemetry/upload/trace_uploader.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/time/app_clock.dart';

import '../../../helpers/hive_temp_dir.dart';
import '../../../fakes/fake_storage_repository.dart';

const _mac = 'A2:B4:C6:D8:E0:F1';
const _email = 'synthetic.owner@example.test';
const _vin = 'JTDKARFU0H3000001';
const _symbol = 'SyncPullAbandonedException';
const _sha = '0123456789abcdef0123456789abcdef01234567';
const _incident = '10203040-5060-7080-90ab-cdef01234567';

class _InvalidKeyMap extends MapBase<Object?, Object?> {
  var visited = 0;
  @override
  Iterable<MapEntry<Object?, Object?>> get entries sync* {
    for (var i = 0; i < PiiScrubber.maxValueCount * 4; i++) {
      visited++;
      yield const MapEntry(Object(), _mac);
    }
  }

  @override
  Iterable<Object?> get keys => const [];
  @override
  Object? operator [](Object? key) => null;
  @override
  void operator []=(Object? key, Object? value) =>
      throw UnsupportedError('fixture');
  @override
  void clear() => throw UnsupportedError('fixture');
  @override
  Object? remove(Object? key) => throw UnsupportedError('fixture');
}

ErrorTrace _trace() => ErrorTrace(
  id: _incident,
  timestamp: const SystemClock().now(),
  timezoneOffset: '+00:00',
  category: ErrorCategory.platform,
  errorType: _symbol,
  errorMessage: '$_symbol cause: device=$_mac owner=$_email vin=$_vin',
  stackTrace:
      '#0 migrateLegacyRowsInBackground '
      '(package:tankstellen/trips.dart:12:3)\n'
      'caused by device $_mac',
  deviceInfo: const DeviceInfo(
    os: 'Android',
    osVersion: '13',
    platform: 'test',
    locale: 'en',
    screenWidth: 400,
    screenHeight: 800,
    appVersion: '6.1.0+2026795211',
  ),
  appState: const AppStateSnapshot(
    activeProfileId: 'private-profile-4478',
    activeProfileName: 'Synthetic private owner',
  ),
  networkState: const NetworkSnapshot(isOnline: true),
  breadcrumbs: [
    Breadcrumb(
      timestamp: const SystemClock().now(),
      action: 'connect',
      detail: 'lastBreadcrumbs: {"causes":["device $_mac","$_email"]}',
    ),
  ],
);

void _expectPrivateValuesAbsent(String encoded) {
  for (final value in [
    _mac,
    _email,
    _vin,
    'private-profile-4478',
    'Synthetic private owner',
    '43.123456',
    '3.987654',
  ]) {
    expect(encoded, isNot(contains(value)), reason: '$value must stay local');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late TraceStorage storage;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('diagnostic_4478_');
    Hive.init(directory.path);
    await TraceStorage.init();
    await TraceStorage.legacySanitization;
    storage = TraceStorage();
    TraceStorage.extraExportSections.clear();
  });
  tearDown(() async {
    TraceStorage.extraExportSections.clear();
    await closeHiveAndDeleteTemp(directory);
  });

  test('invalid map keys spend traversal budget too', () {
    final malformed = _InvalidKeyMap();
    final safe = PiiScrubber.scrubMap({'nested': malformed});
    expect(malformed.visited, lessThanOrEqualTo(PiiScrubber.maxValueCount + 1));
    expect(safe['_diagnosticOmitted'], isTrue);
  });

  test(
    'generic nested IDs and opaque reason/where values are not provenance',
    () {
      const opaque = 'AbCdEfGhIjKlMnOpQrStUv1234';
      final safe = jsonEncode(
        PiiScrubber.scrubMap({
          'account': {'id': _incident},
          'id': _incident,
          'where': opaque,
          'reason': opaque,
          opaque: 'opaque key',
        }),
      );
      expect(safe, isNot(contains(_incident)));
      expect(safe, isNot(contains(opaque)));
    },
  );

  test(
    'real recorder persists, restarts and exports safe bytes with upload off',
    () async {
      final settings = FakeStorageRepository();
      final container = ProviderContainer(
        overrides: [
          storageRepositoryProvider.overrideWithValue(settings),
          traceStorageProvider.overrideWithValue(storage),
          traceUploaderProvider.overrideWithValue(TraceUploader(settings)),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(traceRecorderProvider)
          .record(
            Exception('$_symbol device $_mac owner $_email'),
            StackTrace.fromString(
              '#0 migrateLegacyRowsInBackground '
              '(package:tankstellen/trip_history_repository.dart:12:3)\n$_mac',
            ),
          );
      final id = storage.getAll().single.id;
      expect(container.read(traceUploaderProvider).uploadPermitted(), isFalse);
      _expectPrivateValuesAbsent(
        jsonEncode(Hive.box<dynamic>('error_traces').get(id)),
      );
      await Hive.box<dynamic>('error_traces').close();
      await TraceStorage.init();
      await TraceStorage.legacySanitization;
      final export = storage.exportAsJson();
      _expectPrivateValuesAbsent(export);
      expect(export, contains(_symbol));
      expect(export, contains(id));
      expect(export, contains('migrateLegacyRowsInBackground'));
    },
  );

  test(
    'direct diagnostic storage sanitizes persisted bytes and viewer reads',
    () async {
      await storage.store(_trace());
      final persisted = jsonEncode(
        Hive.box<dynamic>('error_traces').get(_incident),
      );
      _expectPrivateValuesAbsent(persisted);
      _expectPrivateValuesAbsent(jsonEncode(storage.getAll().single.toJson()));
      expect(storage.getById(_incident)!.errorType, _symbol);
      expect(
        storage.getById(_incident)!.stackTrace,
        contains('migrateLegacyRowsInBackground'),
      );
    },
  );

  test(
    'legacy rows and registered nested sections are safe on final export',
    () async {
      final raw = jsonDecode(jsonEncode(_trace().toJson()));
      await Hive.box<dynamic>('error_traces').put(_incident, raw);
      TraceStorage.extraExportSections['native'] = () => {
        'sourceSha': _sha,
        'sourceSymbol': 'TraceStorage.migrateLegacyRowsInBackground',
        'incidentId': _incident,
        'account': {'id': _incident},
        'id': _incident,
        'reason': 'low_memory_kill',
        'outcome': 'completedUnauthenticated',
        'timingMs': 42,
        'transportDecisionReason': 'already_connected_to_device',
        'causes': [
          {
            'lastBreadcrumbs': '$_symbol device $_mac $_email',
            'escaped': jsonEncode({'detail': 'device $_mac'}),
            'lat': 43.123456,
            'lng': 3.987654,
            'vinTail': '3000001',
            'privateUrl':
                'https://example.test/receipts/private-4478?token=abc',
          },
        ],
      };
      final exported = storage.exportAsJson();
      _expectPrivateValuesAbsent(exported);
      expect(exported, isNot(contains('private-4478')));
      expect(exported, isNot(contains('3000001')));
      expect(exported, contains(_symbol));
      expect(exported, contains(_sha));
      expect(exported, contains('TraceStorage.migrateLegacyRowsInBackground'));
      expect(exported, contains('completedUnauthenticated'));
      expect(exported, contains(_incident));
      final document = jsonDecode(exported) as Map<String, dynamic>;
      expect((document['native'] as Map)['timingMs'], 42);
      expect((document['native'] as Map)['account'], PiiScrubber.tokenMarker);
      expect((document['native'] as Map)['id'], isNot(_incident));
      expect((document['native'] as Map)['reason'], 'low_memory_kill');
      expect(
        (document['native'] as Map)['transportDecisionReason'],
        'already_connected_to_device',
      );
    },
  );

  test(
    'restart migrates old diagnostic rows without touching another box',
    () async {
      await Hive.box<dynamic>(
        'error_traces',
      ).put(_incident, jsonDecode(jsonEncode(_trace().toJson())));
      final userRecords = await Hive.openBox<String>('user_backup_fixture');
      await userRecords.put('retained', 'deliberate backup $_mac $_vin');
      await Hive.box<dynamic>('error_traces').close();
      await TraceStorage.init();
      // Reads are protected before deferred at-rest repair completes.
      _expectPrivateValuesAbsent(jsonEncode(storage.getAll().single.toJson()));
      await TraceStorage.legacySanitization;
      _expectPrivateValuesAbsent(
        jsonEncode(Hive.box<dynamic>('error_traces').values.toList()),
      );
      expect(userRecords.get('retained'), 'deliberate backup $_mac $_vin');
      expect(storage.getById(_incident)!.id, _incident);
    },
  );

  test(
    'oversized and deeply nested unknown sections are explicitly omitted',
    () {
      Object? nested = {'detail': _mac};
      for (var i = 0; i < 100; i++) {
        nested = {'child': nested};
      }
      final cycle = <String, dynamic>{};
      cycle['self'] = cycle;
      TraceStorage.extraExportSections['unknown'] = () => {
        'deep': nested,
        'cycle': cycle,
        'large': '${'x' * 100000} $_mac',
        'unsupported': Object(),
      };
      final exported = storage.exportAsJson();
      expect(() => jsonDecode(exported), returnsNormally);
      expect(exported, isNot(contains(_mac)));
      expect(exported, contains('_diagnosticOmitted'));
      expect(exported.length, lessThan(10000));
    },
  );

  test(
    'unrecognized legacy rows keep truthful counts without raw content',
    () async {
      await Hive.box<dynamic>(
        'error_traces',
      ).put('legacy-string', '$_mac $_email');
      final document =
          jsonDecode(storage.exportAsJson()) as Map<String, dynamic>;
      expect(document['traceCount'], 1);
      expect(document['unparsedCount'], 1);
      final unknown = (document['unparsedRaw'] as List).single as Map;
      expect(unknown['_diagnosticOmitted'], isTrue);
      _expectPrivateValuesAbsent(jsonEncode(document));
    },
  );

  test(
    'text redaction covers MAC encodings and preserves safe long symbols',
    () {
      for (final mac in [
        _mac,
        'A2-B4-C6-D8-E0-F1',
        'A2B4.C6D8.E0F1',
        'A2B4C6D8E0F1',
        'A2%3AB4%3AC6%3AD8%3AE0%3AF1',
        r'A2\u003aB4\u003aC6\u003aD8\u003aE0\u003aF1',
      ]) {
        final safe = PiiScrubber.scrubText('$_symbol device $mac')!;
        expect(safe, contains(_symbol));
        expect(safe, isNot(contains(mac)));
        expect(PiiScrubber.scrubText(safe), safe);
      }
    },
  );

  test(
    'escaped JSON coordinates, URL payloads and short credentials fail closed',
    () {
      final encoded = jsonEncode(
        jsonEncode({'lat': 43.123456, 'lng': 3.987654}),
      );
      final safe = PiiScrubber.scrubText(encoded)!;
      expect(safe, isNot(contains('43.123456')));
      expect(safe, isNot(contains('3.987654')));
      expect(
        PiiScrubber.scrubText('authorization: Bearer short-secret'),
        PiiScrubber.omittedMarker,
      );
      expect(
        PiiScrubber.scrubText('Bearer MySecretPasswordException'),
        PiiScrubber.tokenMarker,
      );
      expect(PiiScrubber.scrubText('BuildId: $_sha'), 'BuildId: $_sha');
      final document = PiiScrubber.scrubMap({
        'message': 'password=short-secret',
        'id': 'A2B4C6D8E0F1',
        'device': {'id': _incident},
      });
      expect(document['_diagnosticOmitted'], isTrue);
      expect(jsonEncode(document), isNot(contains('short-secret')));
      expect(jsonEncode(document), isNot(contains('A2B4C6D8E0F1')));
      expect(jsonEncode(document), isNot(contains(_incident)));
      expect(PiiScrubber.scrubMap(document), document);
    },
  );
}
