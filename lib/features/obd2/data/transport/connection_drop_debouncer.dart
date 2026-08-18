// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

/// Debounces a raw BLE `connectionState == disconnected` edge into a
/// *confirmed* drop signal (#2261 concern 1).
///
/// The ELM327 BLE link blips constantly: a momentary RF collision, a
/// 2.4 GHz Wi-Fi burst, or the adapter's own supervision-timeout dance
/// can flip `connectionState` to `disconnected` for a few hundred
/// milliseconds and then heal itself. If every such edge tore the
/// session down, a recoverable drive would end on a pothole.
///
/// This collaborator turns the raw edge into a confirmed drop only when
/// EITHER:
///   * the link stays down for [debounce] (a real disconnect — the
///     adapter is gone), OR
///   * [noteCommandFailure] is called while a disconnect edge is
///     pending (the next OBD command also failed — the link is
///     demonstrably unusable, so we don't wait out the full debounce).
///
/// A `connected` edge arriving before either fires CANCELS the pending
/// drop — the blip self-healed and the session survives.
///
/// Pure of any BLE dependency so it is unit-testable with an injected
/// clock-free [Timer] via [debounce]. The owning channel
/// ([FlutterBluePlusElmChannel]) feeds it edges and wires [onConfirmed]
/// to push the typed [Obd2DisconnectedException] onto the byte stream,
/// which the transport's pending-command completer surfaces as a throw
/// — so [TripDropDetector] fires in ~1–2 s instead of waiting out the
/// ~15 s read timeout.
class ConnectionDropDebouncer {
  ConnectionDropDebouncer({
    required void Function() onConfirmed,
    Duration debounce = const Duration(milliseconds: 1500),
  })  : _onConfirmed = onConfirmed,
        _debounce = debounce;

  final void Function() _onConfirmed;
  final Duration _debounce;

  Timer? _timer;
  bool _confirmed = false;

  /// `true` once a disconnect edge has landed and not yet been cleared
  /// by a reconnect — i.e. a drop is being debounced or has confirmed.
  bool get isPending => _timer != null || _confirmed;

  /// `true` once the drop has been confirmed (debounce elapsed or a
  /// command failed during the pending window). Stays latched until
  /// [reset].
  bool get isConfirmed => _confirmed;

  /// Feed a raw BLE connection-state edge.
  ///
  ///   * `disconnected: true`  → arm the debounce (no-op if already armed
  ///     or confirmed).
  ///   * `disconnected: false` → a reconnect: cancel a pending debounce
  ///     so a self-healed blip never confirms. Does NOT clear an already
  ///     confirmed drop — the session is gone; recovery owns rebuilding.
  void noteConnectionState({required bool disconnected}) {
    if (disconnected) {
      if (_confirmed || _timer != null) return;
      _timer = Timer(_debounce, _confirm);
    } else {
      // Reconnected before the debounce elapsed → the blip healed.
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Report that a command failed while a disconnect edge is pending.
  /// Confirms the drop immediately — no point waiting out the rest of
  /// the debounce when the link has already proven unusable. A no-op
  /// when no disconnect is pending (a lone command timeout on an
  /// otherwise-connected link is the read-timeout's concern, not ours).
  void noteCommandFailure() {
    if (_timer == null || _confirmed) return;
    _confirm();
  }

  void _confirm() {
    _timer?.cancel();
    _timer = null;
    if (_confirmed) return;
    _confirmed = true;
    _onConfirmed();
  }

  /// Clear all state so a fresh connection can reuse the debouncer.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _confirmed = false;
  }

  /// Cancel any pending timer. Call on channel close.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
