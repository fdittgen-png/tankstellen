// Regression guard for issue #753 — hypothesis 4.
//
// Bug hypothesis: the favorites home-screen widget shows station rows in an
// order that differs from `FavoriteStorage.getFavoriteIds()` (the order the
// in-app favorites tab renders). If the widget-side list were reordered,
// filtered, or de-duplicated differently from the app, tapping row N in the
// widget would open a different station than the user expected.
//
// This test feeds `HomeWidgetService.updateWidget` a deterministic list of
// favorites + associated station data, captures the `stations_json` payload
// that the service writes through the `home_widget` method channel, and
// asserts the order of the emitted rows matches the favorites-list order
// index-for-index.
//
// Coordinator context (#753, phase 2): shipped as a regression guard —
// no production code is modified in this PR. If the test surfaces a real
// ordering bug, it is to be skipped with a referencing reason and the fix
// scoped into a separate PR.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';

/// Minimal in-memory [FavoriteStorage] used to drive
/// [HomeWidgetService.updateWidget]. Only the three methods the service
/// actually calls are implemented — every other interface member throws so
/// that an accidental new dependency surfaces as a loud test failure rather
/// than silently returning a stub value.
class _InMemoryFavoriteStorage implements FavoriteStorage {
  _InMemoryFavoriteStorage({
    required List<String> ids,
    required Map<String, Map<String, dynamic>> data,
  })  : _ids = List<String>.of(ids),
        _data = Map<String, Map<String, dynamic>>.of(data);

  final List<String> _ids;
  final Map<String, Map<String, dynamic>> _data;

  @override
  List<String> getFavoriteIds() => List<String>.unmodifiable(_ids);

  @override
  Map<String, dynamic>? getFavoriteStationData(String stationId) =>
      _data[stationId];

  @override
  Map<String, dynamic> getAllFavoriteStationData() =>
      Map<String, dynamic>.unmodifiable(_data);

  // --- unused by HomeWidgetService.updateWidget -----------------------------
  @override
  int get favoriteCount => _ids.length;
  @override
  Future<void> addFavorite(String id) => throw UnimplementedError();
  @override
  Future<void> removeFavorite(String id) => throw UnimplementedError();
  @override
  bool isFavorite(String id) => _ids.contains(id);
  @override
  Future<void> setFavoriteIds(List<String> ids) =>
      throw UnimplementedError();
  @override
  Future<void> saveFavoriteStationData(
    String stationId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();
  @override
  Future<void> removeFavoriteStationData(String stationId) =>
      throw UnimplementedError();
}

/// Build a fixture station map keyed by a caller-supplied label. Values are
/// intentionally distinctive (unique brand + street) so assertion failures
/// point directly at the mis-ordered row.
Map<String, dynamic> _station({
  required String brand,
  required String street,
  double lat = 52.5200,
  double lng = 13.4050,
  double e10 = 1.799,
}) =>
    {
      'brand': brand,
      'name': brand,
      'street': street,
      'postCode': '10969',
      'place': 'Berlin',
      'lat': lat,
      'lng': lng,
      'e5': 1.899,
      'e10': e10,
      'diesel': 1.699,
      'isOpen': true,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;

  // Every `HomeWidget.saveWidgetData` call that lands on the channel gets
  // recorded here so the test can inspect what the service actually wrote.
  late Map<String, Object?> savedWidgetData;

  setUp(() {
    savedWidgetData = <String, Object?>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'saveWidgetData':
          final args = (call.arguments as Map).cast<String, Object?>();
          savedWidgetData[args['id']! as String] = args['data'];
          return true;
        case 'updateWidget':
          return true;
        case 'setAppGroupId':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('HomeWidgetService.updateWidget — row ordering (#753 hypothesis 4)',
      () {
    test(
        'serialized widget rows match the favorites-storage order '
        'index-for-index (no reorder, no filter)', () async {
      // Deterministic 5-item favorites list. The ordering is intentionally
      // *not* alphabetical, *not* by price, *not* by distance — so any
      // incidental sort the service might apply would be detected.
      final ids = <String>[
        'de-002-aral',
        'de-005-shell',
        'de-001-bp',
        'de-010-total',
        'de-003-jet',
      ];
      final data = {
        'de-002-aral':
            _station(brand: 'ARAL', street: 'Kurfuerstendamm 1', e10: 1.849),
        'de-005-shell':
            _station(brand: 'Shell', street: 'Friedrichstr 2', e10: 1.799),
        'de-001-bp':
            _station(brand: 'BP', street: 'Unter den Linden 3', e10: 1.869),
        'de-010-total':
            _station(brand: 'Total', street: 'Alexanderplatz 4', e10: 1.819),
        'de-003-jet':
            _station(brand: 'JET', street: 'Potsdamer Platz 5', e10: 1.759),
      };
      final storage = _InMemoryFavoriteStorage(ids: ids, data: data);

      await HomeWidgetService.updateWidget(storage);

      // 1. Count must equal the input length exactly (no filter drift).
      expect(savedWidgetData['station_count'], ids.length);

      // 2. `stations_json` is the row payload the native widget renders.
      final jsonStr = savedWidgetData['stations_json'] as String?;
      expect(jsonStr, isNotNull,
          reason: 'service must write stations_json on every update');
      final rows = (jsonDecode(jsonStr!) as List).cast<Map<String, dynamic>>();

      // 3. Row count parity.
      expect(rows, hasLength(ids.length),
          reason: 'serialized row count must equal favorite id count');

      // 4. Index-for-index id parity — the core assertion.
      final rowIds = rows.map((r) => r['id'] as String).toList();
      expect(rowIds, equals(ids),
          reason:
              'widget row order must mirror FavoriteStorage.getFavoriteIds() '
              'exactly — any drift means tapping row N opens the wrong '
              'station (issue #753).');

      // 5. Spot-check that the row content matches the id at that position
      //    (protects against a swap where ids stay put but brands shift).
      for (var i = 0; i < ids.length; i++) {
        expect(rows[i]['brand'], data[ids[i]]!['brand'],
            reason: 'row $i brand must match favorite ${ids[i]}');
        expect(rows[i]['street'], data[ids[i]]!['street'],
            reason: 'row $i street must match favorite ${ids[i]}');
      }
    });

    test(
        'negative control — a reversed copy of the rows fails the '
        'same assertion (proves the check is tight)', () async {
      final ids = <String>['de-a', 'de-b', 'de-c'];
      final data = {
        'de-a': _station(brand: 'A', street: '1'),
        'de-b': _station(brand: 'B', street: '2'),
        'de-c': _station(brand: 'C', street: '3'),
      };
      final storage = _InMemoryFavoriteStorage(ids: ids, data: data);

      await HomeWidgetService.updateWidget(storage);

      final rows = (jsonDecode(savedWidgetData['stations_json']! as String)
              as List)
          .cast<Map<String, dynamic>>();

      // Reverse the actual rows — this simulates a service that emits
      // stations in the wrong order. The equality assertion used by the
      // happy-path test above MUST fail on the reversed list, otherwise the
      // positive test is vacuous.
      final reversedIds = rows.reversed.map((r) => r['id'] as String).toList();
      expect(reversedIds, isNot(equals(ids)),
          reason: 'reversed rows must NOT equal original ids — '
              'otherwise the positive-case equality check is vacuous');
    });

    test(
        'negative control — dropping a row fails the count assertion '
        '(proves the count check is tight)', () async {
      final ids = <String>['de-a', 'de-b', 'de-c'];
      final data = {
        'de-a': _station(brand: 'A', street: '1'),
        'de-b': _station(brand: 'B', street: '2'),
        'de-c': _station(brand: 'C', street: '3'),
      };
      final storage = _InMemoryFavoriteStorage(ids: ids, data: data);

      await HomeWidgetService.updateWidget(storage);

      final rows = (jsonDecode(savedWidgetData['stations_json']! as String)
              as List)
          .cast<Map<String, dynamic>>();

      // Simulate dropping the middle row. The happy-path length assertion
      // MUST fail against this shortened list — otherwise the count check
      // is not protecting against silent filter drift.
      final dropped = List.of(rows)..removeAt(1);
      expect(dropped.length, isNot(ids.length),
          reason: 'dropping one row must change the length — '
              'otherwise the length check is vacuous');
    });

    test(
        'empty favorites list writes station_count=0 and stations_json=[]',
        () async {
      final storage =
          _InMemoryFavoriteStorage(ids: const [], data: const {});

      await HomeWidgetService.updateWidget(storage);

      expect(savedWidgetData['station_count'], 0);
      expect(savedWidgetData['stations_json'], '[]');
    });

    test(
        'favorite id with no station data is silently skipped '
        'but remaining rows keep their relative order', () async {
      // de-missing has no data → service must skip it without reordering
      // the rows that DO have data.
      final ids = <String>['de-a', 'de-missing', 'de-b', 'de-c'];
      final data = {
        'de-a': _station(brand: 'A', street: '1'),
        'de-b': _station(brand: 'B', street: '2'),
        'de-c': _station(brand: 'C', street: '3'),
      };
      final storage = _InMemoryFavoriteStorage(ids: ids, data: data);

      await HomeWidgetService.updateWidget(storage);

      final rows = (jsonDecode(savedWidgetData['stations_json']! as String)
              as List)
          .cast<Map<String, dynamic>>();
      final rowIds = rows.map((r) => r['id'] as String).toList();

      // Remaining rows appear in the same relative order as the favorites
      // list, with the missing-data row removed.
      expect(rowIds, equals(<String>['de-a', 'de-b', 'de-c']));
      expect(savedWidgetData['station_count'], 3);
    });

    test(
        'list longer than the 5-row cap is truncated from the TAIL, '
        'never reordered', () async {
      final ids = <String>[
        'de-0',
        'de-1',
        'de-2',
        'de-3',
        'de-4',
        'de-5',
        'de-6',
      ];
      final data = <String, Map<String, dynamic>>{
        for (final id in ids)
          id: _station(brand: id.toUpperCase(), street: id),
      };
      final storage = _InMemoryFavoriteStorage(ids: ids, data: data);

      await HomeWidgetService.updateWidget(storage);

      final rows = (jsonDecode(savedWidgetData['stations_json']! as String)
              as List)
          .cast<Map<String, dynamic>>();
      final rowIds = rows.map((r) => r['id'] as String).toList();

      // First 5 ids in the ORIGINAL order — not sorted or re-ranked.
      expect(rowIds, equals(ids.sublist(0, 5)));
      expect(savedWidgetData['station_count'], 5);
    });
  });
}
