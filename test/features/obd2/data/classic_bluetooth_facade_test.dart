// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/classic_method_channel.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3106 — a Classic bonded-enumeration failure must DEGRADE gracefully, never
/// tear down the scan. The facade's stream is StreamGroup-merged with the BLE
/// scan in Obd2ConnectionService, so an UNCAUGHT throwable here would abort the
/// merged stream and take BLE discovery down with it — the user would find NO
/// adapters on Android because the Classic side blipped.
void main() {
  silenceErrorLoggerSpool();

  group('PluginClassicBluetoothFacade.scan fault tolerance (#3106)', () {
    test('an Exception from bondedDevices degrades to no candidates', () async {
      final facade = PluginClassicBluetoothFacade(
        plugin: _ThrowingPlugin(const FormatException('boom')),
      );
      await expectLater(facade.scan().toList(), completion(isEmpty));
    });

    test(
        'an ERROR from bondedDevices is ALSO caught (the old `on Exception` let '
        'it escape and abort the merged BLE stream)', () async {
      final facade = PluginClassicBluetoothFacade(
        plugin: _ThrowingPlugin(StateError('platform Error')),
      );
      // Completes empty instead of propagating — BLE discovery is unaffected.
      await expectLater(facade.scan().toList(), completion(isEmpty));
    });
  });
}

/// A method-channel stand-in whose [bondedDevices] always throws the given
/// [error] (an Exception or an Error), to exercise the facade's catch path.
class _ThrowingPlugin extends Obd2ClassicMethodChannel {
  _ThrowingPlugin(this.error);

  final Object error;

  @override
  Future<List<ClassicBondedDevice>> bondedDevices() async => throw error;
}
