// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/share/'
    'shared_receipt_intent.dart';

/// #2735 — the platform-channel decode boundary. The GMS-free
/// `ShareIntentChannel.kt` emits exactly the `{items:[...], country:"..."}`
/// map shape these tests drive, so this pins that the Dart side decodes the
/// real native payload (and drops malformed entries) rather than echoing a
/// hand-built object — the data-shape contract between Kotlin and Dart.
void main() {
  group('SharedReceiptItem.fromMap', () {
    test('decodes each kind to the matching field', () {
      expect(
        SharedReceiptItem.fromMap({'kind': 'image', 'path': '/c/a.jpg'}),
        const SharedReceiptItem.image('/c/a.jpg'),
      );
      expect(
        SharedReceiptItem.fromMap({'kind': 'pdf', 'path': '/c/a.pdf'}),
        const SharedReceiptItem.pdf('/c/a.pdf'),
      );
      expect(
        SharedReceiptItem.fromMap({'kind': 'text', 'text': 'Litri 30,00'}),
        const SharedReceiptItem.text('Litri 30,00'),
      );
      expect(
        SharedReceiptItem.fromMap({'kind': 'file', 'path': '/c/a.bin'}),
        const SharedReceiptItem.file('/c/a.bin'),
      );
    });

    test('returns null for a malformed / mismatched entry', () {
      expect(SharedReceiptItem.fromMap(null), isNull);
      expect(SharedReceiptItem.fromMap('not a map'), isNull);
      expect(SharedReceiptItem.fromMap({'kind': 'image'}), isNull,
          reason: 'an image item with no path is malformed');
      expect(SharedReceiptItem.fromMap({'kind': 'text', 'text': ''}), isNull,
          reason: 'an empty text body carries nothing actionable');
      expect(SharedReceiptItem.fromMap({'kind': 'video', 'path': '/x'}), isNull,
          reason: 'an unknown kind is rejected');
    });
  });

  group('SharedReceiptIntent.fromPlatform', () {
    test('decodes the items list and the country code', () {
      final intent = SharedReceiptIntent.fromPlatform({
        'items': [
          {'kind': 'image', 'path': '/c/a.jpg'},
          {'kind': 'text', 'text': 'Gasolio'},
        ],
        'country': 'IT',
      });
      expect(intent, isNotNull);
      expect(intent!.items, hasLength(2));
      expect(intent.countryCode, 'IT');
      expect(intent.isEmpty, isFalse);
    });

    test('drops malformed items individually but keeps the good ones', () {
      final intent = SharedReceiptIntent.fromPlatform({
        'items': [
          {'kind': 'image', 'path': '/c/a.jpg'},
          {'kind': 'image'}, // malformed — dropped
          'garbage', // not a map — dropped
        ],
      });
      expect(intent, isNotNull);
      expect(intent!.items, hasLength(1));
      expect(intent.items.single, const SharedReceiptItem.image('/c/a.jpg'));
      expect(intent.countryCode, isNull);
    });

    test('returns null for a null / non-map / itemless payload', () {
      expect(SharedReceiptIntent.fromPlatform(null), isNull);
      expect(SharedReceiptIntent.fromPlatform('x'), isNull);
      expect(SharedReceiptIntent.fromPlatform({'country': 'IT'}), isNull,
          reason: 'no items → nothing to route');
      expect(
        SharedReceiptIntent.fromPlatform({
          'items': [
            {'kind': 'image'},
          ],
        }),
        isNull,
        reason: 'all items malformed → null, not an empty intent',
      );
    });

    test('an empty / blank country code decodes to null', () {
      final intent = SharedReceiptIntent.fromPlatform({
        'items': [
          {'kind': 'text', 'text': 'Diesel'},
        ],
        'country': '',
      });
      expect(intent, isNotNull);
      expect(intent!.countryCode, isNull);
    });
  });
}
