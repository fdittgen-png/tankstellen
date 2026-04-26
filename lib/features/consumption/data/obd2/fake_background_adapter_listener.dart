import 'dart:async';

import 'background_adapter_listener.dart';

/// Test-only [BackgroundAdapterListener] that lets a unit / widget /
/// integration test drive the [AutoTripCoordinator] state machine
/// deterministically (#1004 phase 2a).
///
/// Lives under `lib/` rather than `test/` because widget and
/// integration tests outside the Dart unit-test directory also need
/// to inject it (the coordinator will eventually be exposed via a
/// Riverpod provider whose override has to import a public symbol).
///
/// ## Capabilities
/// - [emitConnected] / [emitDisconnected] push synthetic events into
///   the broadcast stream so a test reads exactly the timeline it set
///   up — no real BT stack involved.
/// - [startCalls] / [stopCalls] / [startedMacs] record every lifecycle
///   call so a test can assert that the coordinator armed and tore
///   down the bridge correctly.
class FakeBackgroundAdapterListener implements BackgroundAdapterListener {
  /// Broadcast so multiple listeners (e.g. the coordinator AND a test
  /// observer) can attach without competing for a single-subscriber
  /// stream.
  final StreamController<BackgroundAdapterEvent> _events =
      StreamController<BackgroundAdapterEvent>.broadcast();

  /// Number of times [start] has been called over the fake's lifetime.
  /// Lets a test assert idempotency without snapshotting [startedMacs].
  int startCalls = 0;

  /// Number of times [stop] has been called.
  int stopCalls = 0;

  /// MAC addresses passed to [start] in call order. The coordinator's
  /// idempotency rule says "second start with the same MAC is a no-op"
  /// — the test peeks at this list to verify the rule.
  final List<String> startedMacs = <String>[];

  @override
  Stream<BackgroundAdapterEvent> get events => _events.stream;

  @override
  Future<void> start({required String mac}) async {
    startCalls++;
    startedMacs.add(mac);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  /// Push a synthetic connect event. Defaults [at] to `DateTime.now()`
  /// so simple tests don't have to fabricate a timestamp; tests that
  /// care about timing pass it explicitly.
  void emitConnected(String mac, {DateTime? at}) {
    _events.add(AdapterConnected(mac: mac, at: at ?? DateTime.now()));
  }

  /// Push a synthetic disconnect event. Same `at` semantics as
  /// [emitConnected].
  void emitDisconnected(String mac, {DateTime? at}) {
    _events.add(AdapterDisconnected(mac: mac, at: at ?? DateTime.now()));
  }

  /// Close the underlying stream controller. Tests should call this in
  /// `tearDown` so the broadcast stream's resources are released and
  /// pending listeners do not leak across tests.
  Future<void> dispose() async {
    if (!_events.isClosed) {
      await _events.close();
    }
  }
}
