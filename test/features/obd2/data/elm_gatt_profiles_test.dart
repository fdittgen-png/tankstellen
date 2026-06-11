// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/elm_gatt_profiles.dart';

/// #3014 (Epic #3013, Phase 2) — property-based ELM327 GATT discovery.
///
/// The pre-#3014 channel hard-pinned FFF0/FFF2/FFF1 with an exact-UUID
/// `firstWhere`-or-throw, so an HM-10-class clone (the maintainer's SmartOBD)
/// exposing FFE0 with a single dual-mode FFE1 characteristic threw a StateError
/// on discovery → the BLE adapter never connected. This proves the property
/// matcher resolves the write+notify pair across the clone families.
///
/// The matcher is a PURE function over the discovered service/char/property
/// layout — no flutter_blue_plus stack (FBP's BluetoothService /
/// BluetoothCharacteristic.properties are not constructible in a unit test, so
/// this pure seam carries the property-matching coverage; the channel's FBP
/// adapter + the connect ordering are covered separately).

const _fff0 = '0000fff0-0000-1000-8000-00805f9b34fb';
const _fff2 = '0000fff2-0000-1000-8000-00805f9b34fb';
const _fff1 = '0000fff1-0000-1000-8000-00805f9b34fb';
const _ffe0 = '0000ffe0-0000-1000-8000-00805f9b34fb';
const _ffe1 = '0000ffe1-0000-1000-8000-00805f9b34fb';

void main() {
  group('resolveElmGatt — HM-10 single dual-char clone (the SmartOBD fix)', () {
    test(
        'an FFE0 service with ONE dual-mode FFE1 char (write+notify) resolves '
        'write==notify by property (RED on master: exact-FFF0 firstWhere threw)',
        () {
      // SmartOBD-class HM-10 / CC254x layout: one characteristic that is both
      // writable (writeWithoutResponse) and notifiable. The old exact-UUID
      // discovery looked for FFF0/FFF2/FFF1 and threw StateError on this.
      const services = <GattServiceDescriptor>[
        GattServiceDescriptor(
          uuid: _ffe0,
          characteristics: [
            GattCharDescriptor(
              uuid: _ffe1,
              writeWithoutResponse: true,
              notify: true,
            ),
          ],
        ),
      ];

      // The registry hint is the generic FFF0 profile (no scan ⇒ generic),
      // which this device does NOT expose — so the hint MUST fall through to
      // property matching.
      final resolved = resolveElmGatt(
        services,
        hintServiceUuid: _fff0,
        hintWriteCharUuid: _fff2,
        hintNotifyCharUuid: _fff1,
      );

      expect(resolved, isNotNull);
      expect(resolved!.serviceUuid, _ffe0);
      expect(resolved.writeCharUuid, _ffe1);
      expect(resolved.notifyCharUuid, _ffe1,
          reason: 'the single dual-mode char serves BOTH roles');
      expect(resolved.matchReason, 'family-property');
    });

    test(
        'an FFE0 service with SEPARATE write + notify chars resolves the right '
        'pair by property', () {
      const ffe2 = '0000ffe2-0000-1000-8000-00805f9b34fb';
      const services = <GattServiceDescriptor>[
        GattServiceDescriptor(
          uuid: _ffe0,
          characteristics: [
            GattCharDescriptor(uuid: _ffe1, notify: true),
            GattCharDescriptor(uuid: ffe2, write: true),
          ],
        ),
      ];
      final resolved = resolveElmGatt(services,
          hintServiceUuid: _fff0,
          hintWriteCharUuid: _fff2,
          hintNotifyCharUuid: _fff1);
      expect(resolved!.writeCharUuid, ffe2);
      expect(resolved.notifyCharUuid, _ffe1);
    });
  });

  group('resolveElmGatt — FFF0 regression (the dominant clone still works)', () {
    test('exact FFF0/FFF2/FFF1 layout resolves via the hint-exact fast path',
        () {
      const services = <GattServiceDescriptor>[
        GattServiceDescriptor(
          uuid: _fff0,
          characteristics: [
            GattCharDescriptor(uuid: _fff2, writeWithoutResponse: true),
            GattCharDescriptor(uuid: _fff1, notify: true),
          ],
        ),
      ];
      final resolved = resolveElmGatt(services,
          hintServiceUuid: _fff0,
          hintWriteCharUuid: _fff2,
          hintNotifyCharUuid: _fff1);
      expect(resolved!.serviceUuid, _fff0);
      expect(resolved.writeCharUuid, _fff2);
      expect(resolved.notifyCharUuid, _fff1);
      expect(resolved.matchReason, 'hint-exact',
          reason: 'the known-good registry UUIDs are the first-priority hint');
    });

    test(
        'an OBDLink 18F0 service (custom 2af1/2af0 chars) resolves by property '
        'when the FFF0 hint misses', () {
      const s18f0 = '000018f0-0000-1000-8000-00805f9b34fb';
      const w2af1 = '00002af1-0000-1000-8000-00805f9b34fb';
      const n2af0 = '00002af0-0000-1000-8000-00805f9b34fb';
      const services = <GattServiceDescriptor>[
        GattServiceDescriptor(
          uuid: s18f0,
          characteristics: [
            GattCharDescriptor(uuid: w2af1, write: true),
            GattCharDescriptor(uuid: n2af0, notify: true),
          ],
        ),
      ];
      final resolved = resolveElmGatt(services,
          hintServiceUuid: _fff0,
          hintWriteCharUuid: _fff2,
          hintNotifyCharUuid: _fff1);
      expect(resolved!.serviceUuid, s18f0);
      expect(resolved.writeCharUuid, w2af1);
      expect(resolved.notifyCharUuid, n2af0);
      expect(resolved.matchReason, 'family-property');
    });
  });

  group('resolveElmGatt — terminal serviceNotFound (no usable pair)', () {
    test(
        'a device with a notify-only service (no writable char) resolves null '
        'so the caller stamps serviceNotFound', () {
      const services = <GattServiceDescriptor>[
        GattServiceDescriptor(
          uuid: '0000180a-0000-1000-8000-00805f9b34fb', // device-info service
          characteristics: [
            GattCharDescriptor(uuid: _ffe1, notify: true),
          ],
        ),
      ];
      final resolved = resolveElmGatt(services,
          hintServiceUuid: _fff0,
          hintWriteCharUuid: _fff2,
          hintNotifyCharUuid: _fff1);
      expect(resolved, isNull,
          reason: 'no service exposes a writable + notifiable pair');
    });

    test('an empty service list resolves null', () {
      expect(resolveElmGatt(const []), isNull);
    });

    test(
        'a writable+notifiable pair on a NON-ELM-family service resolves via '
        'the any-property last resort', () {
      const custom = '0000abcd-0000-1000-8000-00805f9b34fb';
      const services = <GattServiceDescriptor>[
        GattServiceDescriptor(
          uuid: custom,
          characteristics: [
            GattCharDescriptor(uuid: _ffe1, write: true, notify: true),
          ],
        ),
      ];
      final resolved = resolveElmGatt(services);
      expect(resolved!.serviceUuid, custom);
      expect(resolved.matchReason, 'any-property');
    });
  });

  group('describeGattLayout — failed-open layout dump for the maintainer', () {
    test('renders short UUIDs + property flags', () {
      final layout = describeGattLayout(const [
        GattServiceDescriptor(
          uuid: _ffe0,
          characteristics: [
            GattCharDescriptor(
                uuid: _ffe1, writeWithoutResponse: true, notify: true),
          ],
        ),
      ]);
      expect(layout, contains('ffe0'));
      expect(layout, contains('ffe1'));
      expect(layout, contains('W')); // writeWithoutResponse
      expect(layout, contains('n')); // notify
    });

    test('handles an empty service list', () {
      expect(describeGattLayout(const []), '(no services discovered)');
    });
  });

  group('resolveElmGatt — pure + total: never throws (#3014 / #2349)', () {
    test(
        'adversarial input (a service with NO characteristics, malformed UUIDs, '
        'and conflicting hints) returns normally — never throws', () {
      final adversarial = <GattServiceDescriptor>[
        const GattServiceDescriptor(uuid: '', characteristics: []),
        const GattServiceDescriptor(
          uuid: 'not-a-uuid',
          characteristics: [GattCharDescriptor(uuid: '')],
        ),
      ];
      // The "never throws" docstring contract: a fault-shaped input must
      // resolve null (no usable pair), NOT throw.
      expect(() => resolveElmGatt(adversarial), returnsNormally);
      expect(
        () => resolveElmGatt(adversarial,
            hintServiceUuid: '', hintWriteCharUuid: '', hintNotifyCharUuid: ''),
        returnsNormally,
      );
      expect(() => describeGattLayout(adversarial), returnsNormally);
    });
  });
}
