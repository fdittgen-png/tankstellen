// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/app_initializer.dart';

/// #2772 — the benign EventChannel teardown PlatformException ("No active
/// stream to cancel") reaches the global FlutterError.onError handler and was
/// ERROR-logged; the de-noise predicate must classify it as benign while
/// leaving every other error loggable.
void main() {
  group('AppInitializer.isBenignStreamCancel (#2772)', () {
    test('the benign EventChannel cancel PlatformException → true', () {
      expect(
        AppInitializer.isBenignStreamCancel(
          PlatformException(code: 'error', message: 'No active stream to cancel'),
        ),
        isTrue,
      );
    });

    test('case-insensitive on the message', () {
      expect(
        AppInitializer.isBenignStreamCancel(
          PlatformException(code: 'error', message: 'NO ACTIVE STREAM TO CANCEL'),
        ),
        isTrue,
      );
    });

    test('a different PlatformException is NOT benign (still logged)', () {
      expect(
        AppInitializer.isBenignStreamCancel(
          PlatformException(code: 'error', message: 'Bluetooth adapter is off'),
        ),
        isFalse,
      );
    });

    test('non-PlatformException errors are NOT benign', () {
      expect(AppInitializer.isBenignStreamCancel(Exception('boom')), isFalse);
      expect(
        AppInitializer.isBenignStreamCancel(
          const FormatException('No active stream to cancel'),
        ),
        isFalse,
      );
    });
  });
}
