import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/data/home_widget_json.dart';

void main() {
  group('encodeStationsForWidget', () {
    test('empty list encodes to "[]"', () {
      expect(encodeStationsForWidget(const []), '[]');
    });

    test('single entry round-trips with same id', () {
      final encoded = encodeStationsForWidget(const [
        {'id': 'station-abc', 'name': 'Station ABC', 'price': 1.789},
      ]);

      final decoded = jsonDecode(encoded) as List<dynamic>;
      expect(decoded, hasLength(1));

      final entry = decoded.first as Map<String, dynamic>;
      expect(entry['id'], 'station-abc');
      expect(entry['name'], 'Station ABC');
      expect(entry['price'], 1.789);
    });

    test(
      'multiple entries: every input id appears exactly once, in order',
      () {
        final inputIds = <String>['s1', 's2', 's3', 's4', 's5'];
        final stations = <Map<String, dynamic>>[
          for (final id in inputIds) {'id': id, 'label': 'label-$id'},
        ];

        final encoded = encodeStationsForWidget(stations);
        final decoded = (jsonDecode(encoded) as List<dynamic>)
            .cast<Map<String, dynamic>>();

        expect(decoded.length, inputIds.length);

        // One id per entry, order preserved.
        final decodedIds = decoded.map((e) => e['id'] as String).toList();
        expect(decodedIds, equals(inputIds));

        // Each id appears exactly once.
        for (final id in inputIds) {
          expect(
            decodedIds.where((d) => d == id).length,
            1,
            reason: 'id $id should appear exactly once',
          );
        }
      },
    );

    test(
      'duplicate ids in input pass through unchanged '
      '(encoding is not the deduper)',
      () {
        final stations = <Map<String, dynamic>>[
          {'id': 'dup', 'label': 'first'},
          {'id': 'dup', 'label': 'second'},
          {'id': 'unique', 'label': 'third'},
        ];

        final encoded = encodeStationsForWidget(stations);
        final decoded = (jsonDecode(encoded) as List<dynamic>)
            .cast<Map<String, dynamic>>();

        expect(decoded, hasLength(3));
        expect(
          decoded.map((e) => e['id']).toList(),
          equals(<String>['dup', 'dup', 'unique']),
        );
        expect(decoded[0]['label'], 'first');
        expect(decoded[1]['label'], 'second');
        expect(decoded[2]['label'], 'third');
      },
    );

    test('mixed value types per entry survive round-trip', () {
      final stations = <Map<String, dynamic>>[
        {
          'id': 'mixed-1',
          'name': 'String value',
          'count': 7,
          'price': 1.659,
          'isOpen': true,
          'closedReason': null,
        },
      ];

      final encoded = encodeStationsForWidget(stations);
      final decoded = (jsonDecode(encoded) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(decoded, hasLength(1));
      final entry = decoded.first;

      expect(entry['id'], 'mixed-1');
      expect(entry['name'], 'String value');
      expect(entry['count'], 7);
      expect(entry['count'], isA<int>());
      expect(entry['price'], 1.659);
      expect(entry['price'], isA<double>());
      expect(entry['isOpen'], true);
      expect(entry['isOpen'], isA<bool>());
      expect(entry['closedReason'], isNull);
      expect(entry.containsKey('closedReason'), isTrue);
    });
  });
}
