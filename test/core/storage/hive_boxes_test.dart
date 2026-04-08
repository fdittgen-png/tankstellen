import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';

void main() {
  group('HiveBoxes', () {
    group('box name constants', () {
      test('all box names are non-empty strings', () {
        expect(HiveBoxes.settings, isNotEmpty);
        expect(HiveBoxes.favorites, isNotEmpty);
        expect(HiveBoxes.cache, isNotEmpty);
        expect(HiveBoxes.profiles, isNotEmpty);
        expect(HiveBoxes.priceHistory, isNotEmpty);
        expect(HiveBoxes.alerts, isNotEmpty);
      });

      test('all box names are unique', () {
        final names = {
          HiveBoxes.settings,
          HiveBoxes.favorites,
          HiveBoxes.cache,
          HiveBoxes.profiles,
          HiveBoxes.priceHistory,
          HiveBoxes.alerts,
        };
        expect(names.length, 6, reason: 'All box names must be unique');
      });
    });

    group('encryption coverage', () {
      test('hive_boxes.dart opens all domain boxes with encryptionCipher', () {
        // Read the source file and verify that every Hive.openBox call
        // in init() and initInIsolate() uses encryptionCipher, except
        // initForTest (which runs without FlutterSecureStorage).
        final source =
            File('lib/core/storage/hive_boxes.dart').readAsStringSync();

        // Extract init() method body
        final initMatch = RegExp(
          r'static Future<void> init\(\) async \{(.*?)\n  \}',
          dotAll: true,
        ).firstMatch(source);
        expect(initMatch, isNotNull, reason: 'init() method must exist');
        final initBody = initMatch!.group(1)!;

        // All Hive.openBox calls in init() must use encryptionCipher
        final initOpenBoxCalls = RegExp(r'Hive\.openBox\([^)]+\)')
            .allMatches(initBody)
            .map((m) => m.group(0)!)
            .toList();
        for (final call in initOpenBoxCalls) {
          expect(
            call.contains('encryptionCipher'),
            isTrue,
            reason:
                'All Hive.openBox calls in init() must use encryptionCipher: '
                'found "$call" without it',
          );
        }

        // Extract initInIsolate() method body
        final isolateMatch = RegExp(
          r'static Future<void> initInIsolate\(\) async \{(.*?)\n  \}',
          dotAll: true,
        ).firstMatch(source);
        expect(isolateMatch, isNotNull,
            reason: 'initInIsolate() method must exist');
        final isolateBody = isolateMatch!.group(1)!;

        // All Hive.openBox calls in initInIsolate() must use encryptionCipher
        final isolateOpenBoxCalls = RegExp(r'Hive\.openBox\([^)]+\)')
            .allMatches(isolateBody)
            .map((m) => m.group(0)!)
            .toList();
        for (final call in isolateOpenBoxCalls) {
          expect(
            call.contains('encryptionCipher'),
            isTrue,
            reason: 'All Hive.openBox calls in initInIsolate() must use '
                'encryptionCipher: found "$call" without it',
          );
        }
      });

      test('all six domain boxes are in the encrypted set', () {
        // The _encryptedBoxes set is private, so we verify via source analysis
        // that the migration loop covers all domain boxes.
        final source =
            File('lib/core/storage/hive_boxes.dart').readAsStringSync();

        final encryptedSetMatch = RegExp(
          r'_encryptedBoxes = \{(.*?)\};',
          dotAll: true,
        ).firstMatch(source);
        expect(encryptedSetMatch, isNotNull,
            reason: '_encryptedBoxes set must exist');
        final setBody = encryptedSetMatch!.group(1)!;

        // All six box names must appear in the encrypted set
        for (final boxName in [
          'settings',
          'profiles',
          'favorites',
          'cache',
          'priceHistory',
          'alerts',
        ]) {
          expect(
            setBody.contains(boxName),
            isTrue,
            reason: '$boxName must be in _encryptedBoxes set',
          );
        }
      });

      test('init() opens all six domain boxes', () {
        final source =
            File('lib/core/storage/hive_boxes.dart').readAsStringSync();

        // Extract init() method — match from "static Future<void> init()"
        // to the next "static" or end of class
        final initMatch = RegExp(
          r'static Future<void> init\(\) async \{(.*?)\n  \}',
          dotAll: true,
        ).firstMatch(source);
        expect(initMatch, isNotNull);
        final initBody = initMatch!.group(1)!;

        // Count that all boxes are opened (after the migration loop)
        for (final boxName in [
          'settings',
          'profiles',
          'favorites',
          'cache',
          'priceHistory',
          'alerts',
        ]) {
          expect(
            initBody.contains(boxName),
            isTrue,
            reason: 'init() must open the $boxName box',
          );
        }
      });

      test('initInIsolate() opens the five background boxes', () {
        final source =
            File('lib/core/storage/hive_boxes.dart').readAsStringSync();

        final isolateMatch = RegExp(
          r'static Future<void> initInIsolate\(\) async \{(.*?)\n  \}',
          dotAll: true,
        ).firstMatch(source);
        expect(isolateMatch, isNotNull);
        final isolateBody = isolateMatch!.group(1)!;

        // Background isolate opens settings, favorites, alerts, cache,
        // priceHistory (not profiles)
        for (final boxName in [
          'settings',
          'favorites',
          'alerts',
          'cache',
          'priceHistory',
        ]) {
          expect(
            isolateBody.contains(boxName),
            isTrue,
            reason: 'initInIsolate() must open the $boxName box',
          );
        }
      });

      test('_loadCipher uses FlutterSecureStorage', () {
        final source =
            File('lib/core/storage/hive_boxes.dart').readAsStringSync();

        expect(
          source.contains('FlutterSecureStorage'),
          isTrue,
          reason:
              'Encryption key must be stored in FlutterSecureStorage',
        );
        expect(
          source.contains('hive_encryption_key'),
          isTrue,
          reason: 'Encryption key name must be hive_encryption_key',
        );
      });

      test('migration logic exists for encrypted boxes', () {
        final source =
            File('lib/core/storage/hive_boxes.dart').readAsStringSync();

        expect(
          source.contains('_migrateToEncrypted'),
          isTrue,
          reason: 'Migration method must exist for unencrypted-to-encrypted',
        );
        expect(
          source.contains('deleteBoxFromDisk'),
          isTrue,
          reason:
              'Migration must delete old unencrypted box before re-creating',
        );
      });
    });

    group('toStringDynamicMap', () {
      test('returns null for null input', () {
        expect(HiveBoxes.toStringDynamicMap(null), isNull);
      });

      test('returns typed map for Map<String, dynamic>', () {
        final input = <String, dynamic>{'key': 'value', 'count': 42};
        final result = HiveBoxes.toStringDynamicMap(input);
        expect(result, {'key': 'value', 'count': 42});
      });

      test('converts untyped Map to Map<String, dynamic>', () {
        final input = <dynamic, dynamic>{1: 'one', 'two': 2};
        final result = HiveBoxes.toStringDynamicMap(input);
        expect(result, isNotNull);
        expect(result!['1'], 'one');
        expect(result['two'], 2);
      });

      test('returns null for non-map input', () {
        expect(HiveBoxes.toStringDynamicMap('string'), isNull);
        expect(HiveBoxes.toStringDynamicMap(42), isNull);
        expect(HiveBoxes.toStringDynamicMap([1, 2, 3]), isNull);
      });

      test('deep-converts nested maps', () {
        final input = <String, dynamic>{
          'outer': <dynamic, dynamic>{'inner': 'value'},
        };
        final result = HiveBoxes.toStringDynamicMap(input);
        expect(result, isNotNull);
        expect(result!['outer'], isA<Map<String, dynamic>>());
        expect((result['outer'] as Map)['inner'], 'value');
      });

      test('deep-converts maps inside lists', () {
        final input = <String, dynamic>{
          'items': [
            <dynamic, dynamic>{'id': 1},
            <dynamic, dynamic>{'id': 2},
          ],
        };
        final result = HiveBoxes.toStringDynamicMap(input);
        expect(result, isNotNull);
        final items = result!['items'] as List;
        expect(items.length, 2);
        expect((items[0] as Map)['id'], 1);
      });
    });
  });
}
