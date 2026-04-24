import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/data/home_widget_json.dart';

/// JSON-schema regression guards for the home-screen widget payload (#753).
///
/// The widget-tap-opens-wrong-station bug has four suspect hypotheses.
/// The existing `station_detail_provider_regression_test.dart` locks
/// down H1/H2/H3 (search-state short-circuit, cross-country collision,
/// API fallback). THIS file covers H4: the JSON producer itself must
/// emit exactly one `id` per entry, and those ids must round-trip 1:1
/// from the input list (same order, same values, no duplicates).
///
/// If a regression ever drops, reorders, or malforms the `id` field,
/// Kotlin's `buildRow` would bind row N's PendingIntent to the wrong
/// station — precisely the symptom in #753.
///
/// These tests intentionally do NOT exercise `home_widget`
/// platform-channel code (not available in unit tests). They pin the
/// pure-Dart producer contract via the `encodeStationsForWidget` seam.
void main() {
  group('encodeStationsForWidget (#753 — JSON integrity / H4)', () {
    test('emits one entry per input station, preserving order', () {
      final stations = [
        {'id': 'de-1', 'brand': 'Shell'},
        {'id': 'de-2', 'brand': 'Total'},
        {'id': 'de-3', 'brand': 'BP'},
        {'id': 'de-4', 'brand': 'Aral'},
        {'id': 'de-5', 'brand': 'Esso'},
      ];
      final decoded =
          jsonDecode(encodeStationsForWidget(stations)) as List<dynamic>;

      expect(decoded.length, stations.length,
          reason: 'JSON length must equal input length — a dropped entry '
              'shifts every subsequent row to the wrong station id.');
      for (var i = 0; i < stations.length; i++) {
        final entry = decoded[i] as Map<String, dynamic>;
        expect(entry['id'], stations[i]['id'],
            reason: 'Row $i id must round-trip identical to input; any '
                'reorder would bind the wrong PendingIntent in Kotlin.');
      }
    });

    test('every entry has exactly one `id` field (no malformed rows)', () {
      final stations = [
        {'id': 'a', 'brand': 'A'},
        {'id': 'b', 'brand': 'B'},
        {'id': 'c', 'brand': 'C'},
      ];
      final decoded =
          jsonDecode(encodeStationsForWidget(stations)) as List<dynamic>;

      for (final raw in decoded) {
        final entry = raw as Map<String, dynamic>;
        expect(entry.containsKey('id'), isTrue,
            reason: 'Missing id would make Kotlin fall back to empty '
                'string and skip the tap handler entirely.');
        expect(entry['id'], isA<String>(),
            reason: 'Kotlin calls optString("id", "") — a non-string '
                '(e.g. int, null) would silently become "".');
        expect((entry['id'] as String).isNotEmpty, isTrue,
            reason: 'Empty id would be a no-op tap — worse than wrong '
                'tap because the user has no idea why nothing happened.');
      }
    });

    test('ids across the payload are unique (no collisions)', () {
      final stations = [
        {'id': 'de-1', 'brand': 'Shell'},
        {'id': 'de-2', 'brand': 'Total'},
        {'id': 'de-3', 'brand': 'BP'},
      ];
      final decoded =
          jsonDecode(encodeStationsForWidget(stations)) as List<dynamic>;

      final ids = decoded
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate ids at the widget layer would make two rows '
              'resolve to the same station — not #753 directly, but the '
              'canonical sibling bug that would produce similar reports.');
    });

    test('empty list encodes to `[]`, not null or invalid JSON', () {
      final encoded = encodeStationsForWidget([]);
      expect(encoded, '[]');
      expect(jsonDecode(encoded), isEmpty);
    });

    test('ids with special chars (slash, dash, encoded) are preserved', () {
      // OCM ids contain dashes, and a future country API may include
      // characters that need URI encoding downstream. The JSON layer
      // must NOT mangle them — the encoding concern belongs to the URI
      // builder on the Kotlin side (see `Uri.parse("tankstellenwidget://
      // station?id=$stationId")`), not this payload.
      final stations = [
        {'id': 'ocm-42', 'brand': 'EV A'},
        {'id': 'de-abc/123', 'brand': 'Slash station'},
        {'id': 'fr-ee-bordeaux-01', 'brand': 'Long id'},
        {'id': 'it-42 with space', 'brand': 'Space station'},
      ];
      final decoded =
          jsonDecode(encodeStationsForWidget(stations)) as List<dynamic>;

      expect((decoded[0] as Map)['id'], 'ocm-42');
      expect((decoded[1] as Map)['id'], 'de-abc/123');
      expect((decoded[2] as Map)['id'], 'fr-ee-bordeaux-01');
      expect((decoded[3] as Map)['id'], 'it-42 with space');
    });

    test('output is valid JSON that a JSON parser can round-trip', () {
      final stations = [
        {
          'id': 'de-1',
          'brand': 'Shell',
          'name': 'Shell Unter den Linden',
          'street': 'Unter den Linden 1',
          'postCode': '10117',
          'place': 'Berlin',
          'e5': 1.899,
          'e10': 1.849,
          'diesel': 1.799,
          'isOpen': true,
          'currency': '€',
          'distance_km': 2.3,
        },
      ];
      final encoded = encodeStationsForWidget(stations);
      final decoded = jsonDecode(encoded) as List<dynamic>;
      expect(decoded.length, 1);
      final entry = decoded[0] as Map<String, dynamic>;
      expect(entry['id'], 'de-1');
      expect(entry['e10'], 1.849);
      expect(entry['isOpen'], true);
      expect(entry['currency'], '€');
    });

    test('extra fields are preserved (no schema strip that could drop id)',
        () {
      // Defence-in-depth — if someone refactors the encoder to project
      // only a known subset of fields, this test ensures `id` survives
      // alongside whatever else the builder emits. Any schema change
      // should be a deliberate breaking edit of this test.
      final stations = [
        {
          'id': 'de-1',
          'brand': 'Shell',
          'new_future_field': 'value',
          'another_new_field': 42,
        },
      ];
      final decoded =
          jsonDecode(encodeStationsForWidget(stations)) as List<dynamic>;
      final entry = decoded[0] as Map<String, dynamic>;
      expect(entry['id'], 'de-1');
      expect(entry['new_future_field'], 'value');
      expect(entry['another_new_field'], 42);
    });
  });
}
