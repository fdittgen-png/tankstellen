// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/presentation/obd2_connection_error_l10n.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Pins the #1663 OBD2 error localizer — the user-facing replacement for
/// the raw developer-diagnostic `Obd2ConnectionError.message`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every Obd2ConnectionError subtype maps to its localized key', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final cases = <Obd2ConnectionError, String>{
      const Obd2PermissionDenied(): l10n.obd2ErrorPermissionDenied,
      const Obd2BluetoothOff(): l10n.obd2ErrorBluetoothOff,
      const Obd2ScanTimeout(): l10n.obd2ErrorScanTimeout,
      const Obd2AdapterUnresponsive(): l10n.obd2ErrorAdapterUnresponsive,
      // #3009 — the engine-off condition maps to its OWN message, distinct
      // from the adapter-unresponsive one (the adapter DID respond).
      const Obd2EngineOff(): l10n.obd2ErrorEngineOff,
      const Obd2ProtocolInitFailed('ELM-garbage'):
          l10n.obd2ErrorProtocolInitFailed,
      const Obd2DisconnectedException(): l10n.obd2ErrorDisconnected,
    };
    cases.forEach((error, expected) {
      expect(error.localizedMessage(l10n), expected);
      // The localized message must not leak the raw diagnostic.
      expect(error.localizedMessage(l10n), isNot(error.message));
    });
  });

  test('the engine-off message does NOT blame the adapter (#3009)', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final engineOff = const Obd2EngineOff().localizedMessage(l10n);
    // It must read as engine-off, not adapter-failure.
    expect(engineOff.toLowerCase(), contains('engine'));
    expect(engineOff, isNot(l10n.obd2ErrorAdapterUnresponsive));
    // The reworded adapter-unresponsive string no longer says "ignition".
    expect(l10n.obd2ErrorAdapterUnresponsive.toLowerCase(),
        isNot(contains('ignition')));
  });

  test('falls back to the English diagnostic when l10n is null', () {
    const error = Obd2ScanTimeout();
    expect(error.localizedMessage(null), error.message);
  });
}
