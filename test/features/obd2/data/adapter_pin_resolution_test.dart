// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_pin_resolution.dart';
import 'package:tankstellen/features/obd2/data/last_good_adapter_store.dart';
import '../../../helpers/silence_error_logger.dart';

/// #3423 (Epic #3415 task 6) — the ONE adapter-pin resolution rule shared by
/// the in-trip reconnect gate (`DroppedSessionManager`) and its scanner
/// factory: vehicle-profile MAC first, else the #3019 last-good auto-pin,
/// else null (grace-window-only recovery, unchanged).
void main() {
  silenceErrorLoggerSpool();

  const lastGood = LastGoodAdapter(
    mac: 'CC:DD:EE:FF:00:11',
    transportKind: 'classic',
    name: 'vLinker FS',
  );

  group('resolveAdapterPin (#3423)', () {
    test('the vehicle-profile MAC WINS over the last-good auto-pin', () {
      final pin = resolveAdapterPin(
        vehicleProfileMac: 'AA:BB:CC:DD:EE:FF',
        recallLastGood: () => lastGood,
      );

      expect(pin, isNotNull);
      expect(pin!.mac, 'AA:BB:CC:DD:EE:FF');
      expect(pin.source, AdapterPinSource.vehicleProfile,
          reason: 'an explicit per-vehicle pairing always outranks the '
              'auto-pin');
    });

    test('the last-good store is not even consulted when a vehicle pin '
        'exists (lazy fallback)', () {
      var recalls = 0;
      resolveAdapterPin(
        vehicleProfileMac: 'AA:BB:CC:DD:EE:FF',
        recallLastGood: () {
          recalls++;
          return lastGood;
        },
      );

      expect(recalls, 0);
    });

    test('NO vehicle pin falls back to the last-good auto-pin — the '
        'picker-started-trip gap', () {
      final pin = resolveAdapterPin(
        vehicleProfileMac: null,
        recallLastGood: () => lastGood,
      );

      expect(pin, isNotNull,
          reason: 'a picker-started trip with an unset vehicle MAC must '
              'still get an in-trip reconnect target');
      expect(pin!.mac, 'CC:DD:EE:FF:00:11');
      expect(pin.source, AdapterPinSource.lastGoodAdapter);
    });

    test('a blank / whitespace vehicle MAC counts as unset', () {
      final pin = resolveAdapterPin(
        vehicleProfileMac: '   ',
        recallLastGood: () => lastGood,
      );

      expect(pin?.source, AdapterPinSource.lastGoodAdapter);
    });

    test('NEITHER pin resolves to null — grace-window-only recovery, '
        'exactly as before', () {
      expect(
        resolveAdapterPin(vehicleProfileMac: null, recallLastGood: () => null),
        isNull,
      );
      expect(resolveAdapterPin(), isNull);
    });

    test('a THROWING last-good recall degrades to null — trip start must '
        'never be derailed by the fallback store', () {
      ResolvedAdapterPin? pin;
      expect(
        () => pin = resolveAdapterPin(
          vehicleProfileMac: null,
          recallLastGood: () => throw StateError('provider unresolvable'),
        ),
        returnsNormally,
        reason: 'the documented never-throws contract (#3423): a fault in '
            'the fallback store must degrade to "no pin", not a throw',
      );
      expect(pin, isNull);
    });

    test('resolveAdapterPinMac is the same rule, MAC-only', () {
      expect(
        resolveAdapterPinMac('AA:BB:CC:DD:EE:FF', () => lastGood),
        'AA:BB:CC:DD:EE:FF',
      );
      expect(
        resolveAdapterPinMac(null, () => lastGood),
        'CC:DD:EE:FF:00:11',
      );
      expect(resolveAdapterPinMac(null, () => null), isNull);
    });
  });
}
