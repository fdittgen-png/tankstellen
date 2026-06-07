// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

/// Abstract transport layer for OBD-II communication.
///
/// Implementations handle the actual I/O (Bluetooth, TCP, serial).
/// The [Elm327Protocol] builds commands and parses responses;
/// transport just moves bytes.
abstract class Obd2Transport {
  /// Connect to the OBD-II adapter.
  Future<void> connect();

  /// Send a command and wait for the response (terminated by '>').
  Future<String> sendCommand(String command);

  /// Disconnect from the adapter.
  Future<void> disconnect();

  /// Whether currently connected.
  bool get isConnected;
}

/// Optional capability mixin — transports that support the STN-chip
/// listen-mode protocol (#1418) implement this in addition to
/// [Obd2Transport]. [Obd2Service.canFrameStream] type-checks for it
/// before opening listen-mode so transports that lack support
/// surface a clean [UnsupportedError] from the gate, not a deeper
/// stack.
///
/// Why a separate interface instead of additional abstract methods on
/// [Obd2Transport]: ten-plus existing test fakes `implements
/// Obd2Transport` directly. Adding required members would force every
/// fake to add boilerplate even for tests that don't touch listen
/// mode. The opt-in interface keeps the cost on the listen-mode test
/// path only.
abstract class Obd2ListenModeTransport {
  /// Open a continuous line-stream mode for STN-chip listen-mode CAN
  /// sniffing (#1418). After the caller has sent the listen-mode
  /// setup commands (e.g. `ATCRA 0E6` + `STMA`) via
  /// [Obd2Transport.sendCommand], the adapter starts emitting frame
  /// lines without the trailing `>` prompt that the regular
  /// `sendCommand` path waits on. This method exposes those lines
  /// as a broadcast stream so a higher layer can parse them into
  /// `(id, payload)` tuples.
  Stream<String> openListenLineStream();

  /// Counterpart to [openListenLineStream]: send [command] (typically
  /// `STMP`) without waiting for the `>` prompt that
  /// [Obd2Transport.sendCommand] requires (#1418). On real hardware
  /// the prompt does not arrive until listen-mode exits, so the
  /// regular `sendCommand` path would deadlock.
  Future<void> sendListenModeStop(String command);
}

/// Opt-in capability mixin (#3037) — transports that can give ONE command a
/// dedicated, generous read window that OVERRIDES the steady-state read
/// timeout ceiling.
///
/// Why this is necessary: the `0100` supported-PIDs probe is the FIRST OBD
/// request on the bus, so it triggers the ELM327 protocol auto-search
/// (`SEARCHING…`). On a slow link that search can outlast the steady-state
/// ~5 s read ceiling — and RE-SENDING `0100` mid-search RESTARTS the search,
/// so the late `41 00` frame is never caught (the #3035/#3037 false
/// engine-off). The correct ELM327 practice is to send `0100` ONCE and
/// RE-READ the in-progress search within a single generous window (~12–15 s),
/// which this method exposes. Steady-state PID reads keep their ~5 s class.
///
/// Like [Obd2ListenModeTransport] this is a SEPARATE opt-in interface, not an
/// extra abstract method on [Obd2Transport], so the ten-plus existing fakes
/// that `implements Obd2Transport` don't need boilerplate. Callers type-check
/// for it and fall back to the plain [Obd2Transport.sendCommand] otherwise.
abstract class Obd2ProtocolSearchTransport {
  /// Send [command] and wait up to [readTimeout] for the `>`-terminated
  /// reply, OVERRIDING the transport's steady-state read-timeout ceiling for
  /// this one command only. Used by the `0100` protocol-search probe to give
  /// the ELM327 auto-search a single generous window instead of re-sending
  /// (which would restart the search). All other serialisation /
  /// half-duplex-queue guarantees of [Obd2Transport.sendCommand] still hold.
  Future<String> sendCommandWithReadTimeout(
    String command,
    Duration readTimeout,
  );
}

/// A fake transport for testing that returns pre-configured responses.
///
/// Listen-mode (#1418) is opt-in: tests that need
/// [Obd2ListenModeTransport.openListenLineStream] emit lines via
/// [pushListenLine] and observe stop commands in
/// [listenStopCommands]. Tests that don't touch listen-mode get the
/// pre-#1418 behaviour unchanged.
class FakeObd2Transport
    implements Obd2Transport, Obd2ListenModeTransport {
  final Map<String, String> _responses;
  bool _connected = false;

  /// Commands captured by [sendListenModeStop]. Inspected by #1418
  /// tests to assert that the service sends `STMP` on cancel.
  final List<String> listenStopCommands = [];

  /// Commands captured by [sendCommand]. Available for tests that
  /// want to assert ordering / arguments without writing yet another
  /// recording transport. Pre-existing tests that consult
  /// [_responses] keep working unchanged.
  final List<String> sentCommands = [];

  // Closed in [disconnect]; the linter can't follow the assignment
  // through the nullable field, so silence the warning here.
  // ignore: close_sinks
  StreamController<String>? _listenLines;

  FakeObd2Transport([Map<String, String>? responses])
      : _responses = responses ?? {};

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    sentCommands.add(cmd);
    return _responses[cmd] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    final ctrl = _listenLines;
    _listenLines = null;
    if (ctrl != null && !ctrl.isClosed) {
      await ctrl.close();
    }
  }

  @override
  bool get isConnected => _connected;

  @override
  Stream<String> openListenLineStream() {
    // The controller is owned by the transport (closed in
    // [disconnect]), not by this method's caller. Suppress the lint
    // — the alternative would be a per-call short-lived controller
    // that breaks fan-out for multiple consumers.
    // ignore: close_sinks
    final ctrl = _listenLines ??= StreamController<String>.broadcast();
    return ctrl.stream;
  }

  @override
  Future<void> sendListenModeStop(String command) async {
    if (!_connected) throw StateError('Not connected');
    listenStopCommands.add(command.trim());
  }

  /// Push a line into the listen-mode stream. No-op when no consumer
  /// has called [openListenLineStream] yet — keeps tests that wire
  /// the producer before the consumer working.
  void pushListenLine(String line) {
    final ctrl = _listenLines;
    if (ctrl == null || ctrl.isClosed) return;
    ctrl.add(line);
  }
}
