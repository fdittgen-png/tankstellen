// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

/// App-wide, transport-agnostic "the live OBD2 link just dropped" signal
/// (#3019 / Epic #3013 phase 3).
///
/// Both byte channels — [FlutterBluePlusElmChannel] (BLE) and
/// [ClassicElmChannel] (Classic SPP) — already detect a mid-session drop
/// PROACTIVELY at the transport edge (a `connectionState == disconnected`
/// edge / a notify-stream `onError`, #2261/#2900; a socket `onError` /
/// `onDone`, #2671) and push a typed `Obd2DisconnectedException` onto their
/// byte stream so any in-flight `sendCommand` fails fast. But that only
/// reaches a caller with a command IN FLIGHT — so a drop while idle (or
/// between trips) was previously discovered only LAZILY on the next write.
///
/// This is the missing decoupled hop: the channels emit a drop event HERE
/// the instant the edge fires, and the trip-INDEPENDENT
/// [Obd2ReconnectController] (via its Riverpod owner) subscribes to start
/// its bounded backoff loop regardless of whether a recording is active.
///
/// Static singleton on purpose — it mirrors the existing
/// [Obd2CommDiagnostics.instance] / `AutoRecordTraceLog` static-sink seams
/// the same channels already write to, so the deep-in-the-facade channel
/// construction needs no extra plumbing. A `broadcast` stream, so multiple
/// listeners (the reconnect owner + any diagnostics overlay) can attach.
class Obd2LinkDropSignal {
  Obd2LinkDropSignal._();

  static final Obd2LinkDropSignal instance = Obd2LinkDropSignal._();

  final StreamController<Obd2LinkDropEvent> _controller =
      StreamController<Obd2LinkDropEvent>.broadcast();

  /// Drop events. Each carries the transport kind + the MAC of the link
  /// that dropped, so a subscriber can scope its reaction (e.g. only react
  /// to the adapter it cares about).
  Stream<Obd2LinkDropEvent> get drops => _controller.stream;

  /// Fire a drop event. Called from the channels' proactive
  /// onError / onDone / disconnect-edge handlers. Best-effort: a closed
  /// controller (only in a torn-down test) is ignored silently — a drop
  /// signal is advisory, never load-bearing on its own.
  ///
  /// #3346 — [reason] is a stable, low-cardinality tag for WHY the link
  /// dropped (`ble-disconnect-edge`, `classic-socket-error`,
  /// `classic-socket-done`, `classic-write-failed`). It is carried into the
  /// reconnect-episode breadcrumb so a field export answers the first
  /// question — *what killed the link* — without a debugger attached.
  void notifyDrop({
    required String transportKind,
    String? mac,
    String reason = 'unspecified',
  }) {
    if (_controller.isClosed) return;
    _controller.add(Obd2LinkDropEvent(
      transportKind: transportKind,
      mac: mac,
      reason: reason,
    ));
  }
}

/// One proactive link-drop observation (#3019).
class Obd2LinkDropEvent {
  /// `'ble'` or `'classic'`.
  final String transportKind;

  /// MAC of the link that dropped, when the channel knows it.
  final String? mac;

  /// #3346 — a stable, low-cardinality tag for WHY the link dropped, set at
  /// the channel drop site. Defaults to `'unspecified'` for older callers.
  final String reason;

  const Obd2LinkDropEvent({
    required this.transportKind,
    this.mac,
    this.reason = 'unspecified',
  });

  @override
  String toString() => 'Obd2LinkDropEvent(transportKind: $transportKind, '
      'mac: $mac, reason: $reason)';
}
