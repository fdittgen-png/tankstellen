// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../l10n/app_localizations.dart';
import '../data/obd2_connection_errors.dart';

/// Maps a typed [Obd2ConnectionError] to a localized, user-facing
/// message (#1663).
///
/// `Obd2ConnectionError.message` is a **developer diagnostic** — a terse
/// English string for logs and `toString()`. Whenever the error is shown
/// to the user (a snackbar, an error panel), call [localizedMessage]
/// instead so the user sees a translated, actionable message.
extension Obd2ConnectionErrorL10n on Obd2ConnectionError {
  /// The localized, user-facing message for this error. Falls back to
  /// the English diagnostic [message] when localizations are
  /// unavailable.
  String localizedMessage(AppLocalizations? l10n) => switch (this) {
        Obd2PermissionDenied() =>
          l10n?.obd2ErrorPermissionDenied ?? message,
        Obd2BluetoothOff() => l10n?.obd2ErrorBluetoothOff ?? message,
        Obd2ScanTimeout() => l10n?.obd2ErrorScanTimeout ?? message,
        Obd2AdapterUnresponsive() =>
          l10n?.obd2ErrorAdapterUnresponsive ?? message,
        // #3009 — the adapter answered; the engine is off. Accurate
        // "start the engine" message, not the adapter-blaming one.
        Obd2EngineOff() => l10n?.obd2ErrorEngineOff ?? message,
        Obd2ProtocolInitFailed() =>
          l10n?.obd2ErrorProtocolInitFailed ?? message,
        // #3181 — pairing failed / was never confirmed. Actionable
        // power-cycle guidance: the OBDLink CX only accepts new bonds in
        // the first ~5 minutes after power-on.
        Obd2PairingRequired() =>
          l10n?.obd2ErrorPairingRequired ?? message,
        Obd2DisconnectedException() =>
          l10n?.obd2ErrorDisconnected ?? message,
      };
}
