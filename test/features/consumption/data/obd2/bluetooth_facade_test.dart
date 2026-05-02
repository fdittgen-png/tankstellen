import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';

/// Unit tests for the [PluginBluetoothFacade] BT-off classifier
/// (#1369).
///
/// `PluginBluetoothFacade._looksBluetoothOff` is the boundary that
/// turns a raw `flutter_blue_plus_android` `PlatformException` into a
/// typed `Obd2BluetoothOff`. The plugin's exact wording has changed
/// between versions, so the substring match must stay tolerant of
/// small phrasing tweaks (different capitalisation, "must be on" vs
/// "must be turned on", explicit `bluetooth_off` codes, etc.).
void main() {
  group('PluginBluetoothFacade.debugLooksBluetoothOff (#1369)', () {
    test('matches the canonical FlutterBluePlus 1.36 phrasing', () {
      final ex = PlatformException(
        code: 'startScan',
        message: 'Bluetooth must be turned on',
      );
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isTrue);
    });

    test('matches a case-insensitive variant', () {
      final ex = PlatformException(
        code: 'startScan',
        message: 'BLUETOOTH MUST BE TURNED ON',
      );
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isTrue);
    });

    test('matches the alternate "must be on" phrasing', () {
      final ex = PlatformException(
        code: 'startScan',
        message: 'Bluetooth must be on',
      );
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isTrue);
    });

    test('matches an explicit bluetooth_off code in the message', () {
      final ex = PlatformException(
        code: 'startScan',
        message: 'BLUETOOTH_OFF: adapter disabled',
      );
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isTrue);
    });

    test(
      'rejects unrelated PlatformExceptions so they propagate as-is',
      () {
        final ex = PlatformException(
          code: 'permission_denied',
          message: 'BLUETOOTH_SCAN permission required',
        );
        expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isFalse);
      },
    );

    test('rejects non-PlatformException objects', () {
      expect(
        PluginBluetoothFacade.debugLooksBluetoothOff(
          ArgumentError('not a platform exception'),
        ),
        isFalse,
      );
      expect(
        PluginBluetoothFacade.debugLooksBluetoothOff(
          'Bluetooth must be turned on',
        ),
        isFalse,
      );
    });

    test('handles a PlatformException with a null message gracefully', () {
      final ex = PlatformException(code: 'startScan');
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isFalse);
    });
  });
}
